#!/usr/bin/env python3
"""Operações de arquivo do widget Pasta.

Recebe um JSON como argumento, com "acao" e os dados dela, e imprime JSON:
  listar      {pasta, ocultos}      -> {pasta, modo, itens: [{nome, pasta, tamanho, data, url}]}
  ordem       {pasta, nomes}        -> {ok}; passa a pasta para o modo manual nessa ordem
  modo        {pasta, modo, nomes}  -> {ok}; modo é nome, data, tipo ou manual. "nomes" é a ordem
                                       inicial do manual quando a pasta ainda não tem uma guardada
  mover       {itens, destino}      -> {nomes, erros}
  copiar      {itens, destino}      -> {nomes, erros}
  renomear    {caminho, nome}       -> {nome}
  nova-pasta  {pasta, nome}         -> {nome}
  lixeira     {itens}               -> {erros}
Falha da ação inteira volta em {"erro": "..."}. Nada é sobrescrito: mover ou copiar para um nome
que já existe cria "nome (1)", e renomear ou criar com nome existente é erro.
O modo e a ordem manual de cada pasta ficam em $XDG_DATA_HOME/trapiche/pastas.json.
"""
import errno
import json
import os
import re
import shutil
import subprocess
import sys
import unicodedata
from pathlib import Path

import caminhos

ARQUIVO = caminhos.dados("pastas.json")
MODOS = ("nome", "data", "tipo", "manual")


def ler_guardado():
    try:
        with open(ARQUIVO) as arquivo:
            dados = json.load(arquivo)
        return dados if isinstance(dados, dict) else {}
    except (OSError, ValueError):
        return {}


def gravar_guardado(dados):
    os.makedirs(os.path.dirname(ARQUIVO), exist_ok=True)
    with open(ARQUIVO + ".tmp", "w") as arquivo:
        json.dump(dados, arquivo, ensure_ascii=False)
    os.replace(ARQUIVO + ".tmp", ARQUIVO)


def normalizar(caminho):
    return os.path.abspath(os.path.expanduser(caminho))


def chave_natural(nome):
    """"Foto 2" antes de "foto 10", sem diferença entre maiúscula e acento."""
    texto = unicodedata.normalize("NFKD", nome.casefold())
    texto = "".join(c for c in texto if not unicodedata.combining(c))
    return [int(parte) if parte.isdigit() else parte for parte in re.split(r"(\d+)", texto)]


def extensao(nome):
    base, ext = os.path.splitext(nome)
    if base.lower().endswith(".tar"):
        return ".tar" + ext
    return ext


def validar_nome(nome):
    nome = (nome or "").strip()
    if not nome:
        raise ValueError("O nome está vazio")
    if "/" in nome or "\0" in nome:
        raise ValueError("O nome não pode ter “/”")
    if nome in (".", ".."):
        raise ValueError("Nome inválido")
    return nome


def nome_livre(pasta, nome, eh_pasta):
    if not os.path.lexists(os.path.join(pasta, nome)):
        return nome
    ext = "" if eh_pasta else extensao(nome)
    if ext == nome:
        ext = ""
    base = nome[:len(nome) - len(ext)]
    numero = 1
    while os.path.lexists(os.path.join(pasta, f"{base} ({numero}){ext}")):
        numero += 1
    return f"{base} ({numero}){ext}"


ERROS = {
    errno.ENOENT: "Não encontrado",
    errno.EACCES: "Sem permissão",
    errno.EPERM: "Sem permissão",
    errno.ENOSPC: "Disco cheio",
    errno.EEXIST: "Já existe",
    errno.ENAMETOOLONG: "Nome comprido demais",
    errno.EROFS: "Disco só de leitura",
}


def mensagem(erro):
    if isinstance(erro, OSError):
        return ERROS.get(erro.errno) or erro.strerror or str(erro)
    return str(erro)


