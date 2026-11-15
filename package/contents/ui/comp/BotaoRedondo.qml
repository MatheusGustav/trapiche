import QtQuick

Rectangle {
    id: botao
    property string icone
    property color corIcone: Tema.texto
    property real tam: 36
    property real tamIcone: tam * 0.5
    signal clicado()

    width: tam
    height: tam
    radius: tam / 2
    color: Tema.botao
    scale: area.pressed ? 0.88 : (area.containsMouse ? 1.08 : 1)
    Behavior on scale { SpringAnimation { spring: 5; damping: 0.35; mass: 0.5 } }
    Behavior on color { ColorAnimation { duration: Tema.rapido } }

    Icone {
        anchors.centerIn: parent
        source: botao.icone
        tam: botao.tamIcone
        cor: botao.corIcone
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: botao.clicado()
    }
}
