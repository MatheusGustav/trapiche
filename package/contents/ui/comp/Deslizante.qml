import QtQuick

// Barra larga que se arrasta para escolher um valor de 0 a 1.
Item {
    id: deslizante
    property real valor: 0
    property color cor: Tema.azul
    readonly property bool arrastando: area.pressed
    signal escolhido(real valor)

    implicitHeight: 26
    implicitWidth: 120

    Rectangle {
        id: trilho
        anchors.fill: parent
        radius: height / 2
        color: Tema.trilho
        scale: area.pressed ? 1.03 : 1
        Behavior on scale { NumberAnimation { duration: Tema.rapido } }

        Rectangle {
            height: parent.height
            radius: height / 2
            width: Math.max(height, parent.width * Math.max(0, Math.min(1, deslizante.valor)))
            visible: deslizante.valor > 0
            color: deslizante.cor
            Behavior on width { enabled: !area.pressed; NumberAnimation { duration: Tema.normal; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Tema.normal } }
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        function emitir(x) { deslizante.escolhido(Math.max(0, Math.min(1, x / width))) }
        onPressed: mouse => emitir(mouse.x)
        onPositionChanged: mouse => { if (pressed) emitir(mouse.x) }
        onWheel: roda => deslizante.escolhido(Math.max(0, Math.min(1, deslizante.valor + (roda.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
