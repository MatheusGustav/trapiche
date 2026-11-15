import QtQuick
import "../comp"
import "../dados"

Tile {
    id: raiz
    largura: 230
    clicavel: true
    onClicado: Qt.openUrlExternally("https://github.com/notifications")

    GitHub { id: github }

    Texto {
        anchors { left: parent.left; leftMargin: 20; top: parent.top; topMargin: 10 }
        text: github.pronto ? (github.naoLidas >= 50 ? "50+" : github.naoLidas) : "–"
        tam: 26
        forte: true
    }
    Texto {
        anchors { left: parent.left; leftMargin: 20; right: parent.right; rightMargin: 14; bottom: parent.bottom; bottomMargin: 12 }
        text: github.pronto ? "Não lidas – " + github.perfil.login : github.aviso
        tam: 13
        fraco: true
    }
    Marca {
        anchors { right: parent.right; rightMargin: 14; top: parent.top; topMargin: 12 }
        tam: 24; sigla: "GH"; color: "#24292f"
    }
}
