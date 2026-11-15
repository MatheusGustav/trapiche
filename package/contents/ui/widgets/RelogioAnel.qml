import QtQuick
import org.kde.plasma.plasmoid
import "../comp"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "relogio-digital")
    property date agora: new Date()

    Timer { interval: 1000; running: true; repeat: true; onTriggered: raiz.agora = new Date() }

    Anel {
        anchors.centerIn: parent
        width: 57; height: 57
        valor: (raiz.agora.getMinutes() * 60 + raiz.agora.getSeconds()) / 3600
        cor: Tema.laranja
        espessura: 4
    }
    Column {
        anchors.centerIn: parent
        spacing: -4
        Texto {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Util.horaDoRelogio(raiz.agora, raiz.op.h24)
            tam: 21
            forte: true
        }
        Texto {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Util.dois(raiz.agora.getMinutes())
            tam: 11
            forte: true
            fraco: true
        }
    }
}
