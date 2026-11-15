#!/usr/bin/env python3
"""Soma os tokens usados no OpenCode a partir do banco local.

Imprime {"h5": tokens das últimas 5 horas, "d7": dos últimos 7 dias, "modelo": mais usado em 7 dias, "modeloTokens": tokens dele}.
"""
import json
import os
import sqlite3
import time

BANCO = os.path.join(os.path.expanduser(os.environ.get("XDG_DATA_HOME", "~/.local/share")), "opencode", "opencode.db")


def main():
    agora = time.time() * 1000
    semana = agora - 7 * 86400 * 1000
    conexao = sqlite3.connect("file:" + BANCO + "?mode=ro", uri=True)
    h5 = d7 = 0
    por_modelo = {}
    for criado, dados in conexao.execute("select time_created, data from message where time_created >= ?", (semana,)):
        try:
            mensagem = json.loads(dados)
        except ValueError:
            continue
        uso = mensagem.get("tokens")
        if mensagem.get("role") != "assistant" or not isinstance(uso, dict):
            continue
        cache = uso.get("cache") or {}
        tokens = sum(valor or 0 for valor in (
            uso.get("input"), uso.get("output"), uso.get("reasoning"), cache.get("read"), cache.get("write")))
        modelo = mensagem.get("modelID") or ""
        d7 += tokens
        por_modelo[modelo] = por_modelo.get(modelo, 0) + tokens
        if criado >= agora - 5 * 3600 * 1000:
            h5 += tokens
    modelo = max(por_modelo, key=por_modelo.get) if por_modelo else ""
    print(json.dumps({"h5": h5, "d7": d7, "modelo": modelo, "modeloTokens": por_modelo.get(modelo, 0)}))


main()
