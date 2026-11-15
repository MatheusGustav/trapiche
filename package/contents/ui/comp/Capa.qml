import QtQuick
import QtQuick.Effects

// Capa do que está tocando, com barrinhas que dançam enquanto toca.
Item {
    id: capa
    property string fonte
    property bool tocando: false

    width: 55; height: 55

    Rectangle {
        id: fundo
        anchors.fill: parent
        radius: 13
        gradient: Gradient {
            GradientStop { position: 0; color: Tema.roxo }
            GradientStop { position: 1; color: Tema.vermelho }
        }
    }
    Image {
        id: imagem
        anchors.fill: parent
        source: capa.fonte
        sourceSize: Qt.size(160, 160)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    Rectangle { id: recorte; anchors.fill: parent; radius: 13; visible: false; layer.enabled: true }
    MultiEffect {
        anchors.fill: parent
        source: imagem
        visible: imagem.status === Image.Ready
        maskEnabled: true
        maskSource: recorte
    }
    Row {
        anchors.centerIn: parent
        spacing: 3
        visible: imagem.status !== Image.Ready
        Repeater {
            model: 4
            Rectangle {
                required property int index
                anchors.verticalCenter: parent.verticalCenter
                width: 4; radius: 2
                height: 8
                color: "white"
                SequentialAnimation on height {
                    running: capa.tocando
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    NumberAnimation { to: 24 - index * 3; duration: 260 + index * 90; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 8; duration: 300 + index * 70; easing.type: Easing.InOutSine }
                }
            }
        }
    }
}
