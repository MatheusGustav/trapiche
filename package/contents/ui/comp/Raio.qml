import QtQuick
import QtQuick.Shapes

// Raio desenhado em vetor (indica carga).
Shape {
    id: raio
    property color cor: Tema.texto
    property real tam: 14

    width: tam * 0.62
    height: tam
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: "transparent"
        fillColor: raio.cor
        PathPolyline {
            path: [
                Qt.point(raio.width * 0.62, 0),
                Qt.point(0, raio.height * 0.58),
                Qt.point(raio.width * 0.44, raio.height * 0.58),
                Qt.point(raio.width * 0.34, raio.height),
                Qt.point(raio.width, raio.height * 0.4),
                Qt.point(raio.width * 0.54, raio.height * 0.4),
                Qt.point(raio.width * 0.62, 0)
            ]
        }
    }
}
