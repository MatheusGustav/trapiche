#!/usr/bin/env python3
"""Lançador de um site, para ele entrar na dock como um aplicativo.

Recebe um JSON como argumento e imprime outro:
  {"acao": "criar", "url": "https://..."}
      Cria o arquivo .desktop do site (fora do menu de aplicativos) e baixa o maior ícone que o site publica.
      Imprime {"id", "nome", "bruto", "icone"}: "bruto" é o ícone baixado ("" se o site não tem um que sirva, ou se o
      ícone já está pronto) e "icone" é o arquivo que o lançador usa, que a dock pinta a partir do bruto.
  {"acao": "apagar", "id": "trapiche-site-..."}
      Apaga o .desktop e os ícones do site.
"""
import hashlib
import json
import os
import re
import struct
import sys
import urllib.parse
import urllib.request
from html.parser import HTMLParser

import caminhos

AGENTE = "Mozilla/5.0 (compatible; icon-fetcher)"
PREFIXO = "trapiche-site-"
MINIMO = 64             # ícone menor que isto ficaria borrado na dock
BASTA = 180
TENTATIVAS = 6


def baixar(url, limite):
    if urllib.parse.urlsplit(url).scheme not in ("http", "https"):
        raise ValueError(url)
    pedido = urllib.request.Request(url, headers={"User-Agent": AGENTE, "Accept-Language": "pt-BR,pt;q=0.9,en;q=0.5"})
    with urllib.request.urlopen(pedido, timeout=8) as resposta:
        return resposta.read(limite), resposta.geturl()


class Pagina(HTMLParser):
    """Guarda o que a página diz do próprio nome e dos ícones."""

    def __init__(self):
        super().__init__()
        self.nomes = {}
        self.icones = []        # (tamanho declarado, endereço)
        self.manifesto = ""
        self.titulo = ""
        self.no_titulo = False

    def handle_starttag(self, tag, atributos):
        a = {chave: (valor or "").strip() for chave, valor in atributos}
        if tag == "title":
            self.no_titulo = True
        elif tag == "meta":
            chave = (a.get("property") or a.get("name") or "").lower()
            if chave in ("og:site_name", "application-name", "apple-mobile-web-app-title") and a.get("content"):
                self.nomes.setdefault(chave, a["content"])
        elif tag == "link" and a.get("href"):
            rel = a.get("rel", "").lower().split()
            if "manifest" in rel:
                self.manifesto = a["href"]
            elif "apple-touch-icon" in rel or "apple-touch-icon-precomposed" in rel:
                self.icones.append((declarado(a.get("sizes")) or 180, a["href"]))
            elif "icon" in rel:
                self.icones.append((declarado(a.get("sizes")) or (512 if a["href"].lower().endswith(".svg") else 32), a["href"]))

    def handle_endtag(self, tag):
        if tag == "title":
            self.no_titulo = False

    def handle_data(self, texto):
        if self.no_titulo:
            self.titulo += texto


def declarado(sizes):
    """Maior lado de um atributo sizes ("32x32 192x192", "any")."""
    if not sizes:
        return 0
    if "any" in sizes.lower():
        return 512
    return max([int(n) for n in re.findall(r"(\d+)x\d+", sizes.lower())] or [0])


def medir(dados):
    """(extensão, maior lado em pixels) de uma imagem, ou None se não for uma que a dock saiba abrir."""
    if dados[:8] == b"\x89PNG\r\n\x1a\n" and len(dados) >= 24:
        return "png", max(struct.unpack(">II", dados[16:24]))
    if dados[:6] in (b"GIF87a", b"GIF89a") and len(dados) >= 10:
        return "gif", max(struct.unpack("<HH", dados[6:10]))
    if dados[:4] == b"RIFF" and dados[8:12] == b"WEBP" and len(dados) >= 30:
        if dados[12:16] == b"VP8X":
            return "webp", 1 + max(int.from_bytes(dados[24:27], "little"), int.from_bytes(dados[27:30], "little"))
        if dados[12:16] == b"VP8L":
            bits = int.from_bytes(dados[21:25], "little")
            return "webp", 1 + max(bits & 0x3FFF, (bits >> 14) & 0x3FFF)
        return "webp", max(n & 0x3FFF for n in struct.unpack("<HH", dados[26:30]))
    if dados[:2] == b"\xff\xd8":
        p = 2
        while p + 9 < len(dados) and dados[p] == 0xFF:
            marca = dados[p + 1]
            if 0xC0 <= marca <= 0xCF and marca not in (0xC4, 0xC8, 0xCC):
                return "jpg", max(struct.unpack(">HH", dados[p + 5:p + 9]))
            p += 2 + struct.unpack(">H", dados[p + 2:p + 4])[0]
        return "jpg", 0
    if dados[:4] == b"\x00\x00\x01\x00":
        return "ico", max([lado for lado, _ in entradas_ico(dados)] or [0])
    if b"<svg" in dados[:2048].lower():
        return "svg", 1024
    return None


def entradas_ico(dados):
    """(lado, bytes da imagem) de cada imagem de um .ico."""
    saida = []
    for n in range(struct.unpack("<H", dados[4:6])[0]):
        entrada = dados[6 + 16 * n:22 + 16 * n]
        if len(entrada) < 16:
            break
        tamanho, onde = struct.unpack("<II", entrada[8:16])
        saida.append((max(entrada[0] or 256, entrada[1] or 256), entrada[:8] + struct.pack("<II", tamanho, 22) + dados[onde:onde + tamanho]))
    return saida


