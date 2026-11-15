import QtQuick

// Bloco base da dock. O conteúdo é desenhado numa área de altura fixa 77 e escalado para a altura real.
Item {
    id: tile

    property real largura: 77
    readonly property real u: height / 77
    property bool clicavel: false
    property bool rolavel: false
    property color cor: Tema.tile
    property color corBorda: Tema.borda
    property real espessuraBorda: 1
    property bool semFundo: false
    readonly property bool sobre: pairar.hovered
    readonly property bool pressionado: toque.pressed
    default property alias conteudo: area.data

    signal clicado()
    signal rolado(int passo)

    implicitWidth: Math.round(largura * u)
    width: implicitWidth

    Item {
        id: moldura
        anchors.fill: parent
        scale: tile.clicavel ? (toque.pressed ? 0.94 : (pairar.hovered ? 1.03 : 1)) : 1
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.4; mass: 0.6 } }

        Rectangle {
            anchors.fill: parent
            visible: !tile.semFundo
            radius: 24 * tile.u
            color: tile.cor
            border.color: tile.corBorda
            border.width: tile.espessuraBorda
            Behavior on color { ColorAnimation { duration: Tema.normal } }
            Behavior on border.color { ColorAnimation { duration: Tema.normal } }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
            visible: !tile.semFundo
            height: parent.height / 2
            radius: 23 * tile.u
            gradient: Gradient {
                GradientStop { position: 0; color: Tema.brilho }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        Item {
            id: area
            width: tile.largura
            height: 77
            scale: tile.u
            transformOrigin: Item.TopLeft
        }
    }

    HoverHandler { id: pairar }
    TapHandler {
        id: toque
        enabled: tile.clicavel
        acceptedButtons: Qt.LeftButton
        onTapped: tile.clicado()
    }
    WheelHandler {
        enabled: tile.rolavel
        onWheel: evento => tile.rolado(evento.angleDelta.y > 0 ? 1 : -1)
    }
}
