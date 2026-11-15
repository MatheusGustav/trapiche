import QtQuick
import QtQuick.Shapes

// Arco de progresso. inicio em graus (0 = direita, sentido horário), varredura = arco total.
Item {
    id: anel
    property real valor: 0
    property real espessura: 5
    property color cor: Tema.verde
    property color corTrilho: Tema.trilho
    property real inicio: -90
    property real varredura: 360
    property bool animar: true
    readonly property real mostrado: valorAnimado

    property real valorAnimado: valor
    Behavior on valorAnimado {
        enabled: anel.animar
        NumberAnimation { duration: Tema.lento; easing.type: Easing.OutCubic }
    }

    implicitWidth: 52
    implicitHeight: 52

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: anel.corTrilho
            strokeWidth: anel.espessura
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: anel.width / 2; centerY: anel.height / 2
                radiusX: (anel.width - anel.espessura) / 2; radiusY: (anel.height - anel.espessura) / 2
                startAngle: anel.inicio; sweepAngle: anel.varredura
            }
        }
        ShapePath {
            strokeColor: anel.valorAnimado > 0.001 ? anel.cor : "transparent"
            strokeWidth: anel.espessura
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: anel.width / 2; centerY: anel.height / 2
                radiusX: (anel.width - anel.espessura) / 2; radiusY: (anel.height - anel.espessura) / 2
                startAngle: anel.inicio
                sweepAngle: anel.varredura * Math.max(0, Math.min(1, anel.valorAnimado))
            }
        }
    }
}