def maior_do_ico(dados):
    """A maior imagem de um .ico: o PNG de dentro dele, ou um .ico só com ela."""
    _, entrada = max(entradas_ico(dados), key=lambda e: e[0])
    imagem = entrada[16:]
    if imagem[:8] == b"\x89PNG\r\n\x1a\n":
        return "png", imagem
    return "ico", b"\x00\x00\x01\x00\x01\x00" + entrada


def icones_do_manifesto(endereco):
    try:
        dados, endereco = baixar(endereco, 500_000)
        manifesto = json.loads(dados.decode("utf-8", "ignore"))
    except Exception:
        return [], ""
    icones = [(declarado(i.get("sizes")) or 48, urllib.parse.urljoin(endereco, i["src"]))
              for i in manifesto.get("icons") or [] if isinstance(i, dict) and i.get("src")]
    return icones, str(manifesto.get("short_name") or manifesto.get("name") or "")


def melhor_icone(candidatos):
    """Baixa os candidatos do maior para o menor e fica com o maior de verdade: (extensão, bytes) ou None."""
    melhor = None
    vistos = set()
    for _, endereco in sorted(candidatos, key=lambda c: -c[0]):
        if endereco in vistos or len(vistos) >= TENTATIVAS:
            continue
        vistos.add(endereco)
        try:
            dados, _ = baixar(endereco, 3_000_000)
        except Exception:
            continue
        medida = medir(dados)
        if not medida:
            continue
        tipo, lado = medida
        if tipo == "ico":
            tipo, dados = maior_do_ico(dados)
        if not melhor or lado > melhor[0]:
            melhor = (lado, tipo, dados)
        if lado >= BASTA:
            break
    return melhor[1:] if melhor and melhor[0] >= MINIMO else None


def arquivos(ident):
    aplicativos = os.path.join(os.path.expanduser(os.environ.get("XDG_DATA_HOME", "~/.local/share")), "applications")
    return os.path.join(aplicativos, ident + ".desktop"), caminhos.dados(os.path.join("sites", ident)), caminhos.cache(os.path.join("sites", ident))


def apagar(ident):
    if not re.fullmatch(PREFIXO + r"[a-z0-9-]+", ident or ""):
        return {}
    desktop, icone, bruto = arquivos(ident)
    for caminho in (desktop, icone + ".png", icone + ".svg", bruto):
        try:
            os.remove(caminho)
        except OSError:
            pass
    return {"id": ident}


def criar(url):
    partes = urllib.parse.urlsplit(url.strip())
    if partes.scheme not in ("http", "https") or not partes.hostname:
        return {}
    # O endereço vai entre aspas na linha Exec: o que as quebraria fica codificado.
    url = re.sub(r'[\s"`$\\<>]', lambda c: "%%%02X" % ord(c.group()), partes.geturl())
    resumo = hashlib.sha1(url.encode()).hexdigest()[:8]
    trecho = re.sub(r"[^a-z0-9]+", "-", (partes.hostname + partes.path).lower()).strip("-")[:40].strip("-")
    ident = PREFIXO + trecho + "-" + resumo
    desktop, icone, bruto = arquivos(ident)

    pagina = Pagina()
    base = url
    try:
        dados, base = baixar(url, 1_500_000)
        pagina.feed(dados.decode("utf-8", "ignore"))
    except Exception:
        pass
    candidatos = [(lado, urllib.parse.urljoin(base, endereco)) for lado, endereco in pagina.icones]
    nome_do_manifesto = ""
    if pagina.manifesto:
        do_manifesto, nome_do_manifesto = icones_do_manifesto(urllib.parse.urljoin(base, pagina.manifesto))
        candidatos += do_manifesto
    candidatos += [(179, urllib.parse.urljoin(base, "/apple-touch-icon.png")), (1, urllib.parse.urljoin(base, "/favicon.ico"))]

    hospedeiro = re.sub(r"^www\.", "", partes.hostname)
    nome = (pagina.nomes.get("og:site_name") or pagina.nomes.get("application-name")
            or pagina.nomes.get("apple-mobile-web-app-title") or nome_do_manifesto
            or re.split(r"\s+[-|·—–:]\s+", pagina.titulo.strip())[0] or hospedeiro)
    nome = " ".join(nome.split())[:40] or hospedeiro

    for pasta in (os.path.dirname(desktop), os.path.dirname(icone), os.path.dirname(bruto)):
        os.makedirs(pasta, exist_ok=True)
    achado = melhor_icone(candidatos)
    saida = {"id": ident, "nome": nome, "bruto": "", "icone": icone + ".png"}
    if achado and achado[0] == "svg":
        # Desenho vetorial já serve como está, em qualquer tamanho.
        saida["icone"] = icone + ".svg"
        with open(saida["icone"], "wb") as arquivo:
            arquivo.write(achado[1])
    elif achado:
        saida["bruto"] = bruto
        with open(bruto, "wb") as arquivo:
            arquivo.write(achado[1])
    with open(desktop, "w") as arquivo:
        arquivo.write("[Desktop Entry]\nType=Application\nName=%s\nComment=%s\nExec=kioclient exec \"%s\"\nIcon=%s\n"
                      "NoDisplay=true\nStartupNotify=false\n" % (nome, url, url.replace("%", "%%"), saida["icone"]))
    return saida


def main():
    try:
        pedido = json.loads(sys.argv[1])
    except (IndexError, ValueError):
        pedido = {}
    if pedido.get("acao") == "criar":
        print(json.dumps(criar(str(pedido.get("url") or ""))))
    elif pedido.get("acao") == "apagar":
        print(json.dumps(apagar(str(pedido.get("id") or ""))))
    else:
        print("{}")


main()
