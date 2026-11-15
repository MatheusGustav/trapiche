import QtQuick
import org.kde.plasma.plasmoid
import "../comp"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "relogio-digital")
    property date agora: new Date()

    Timer { interval: 1000; running: true; repeat: true; onTriggered: raiz.agora = new Date() }

    Column {
        anchors.centerIn: parent
        spacing: -9
        Texto {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Util.dois(Util.horaDoRelogio(raiz.agora, raiz.op.h24))
            tam: 30
            forte: true
            font.features: { "tnum": 1 }
        }
        Texto {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Util.dois(raiz.agora.getMinutes())
            tam: 30
            font.weight: Font.Light
            font.features: { "tnum": 1 }
            color: Tema.laranja
        }
    }
}
