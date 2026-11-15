#!/usr/bin/env python3
"""Soma os tokens usados no Claude Code a partir dos registros locais.

Imprime {"h5": tokens das últimas 5 horas, "d7": dos últimos 7 dias, "modelo": mais usado em 7 dias, "modeloTokens": tokens dele}.
Cada arquivo de registro só é relido quando muda; o resultado por arquivo fica em cache.
"""
import json
import os
import time
from datetime import datetime

BASE = os.path.join(os.path.expanduser(os.environ.get("CLAUDE_CONFIG_DIR", "~/.claude")), "projects")
CACHE = os.path.join(os.path.expanduser(os.environ.get("XDG_CACHE_HOME", "~/.cache")), "trapiche", "uso-claude.json")
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

    h5 = d7 = 0
    por_modelo = {}
    for dados in novo.values():
        for instante, tokens, modelo in dados["entradas"]:
            idade = agora - instante
            if idade > SEMANA:
                continue
            d7 += tokens
            por_modelo[modelo] = por_modelo.get(modelo, 0) + tokens
            if idade <= 5 * 3600:
                h5 += tokens
    modelo = max(por_modelo, key=por_modelo.get) if por_modelo else ""

    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    with open(CACHE + ".tmp", "w") as arquivo:
        json.dump(novo, arquivo)
    os.replace(CACHE + ".tmp", CACHE)
    print(json.dumps({"h5": h5, "d7": d7, "modelo": modelo, "modeloTokens": por_modelo.get(modelo, 0)}))


main()
