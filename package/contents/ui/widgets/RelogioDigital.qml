import QtQuick
import org.kde.plasma.plasmoid
import "../comp"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "relogio-digital")
    property date agora: new Date()
    readonly property int hora: Util.horaDoRelogio(agora, op.h24)

    largura: op.h24 ? 128 : 152

    Timer { interval: 1000; running: true; repeat: true; onTriggered: raiz.agora = new Date() }

    component Numero: Texto {
        tam: 35
        font.weight: Font.Light
        font.features: { "tnum": 1 }
    }

    Column {
        anchors.centerIn: parent
        spacing: -2
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            Numero { text: raiz.op.h24 ? Util.dois(raiz.hora) : raiz.hora }
            Numero { text: ":"; color: Tema.laranja; bottomPadding: 5 }
            Numero { text: Util.dois(raiz.agora.getMinutes()) }
            Texto {
                visible: !raiz.op.h24
                anchors.baseline: parent.children[0].baseline
                leftPadding: 4
                text: raiz.agora.getHours() < 12 ? "AM" : "PM"
                tam: 11
                forte: true
                fraco: true
            }
        }
        Texto {
            anchors.horizontalCenter: parent.horizontalCenter
            text: raiz.agora.toLocaleDateString(Qt.locale("pt_BR"), "ddd d MMM").replace(/\./g, "").toUpperCase()
            tam: 10
            forte: true
            fraco: true
            font.letterSpacing: 1.2
        }
    }
}
