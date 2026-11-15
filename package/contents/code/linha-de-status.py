#!/usr/bin/env python3
"""Linha de status do Claude Code: guarda os limites do plano para o widget do Trapiche.

O Claude Code entrega em stdin um JSON com rate_limits (five_hour e seven_day, cada um com
used_percentage e resets_at, em segundos). Grava o que veio em claude-limites.json, no cache,
como {"sessao": {"pct", "renova"}, "semana": {"pct", "renova"}}. Não imprime nada.
"""
import json
import os
import sys
import time

import caminhos

ARQUIVO = caminhos.cache("claude-limites.json")


def main():
    try:
        limites = json.load(sys.stdin).get("rate_limits") or {}
    except (ValueError, AttributeError):
        return
    novo = {}
    for chave, nome in (("five_hour", "sessao"), ("seven_day", "semana")):
        janela = limites.get(chave)
        if isinstance(janela, dict) and janela.get("used_percentage") is not None:
            novo[nome] = {"pct": janela["used_percentage"], "renova": janela.get("resets_at")}
    if not novo:
        return
    try:
        with open(ARQUIVO) as arquivo:
            atual = json.load(arquivo)
    except (OSError, ValueError):
        atual = {}
    atual.update(novo)
    atual["atualizado"] = int(time.time())
    os.makedirs(os.path.dirname(ARQUIVO), exist_ok=True)
    with open(ARQUIVO + ".tmp", "w") as arquivo:
        json.dump(atual, arquivo)
    os.replace(ARQUIVO + ".tmp", ARQUIVO)


main()
