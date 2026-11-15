"""Caminhos compartilhados pelos scripts do Trapiche."""
import os


def cache(nome):
    return os.path.join(os.path.expanduser(os.environ.get("XDG_CACHE_HOME", "~/.cache")), "trapiche", nome)


def dados(nome):
    return os.path.join(os.path.expanduser(os.environ.get("XDG_DATA_HOME", "~/.local/share")), "trapiche", nome)
