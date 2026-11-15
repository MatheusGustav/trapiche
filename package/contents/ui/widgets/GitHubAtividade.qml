import QtQuick
import "../comp"
import "../dados"

Tile {
    id: raiz
    readonly property int colunas: 13
    readonly property var recentes: github.dias.slice(-colunas * 3)
    readonly property int maior: Math.max(1, ...recentes)

    largura: 208

    GitHub { id: github }

    Texto { anchors.centerIn: parent; visible: !github.pronto; text: github.aviso; tam: 12; fraco: true }

    Row {
        visible: github.pronto
        anchors { left: parent.left; leftMargin: 14; top: parent.top; topMargin: 9 }
        spacing: 9
        Repeater {
            model: [
                { n: github.hoje, r: "hoje" },
                { n: github.semana, r: "semana" },
                { n: github.sequencia, r: "seguidos" }
            ]
            Row {
                required property var modelData
                spacing: 3
                Texto { text: modelData.n; tam: 12; forte: true }
                Texto { text: modelData.r; tam: 12; fraco: true }
            }
        }
    }
    Grid {
        visible: github.pronto
        anchors { left: parent.left; leftMargin: 14; bottom: parent.bottom; bottomMargin: 10 }
        columns: raiz.colunas
        spacing: 3
        Repeater {
            model: raiz.recentes
            Rectangle {
                required property int modelData
                required property int index
                width: 11; height: 11; radius: 3
                color: modelData === 0 ? Tema.trilho : Qt.alpha(Tema.verde, 0.35 + 0.65 * Math.min(1, modelData / raiz.maior))
                scale: 0
                Component.onCompleted: scale = 1
                Behavior on scale { SequentialAnimation { PauseAnimation { duration: index * 12 } NumberAnimation { duration: 260; easing.type: Easing.OutBack } } }
            }
        }
    }
}
