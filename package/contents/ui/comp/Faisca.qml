import QtQuick
import QtQuick.Shapes

// Gráfico de linha pequeno com área preenchida.
Item {
    id: faisca
    property var valores: []
    property color cor: Tema.verde
    property bool area: true
    property bool ponto: true
    property real espessura: 2

    readonly property var pontos: {
        const v = valores || []
        if (v.length < 2 || width <= 0) return []
        let min = Math.min(...v), max = Math.max(...v)
        if (max - min < 1e-9) { max = min + 1; min = min - 1 }
        const topo = espessura + 2, base = height - espessura - 1
        return v.map((y, i) => Qt.point(i * width / (v.length - 1), base - (y - min) / (max - min) * (base - topo)))
    }

    Shape {
        anchors.fill: parent
        visible: faisca.pontos.length > 1
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: 0; y2: faisca.height
                GradientStop { position: 0; color: faisca.area ? Qt.alpha(faisca.cor, 0.35) : "transparent" }
                GradientStop { position: 1; color: "transparent" }
            }
            PathPolyline {
                path: faisca.pontos.length > 1
                    ? [Qt.point(0, faisca.height)].concat(faisca.pontos, [Qt.point(faisca.width, faisca.height)])
                    : []
            }
        }
        ShapePath {
            strokeColor: faisca.cor
            strokeWidth: faisca.espessura
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: faisca.pontos }
        }
    }
    Rectangle {
        visible: faisca.ponto && faisca.pontos.length > 1
        width: 6; height: 6; radius: 3
        color: faisca.cor
        x: faisca.pontos.length > 1 ? faisca.pontos[faisca.pontos.length - 1].x - 3 : 0
        y: faisca.pontos.length > 1 ? faisca.pontos[faisca.pontos.length - 1].y - 3 : 0
    }
}
