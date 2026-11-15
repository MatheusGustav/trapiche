import QtQuick
import "../comp"
import "../dados"

Tile {
    id: raiz
    readonly property int colunas: 7
    readonly property int fileiras: 6
    readonly property int acesos: Math.round(bateria.porcento / 100 * colunas * fileiras)
    property int onda: -1

    Bateria { id: bateria }

    Timer {
        interval: 140
        running: bateria.carregando
        repeat: true
        onTriggered: raiz.onda = (raiz.onda + 1) % (raiz.fileiras + 5)
        onRunningChanged: if (!running) raiz.onda = -1
    }

    Grid {
        anchors.centerIn: parent
        columns: raiz.colunas
        spacing: 3
        Repeater {
            model: raiz.colunas * raiz.fileiras
            Rectangle {
                required property int index
                // Enche de baixo para cima, da esquerda para a direita.
                readonly property int fileiraDeBaixo: raiz.fileiras - 1 - Math.floor(index / raiz.colunas)
                readonly property int ordem: fileiraDeBaixo * raiz.colunas + index % raiz.colunas
                readonly property bool aceso: ordem < raiz.acesos
                width: 5.5; height: 5.5; radius: 2.75
                color: aceso ? bateria.cor : Tema.trilho
                scale: raiz.onda === fileiraDeBaixo ? 1.35 : 1
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: Tema.normal } }
            }
        }
    }
}
