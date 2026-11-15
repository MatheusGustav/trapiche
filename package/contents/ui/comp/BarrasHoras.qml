import QtQuick

// 24 barras, uma por hora do dia; valores em minutos (0 a 60).
Row {
    id: barras
    property var valores: []
    property color cor: Tema.azul
    property int horaAtual: -1
    property real larguraBarra: 4
    property real alturaMaxima: 24

    spacing: 2
    height: alturaMaxima

    Repeater {
        model: 24
        Rectangle {
            required property int index
            readonly property real minutos: barras.valores[index] || 0
            anchors.bottom: parent.bottom
            width: barras.larguraBarra
            radius: width / 2
            height: minutos > 0 ? Math.max(width, minutos / 60 * barras.alturaMaxima) : 2
            color: minutos > 0 ? barras.cor : Tema.trilho
            opacity: index === barras.horaAtual || minutos > 0 ? 1 : 0.7
            Behavior on height { NumberAnimation { duration: Tema.lento; easing.type: Easing.OutCubic } }
        }
    }
}
