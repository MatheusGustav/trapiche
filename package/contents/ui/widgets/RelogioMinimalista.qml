import QtQuick
import "../comp"

Tile {
    id: raiz
    property date agora: new Date()
    readonly property real minutos: agora.getMinutes() + agora.getSeconds() / 60

    Timer { interval: 1000; running: true; repeat: true; onTriggered: raiz.agora = new Date() }

    // Ponteiro que parte do centro do mostrador e gira em volta dele.
    component Ponteiro: Item {
        id: ponteiro
        property real comprimento
        property real espessura
        x: 28.5; y: 28.5
        Rectangle {
            x: -ponteiro.espessura / 2; y: -ponteiro.comprimento
            width: ponteiro.espessura; height: ponteiro.comprimento + ponteiro.espessura / 2
            radius: ponteiro.espessura / 2
            color: Tema.texto
        }
    }

    Item {
        anchors.centerIn: parent
        width: 57; height: 57

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 1
            width: 4; height: 4; radius: 2
            color: Tema.textoFraco
        }
        Ponteiro { comprimento: 15; espessura: 4; rotation: (raiz.agora.getHours() % 12 + raiz.minutos / 60) * 30 }
        Ponteiro { comprimento: 24; espessura: 2.5; rotation: raiz.minutos * 6 }
        Item {
            x: 28.5; y: 28.5
            rotation: raiz.agora.getSeconds() * 6
            Behavior on rotation { RotationAnimation { direction: RotationAnimation.Shortest; duration: Tema.normal; easing.type: Easing.OutBack } }
            Rectangle { x: -0.5; y: -25; width: 1; height: 32; color: Tema.laranja }
        }
        Rectangle {
            anchors.centerIn: parent
            width: 5; height: 5; radius: 2.5
            color: Tema.laranja
        }
    }
}
