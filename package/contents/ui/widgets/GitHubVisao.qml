import QtQuick
import "../comp"
import "../dados"
import "../util.js" as Util

Tile {
    id: raiz
    largura: 216

    GitHub { id: github }

    Marca {
        id: marca
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        sigla: "GH"; color: "#24292f"
    }
    Texto {
        anchors { left: marca.right; leftMargin: 12; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        visible: !github.pronto
        text: github.aviso
        tam: 12; fraco: true
        wrapMode: Text.WordWrap
    }
    Column {
        visible: github.pronto
        anchors { left: marca.right; leftMargin: 12; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 2
        Repeater {
            model: [
                { rotulo: "Não lidas", valor: github.naoLidas >= 50 ? "50+" : github.naoLidas },
                { rotulo: "PRs", valor: github.prs },
                { rotulo: "Estrelas", valor: github.pronto ? Util.compacto(github.perfil.estrelas) : "" }
            ]
            Item {
                required property var modelData
                width: parent.width; height: 18
                Texto { anchors.verticalCenter: parent.verticalCenter; text: modelData.rotulo; tam: 13; fraco: true; forte: true }
                Texto { text: modelData.valor; tam: 14; forte: true; anchors { right: parent.right; verticalCenter: parent.verticalCenter } }
            }
        }
    }
}
