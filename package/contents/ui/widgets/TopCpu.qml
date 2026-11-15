import QtQuick

ListaProcessos {
    comando: "LC_ALL=C top -b -n 2 -d 1 -w 512 | awk -v n=\"$(nproc)\" '/^ *PID/{b++; next} b==2 && NF>=12 {c=$12; for(i=13;i<=NF;i++) c=c\" \"$i; u[c]+=$9} END{for(k in u) printf \"%.1f\\t%s\\n\", u[k]/n, k}' | sort -rn | head -3"
    intervalo: 5000
    formatar: valor => valor.toFixed(1).replace(".", ",") + "%"
}
