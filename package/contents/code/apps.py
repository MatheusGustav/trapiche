#!/usr/bin/env python3
"""Aplicativos instalados, lidos dos arquivos .desktop.

Recebe um JSON como argumento e imprime uma lista de {"id", "nome", "icone", "caminho"}:
  {"acao": "listar"}                    todos os aplicativos visíveis, por nome
  {"acao": "resolver", "ids": [...]}    só os pedidos, na ordem pedida, inclusive os que ficam fora do menu de
                                        aplicativos (os que não existem ficam de fora)
"""
import json
import os
import sys


def pastas():
    casa = os.path.expanduser(os.environ.get("XDG_DATA_HOME", "~/.local/share"))
    outras = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    return [os.path.join(pasta, "applications") for pasta in [casa] + outras if pasta]


def ler(caminho, fora_do_menu):
    """Campos do grupo [Desktop Entry], ou None se não for um aplicativo visível."""
    campos = {}
    dentro = False
    try:
        with open(caminho, errors="ignore") as arquivo:
            for linha in arquivo:
                linha = linha.strip()
                if linha.startswith("["):
                    dentro = linha == "[Desktop Entry]"
                elif dentro and "=" in linha and not linha.startswith("#"):
                    chave, valor = linha.split("=", 1)
                    campos[chave.strip()] = valor.strip()
    except OSError:
        return None
    if campos.get("Type") != "Application" or campos.get("Hidden") == "true":
        return None
    if campos.get("NoDisplay") == "true" and not fora_do_menu:
        return None
    ambientes = [a for a in campos.get("OnlyShowIn", "").split(";") if a]
    if (ambientes and "KDE" not in ambientes) or "KDE" in campos.get("NotShowIn", "").split(";"):
        return None
    nome = campos.get("Name[pt_BR]") or campos.get("Name[pt]") or campos.get("Name")
    if not nome:
        return None
    return {"nome": nome, "icone": campos.get("Icon", ""), "caminho": caminho}


def instalados(fora_do_menu):
    """Dicionário id -> aplicativo; a primeira pasta que tem o id vence."""
    achados = {}
    for base in pastas():
        for pasta, _, nomes in os.walk(base):
            for nome in nomes:
                if not nome.endswith(".desktop"):
                    continue
                caminho = os.path.join(pasta, nome)
                ident = os.path.relpath(caminho, base)[:-len(".desktop")].replace(os.sep, "-")
                if ident in achados:
                    continue
                app = ler(caminho, fora_do_menu)
                if app:
                    app["id"] = ident
                    achados[ident] = app
    return achados


def main():
    try:
        pedido = json.loads(sys.argv[1])
    except (IndexError, ValueError):
        pedido = {}
    apps = instalados(pedido.get("acao") == "resolver")
    if pedido.get("acao") == "resolver":
        saida = [apps[ident] for ident in pedido.get("ids") or [] if ident in apps]
    else:
        saida = sorted(apps.values(), key=lambda app: app["nome"].casefold())
    print(json.dumps(saida))


main()
