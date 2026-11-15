import QtQuick
import "../comp"
import "../dados"

Tile {
    id: raiz
    readonly property int gomos: 14
    readonly property int acesos: Math.round(bateria.porcento / 100 * gomos)
    property int onda: -1

    Bateria { id: bateria }

    Timer {
        interval: 110
        running: bateria.carregando
        repeat: true
        onTriggered: raiz.onda = (raiz.onda + 1) % (raiz.gomos + 8)
        onRunningChanged: if (!running) raiz.onda = -1
    }

    Item {
        id: palco
        anchors.centerIn: parent
        width: 62; height: 62

        Repeater {
            model: raiz.gomos
            Item {
                required property int index
                readonly property bool aceso: index < raiz.acesos
                anchors.fill: parent
                rotation: index * 360 / raiz.gomos
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 0
                    width: 9; height: 4; radius: 2
                    color: parent.aceso ? bateria.cor : Tema.trilho
                    scale: raiz.onda === index ? 1.5 : 1
                    opacity: parent.aceso ? 1 : (raiz.onda === index ? 0.9 : 0.6)
                    Behavior on scale { NumberAnimation { duration: 220 } }
                    Behavior on color { ColorAnimation { duration: Tema.normal } }
                }
            }
        }
        Rectangle {
            id: nucleo
            anchors.centerIn: parent
            width: 40; height: 40; radius: 20
            color: Tema.escuro ? "#0c0c0e" : "#ffffff"
            border.width: 2
            border.color: bateria.cor
            Texto {
                anchors.centerIn: parent
                text: bateria.existe ? bateria.porcento : "–"
                tam: bateria.porcento === 100 ? 13 : 16
                forte: true
            }
            SequentialAnimation on scale {
                running: bateria.carregando || bateria.baixa
                loops: Animation.Infinite
                alwaysRunToEnd: true
                NumberAnimation { to: 1.08; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: 40; height: 40; radius: 20
            color: "transparent"
            border.width: 2
            border.color: bateria.cor
            opacity: 0
            SequentialAnimation {
                running: bateria.carregando
                loops: Animation.Infinite
                ParallelAnimation {
                    NumberAnimation { target: halo; property: "scale"; from: 1; to: 1.45; duration: 1400; easing.type: Easing.OutCubic }
                    NumberAnimation { target: halo; property: "opacity"; from: 0.7; to: 0; duration: 1400 }
                }
                PauseAnimation { duration: 400 }
            }
            id: halo
        }
    }
}
