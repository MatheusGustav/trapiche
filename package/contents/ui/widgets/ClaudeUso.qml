import QtQuick
import "../comp"
import "../dados"
import "../util.js" as Util

// Uso do Claude Code: tokens das últimas 5 horas.
Tile {
    id: raiz
    largura: 212

    UsoClaude { id: uso }

    Marca {
        id: marca
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        sigla: "C"
        color: "#d97757"
    }
    Item {
        anchors { left: marca.right; leftMargin: 12; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        height: 46
        Texto { text: "Sessão"; tam: 13; forte: true }
        Texto { anchors.right: parent.right; text: "5 horas"; tam: 12; fraco: true }
        Texto {
            anchors.bottom: parent.bottom
            text: uso.pronto ? Util.compacto(uso.dados.h5) : "–"
            tam: 20
            forte: true
        }
    }
}