def listar(pedido):
    pasta = normalizar(pedido.get("pasta") or "~")
    ocultos = bool(pedido.get("ocultos"))
    itens = []
    try:
        entradas = list(os.scandir(pasta))
    except FileNotFoundError:
        return {"erro": "Pasta não encontrada", "pasta": pasta}
    except NotADirectoryError:
        return {"erro": "Não é uma pasta", "pasta": pasta}
    except OSError as erro:
        return {"erro": mensagem(erro), "pasta": pasta}
    for entrada in entradas:
        if not ocultos and entrada.name.startswith("."):
            continue
        try:
            estado = entrada.stat()
        except OSError:
            try:
                estado = entrada.stat(follow_symlinks=False)
            except OSError:
                continue
        try:
            eh_pasta = entrada.is_dir()
        except OSError:
            eh_pasta = False
        itens.append({
            "nome": entrada.name,
            "pasta": eh_pasta,
            "tamanho": 0 if eh_pasta else estado.st_size,
            "data": estado.st_mtime,
            "url": Path(entrada.path).as_uri(),
        })

    guardado = ler_guardado().get(pasta) or {}
    modo = guardado.get("modo") if guardado.get("modo") in MODOS else "data"
    por_data = sorted(itens, key=lambda i: (-i["data"], chave_natural(i["nome"])))
    if modo == "data":
        itens = por_data
    elif modo == "nome":
        itens.sort(key=lambda i: (not i["pasta"], chave_natural(i["nome"])))
    elif modo == "tipo":
        itens.sort(key=lambda i: (not i["pasta"], "" if i["pasta"] else extensao(i["nome"]).lower(), chave_natural(i["nome"])))
    else:
        posicao = {nome: n for n, nome in enumerate(guardado.get("ordem") or [])}
        novos = [i for i in por_data if i["nome"] not in posicao]
        antigos = sorted((i for i in itens if i["nome"] in posicao), key=lambda i: posicao[i["nome"]])
        itens = novos + antigos
    return {"pasta": pasta, "modo": modo, "itens": itens}


def juntar_ordem(pasta, nomes, anterior):
    """A ordem nova, seguida dos nomes guardados que não vieram nela (ocultos, por exemplo) e ainda existem."""
    vistos = set()
    ordem = []
    for nome in list(nomes) + list(anterior):
        if isinstance(nome, str) and nome not in vistos and os.path.lexists(os.path.join(pasta, nome)):
            vistos.add(nome)
            ordem.append(nome)
    return ordem


def gravar_ordem(pedido):
    pasta = normalizar(pedido["pasta"])
    dados = ler_guardado()
    anterior = (dados.get(pasta) or {}).get("ordem") or []
    dados[pasta] = {"modo": "manual", "ordem": juntar_ordem(pasta, pedido.get("nomes") or [], anterior)}
    gravar_guardado(dados)
    return {"ok": True}


def mudar_modo(pedido):
    pasta = normalizar(pedido["pasta"])
    modo = pedido.get("modo")
    if modo not in MODOS:
        return {"erro": "Modo de ordenação inválido"}
    dados = ler_guardado()
    atual = dados.get(pasta) or {}
    ordem = atual.get("ordem") or []
    if modo == "manual" and not ordem:
        ordem = juntar_ordem(pasta, pedido.get("nomes") or [], [])
    dados[pasta] = {"modo": modo, "ordem": ordem}
    gravar_guardado(dados)
    return {"ok": True}


def trocar_caminho_guardado(dados, antigo, novo):
    """Uma pasta renomeada ou movida leva junto a arrumação dela e das subpastas."""
    for chave in list(dados):
        if chave == antigo or chave.startswith(antigo + "/"):
            dados[novo + chave[len(antigo):]] = dados.pop(chave)


