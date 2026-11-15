import QtQuick
import "../util.js" as Util

ListaProcessos {
    comando: "ps -eo rss=,comm= | awk '{r=$1; $1=\"\"; sub(/^ /,\"\"); m[$0]+=r} END{for(k in m) printf \"%d\\t%s\\n\", m[k], k}' | sort -rn | head -3"
    intervalo: 10000
    formatar: valor => Util.bytes(valor * 1024)
}
