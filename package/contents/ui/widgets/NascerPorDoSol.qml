import QtQuick
import QtQuick.Shapes
import "../comp"
import "../dados" as Dados

Tile {
    id: raiz
    property real agora: Date.now()
    readonly property real nascer: clima.pronto ? new Date(clima.dados.daily.sunrise[0]).getTime() : 0
    readonly property real por: clima.pronto ? new Date(clima.dados.daily.sunset[0]).getTime() : 0
    // 0 no nascer, 1 no pôr do sol
    readonly property real posicao: por > nascer ? Math.max(0, Math.min(1, (agora - nascer) / (por - nascer))) : 0
    readonly property bool dia: agora >= nascer && agora <= por

    largura: 230

    Dados.Clima { id: clima }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: raiz.agora = Date.now() }

    Texto { anchors.centerIn: parent; visible: !clima.pronto; text: clima.aviso; tam: 12; fraco: true }

    Item {
        id: ceu
        visible: clima.pronto
        anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 18; rightMargin: 18; topMargin: 12 }
        height: 30
        property real avanco: raiz.posicao
        Behavior on avanco { NumberAnimation { duration: 1400; easing.type: Easing.OutCubic } }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Tema.laranja
                strokeWidth: 2
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 0; startY: ceu.height
                PathQuad { x: ceu.width; y: ceu.height; controlX: ceu.width / 2; controlY: -ceu.height * 0.6 }
            }
        }
        Rectangle {
            readonly property real t: ceu.avanco
            width: 12; height: 12; radius: 6
            color: raiz.dia ? Tema.amarelo : Tema.textoFraco
            x: t * ceu.width - 6
            y: (1 - t) * (1 - t) * ceu.height + 2 * (1 - t) * t * (-ceu.height * 0.6) + t * t * ceu.height - 6
        }
    }
    Texto {
        visible: clima.pronto
        anchors { left: parent.left; leftMargin: 18; bottom: parent.bottom; bottomMargin: 9 }
        text: clima.pronto ? "☀ " + clima.dados.daily.sunrise[0].substr(11, 5) : ""
        tam: 13
        forte: true
    }
    Texto {
        visible: clima.pronto
        anchors { right: parent.right; rightMargin: 18; bottom: parent.bottom; bottomMargin: 9 }
        text: clima.pronto ? clima.dados.daily.sunset[0].substr(11, 5) + " ☾" : ""
        tam: 13
        forte: true
    }
}
