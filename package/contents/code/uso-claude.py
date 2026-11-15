#!/usr/bin/env python3
"""Uso do Claude Code: limites do plano e tokens.

Imprime {"sessao": {"pct", "renova"} ou null, "semana": idem, "modelo": mais usado em 7 dias, "modeloTokens": tokens dele}.
Os limites vêm do arquivo gravado por linha-de-status.py; os tokens, dos registros locais.
Cada arquivo de registro só é relido quando muda; o resultado por arquivo fica em cache.
"""
import json
import os
import time
from datetime import datetime

import caminhos

BASE = os.path.join(os.path.expanduser(os.environ.get("CLAUDE_CONFIG_DIR", "~/.claude")), "projects")
CACHE = caminhos.cache("uso-claude.json")
SEMANA = 7 * 86400


def ler_arquivo(caminho):
    """Lista de [instante, tokens, modelo], uma entrada por mensagem do assistente."""
    vistos = {}
    with open(caminho, errors="ignore") as arquivo:
        for linha in arquivo:
            if '"output_tokens"' not in linha:
                continue
            try:
                registro = json.loads(linha)
                mensagem = registro["message"]
                uso = mensagem["usage"]
                instante = datetime.fromisoformat(registro["timestamp"].replace("Z", "+00:00")).timestamp()
            except (ValueError, KeyError, TypeError):
                continue
            tokens = sum(uso.get(chave) or 0 for chave in (
                "input_tokens", "output_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"))
            vistos[mensagem.get("id") or len(vistos)] = [instante, tokens, mensagem.get("model") or ""]
    return list(vistos.values())


def limites(agora):
    """Janelas de 5 horas e 7 dias. Uma janela cujo prazo já passou volta zerada, sem prazo."""
    try:
        with open(caminhos.cache("claude-limites.json")) as arquivo:
            dados = json.load(arquivo)
    except (OSError, ValueError):
        dados = {}
    resultado = {}
    for nome in ("sessao", "semana"):
        janela = dados.get(nome)
        if not isinstance(janela, dict):
            resultado[nome] = None
        elif janela.get("renova") and janela["renova"] <= agora:
            resultado[nome] = {"pct": 0, "renova": None}
        else:
            resultado[nome] = janela
    return resultado


def main():
    agora = time.time()
    try:
        with open(CACHE) as arquivo:
            cache = json.load(arquivo)
    except (OSError, ValueError):
        cache = {}
    novo = {}
    for pasta, _, nomes in os.walk(BASE):
        for nome in nomes:
            if not nome.endswith(".jsonl"):
                continue
            caminho = os.path.join(pasta, nome)
            try:
                estado = os.stat(caminho)
            except OSError:
                continue
            if estado.st_mtime < agora - SEMANA:
                continue
            assinatura = [estado.st_size, estado.st_mtime]
            antigo = cache.get(caminho)
            if antigo and antigo["assinatura"] == assinatura:
                novo[caminho] = antigo
            else:
                novo[caminho] = {"assinatura": assinatura, "entradas": ler_arquivo(caminho)}

    por_modelo = {}
    for dados in novo.values():
        for instante, tokens, modelo in dados["entradas"]:
            idade = agora - instante
            if idade > SEMANA:
                continue
            por_modelo[modelo] = por_modelo.get(modelo, 0) + tokens
    modelo = max(por_modelo, key=por_modelo.get) if por_modelo else ""

    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    with open(CACHE + ".tmp", "w") as arquivo:
        json.dump(novo, arquivo)
    os.replace(CACHE + ".tmp", CACHE)
    saida = limites(agora)
    saida.update({"modelo": modelo, "modeloTokens": por_modelo.get(modelo, 0)})
    print(json.dumps(saida))


main()