def transferir(pedido, mover):
    destino = normalizar(pedido.get("destino") or "")
    if not os.path.isdir(destino):
        return {"erro": "A pasta de destino não existe"}
    nomes, erros = [], []
    dados = ler_guardado()
    mudou = False
    for item in pedido.get("itens") or []:
        origem = normalizar(item)
        nome = os.path.basename(origem)
        try:
            if not os.path.lexists(origem):
                raise ValueError(f"{nome}: não existe mais")
            if os.path.isdir(origem) and not os.path.islink(origem) and (destino == origem or destino.startswith(origem + "/")):
                raise ValueError(f"{nome}: não dá para pôr uma pasta dentro dela mesma")
            if mover and os.path.dirname(origem) == destino:
                continue
            novo_nome = nome_livre(destino, nome, os.path.isdir(origem) and not os.path.islink(origem))
            alvo = os.path.join(destino, novo_nome)
            if mover:
                shutil.move(origem, alvo)
                if os.path.isdir(alvo) and not os.path.islink(alvo):
                    trocar_caminho_guardado(dados, origem, alvo)
                    mudou = True
            elif os.path.isdir(origem) and not os.path.islink(origem):
                shutil.copytree(origem, alvo, symlinks=True)
            else:
                shutil.copy2(origem, alvo, follow_symlinks=False)
            nomes.append(novo_nome)
        except (OSError, ValueError, shutil.Error) as erro:
            texto = mensagem(erro)
            erros.append(texto if texto.startswith(nome + ":") else f"{nome}: {texto}")
    if mudou:
        gravar_guardado(dados)
    return {"nomes": nomes, "erros": erros}


def renomear(pedido):
    origem = normalizar(pedido["caminho"])
    pasta, antigo = os.path.split(origem)
    try:
        novo = validar_nome(pedido.get("nome"))
    except ValueError as erro:
        return {"erro": str(erro)}
    if novo == antigo:
        return {"nome": novo}
    if not os.path.lexists(origem):
        return {"erro": f"{antigo}: não existe mais"}
    alvo = os.path.join(pasta, novo)
    if os.path.lexists(alvo) and not os.path.samefile(origem, alvo):
        return {"erro": f"Já existe “{novo}” nesta pasta"}
    try:
        os.rename(origem, alvo)
    except OSError as erro:
        return {"erro": mensagem(erro)}
    dados = ler_guardado()
    guardado = dados.get(pasta)
    if guardado and antigo in (guardado.get("ordem") or []):
        guardado["ordem"] = [novo if nome == antigo else nome for nome in guardado["ordem"]]
    if os.path.isdir(alvo) and not os.path.islink(alvo):
        trocar_caminho_guardado(dados, origem, alvo)
    gravar_guardado(dados)
    return {"nome": novo}


def nova_pasta(pedido):
    pasta = normalizar(pedido["pasta"])
    try:
        nome = validar_nome(pedido.get("nome"))
    except ValueError as erro:
        return {"erro": str(erro)}
    if os.path.lexists(os.path.join(pasta, nome)):
        return {"erro": f"Já existe “{nome}” nesta pasta"}
    try:
        os.mkdir(os.path.join(pasta, nome))
    except OSError as erro:
        return {"erro": mensagem(erro)}
    return {"nome": nome}


def lixeira(pedido):
    erros = []
    for item in pedido.get("itens") or []:
        caminho = normalizar(item)
        nome = os.path.basename(caminho)
        if not os.path.lexists(caminho):
            erros.append(f"{nome}: não existe mais")
            continue
        processo = subprocess.run(["gio", "trash", "--", caminho], capture_output=True, text=True)
        if processo.returncode != 0:
            detalhe = processo.stderr.strip().splitlines()
            erros.append(f"{nome}: não foi para a lixeira" + (f" ({detalhe[-1].rsplit(': ', 1)[-1]})" if detalhe else ""))
    return {"erros": erros}


ACOES = {
    "listar": listar,
    "ordem": gravar_ordem,
    "modo": mudar_modo,
    "mover": lambda pedido: transferir(pedido, True),
    "copiar": lambda pedido: transferir(pedido, False),
    "renomear": renomear,
    "nova-pasta": nova_pasta,
    "lixeira": lixeira,
}


def main():
    try:
        pedido = json.loads(sys.argv[1])
        acao = ACOES[pedido["acao"]]
    except (IndexError, ValueError, KeyError, TypeError):
        print(json.dumps({"erro": "Pedido inválido"}))
        return
    try:
        resposta = acao(pedido)
    except (OSError, KeyError, TypeError) as erro:
        resposta = {"erro": mensagem(erro)}
    print(json.dumps(resposta))


main()
