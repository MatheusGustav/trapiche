#!/usr/bin/env bash
# Roda o plasmoide num compositor virtual (fora da tela, com configuração descartável) e salva uma foto.
# uso: [PACOTE=dir] [WIDGETS=a,b] [OPCOES='{}'] [DADOS='{}'] [ABRIR=id] dev/foto.sh saida.png [largura] [altura] [espera_s]
set -u
saida=$(realpath -m "${1:?saida.png}"); larg=${2:-1400}; alt=${3:-140}; espera=${4:-4}
raiz=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
mkdir -p "$tmp/data/plasma/plasmoids" "$tmp/config"
ln -s "${PACOTE:-$raiz/package}" "$tmp/data/plasma/plasmoids/io.github.matheusgustav.trapiche"
cp "${XDG_CONFIG_HOME:-$HOME/.config}/kdeglobals" "$tmp/config/" 2>/dev/null
{
    printf '[Applets][4]\nimmutability=1\nplugin=io.github.matheusgustav.trapiche\n\n[Applets][4][Configuration][General]\n'
    [ -n "${WIDGETS:-}" ] && printf 'widgets=%s\n' "$WIDGETS"
    [ -n "${OPCOES:-}" ] && printf 'opcoes=%s\n' "$OPCOES"
    [ -n "${DADOS:-}" ] && printf 'dados=%s\n' "$DADOS"
    [ -n "${ABRIR:-}" ] && printf 'testeAbrir=%s\n' "$ABRIR"
} > "$tmp/config/plasmawindowedrc"
cat > "$tmp/dentro.sh" <<DENTRO
QT_FORCE_STDERR_LOGGING=1 plasmawindowed io.github.matheusgustav.trapiche &
sleep $espera
spectacle -b -f -n -o "$saida"
sleep 1
kill %1
DENTRO
XDG_CONFIG_HOME="$tmp/config" XDG_DATA_DIRS="$tmp/data:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" \
    dbus-run-session -- kwin_wayland --virtual --width "$larg" --height "$alt" --no-lockscreen \
    --socket "wl-trapiche-$$" --exit-with-session "bash $tmp/dentro.sh" 2>"$tmp/log.txt"
grep -E "\.qml|\.js|qml:" "$tmp/log.txt" | grep -v "^kwin_" | sort | uniq -c | head -"${LINHAS_LOG:-25}"
[ -n "${MANTER_LOG:-}" ] && cp "$tmp/log.txt" "$MANTER_LOG"
rm -rf "$tmp"
