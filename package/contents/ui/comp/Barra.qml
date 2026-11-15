import QtQuick

Item {
    id: barra
    property real valor: 0
    property color cor: Tema.verde
    property color corTrilho: Tema.trilho

    implicitHeight: 4
    implicitWidth: 80

    Rectangle { anchors.fill: parent; radius: height / 2; color: barra.corTrilho }
    Rectangle {
        height: parent.height
        radius: height / 2
        color: barra.cor
        width: Math.max(height, parent.width * Math.max(0, Math.min(1, barra.valor)))
        visible: barra.valor > 0
        Behavior on width { NumberAnimation { duration: Tema.lento; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Tema.normal } }
    }
}
