import QtQuick

// Grade de arquivos que entra em cascata, saindo do ponto de origem (embaixo, no meio).
Item {
    id: grade
    property var itens: []          // { nome, url, pasta }
    property int colunas: 4
    property bool mostrar: false
    property string vazio: "Nada aqui"
    readonly property real celula: width / colunas
    signal aberto()

    implicitHeight: Math.max(1, Math.ceil(itens.length / colunas)) * 92

    Texto {
        anchors.centerIn: parent
        visible: grade.itens.length === 0
        text: grade.vazio
        fraco: true
    }

    Repeater {
        model: grade.itens

        Item {
            id: celula
            required property var modelData
            required property int index
            readonly property real destinoX: (index % grade.colunas) * grade.celula
            readonly property real destinoY: Math.floor(index / grade.colunas) * 92
            property real avanco: 0

            width: grade.celula
            height: 92
            x: destinoX + (1 - avanco) * (grade.width / 2 - grade.celula / 2 - destinoX)
            y: destinoY + (1 - avanco) * (grade.height - destinoY)
            scale: 0.35 + 0.65 * avanco
            opacity: Math.min(1, avanco * 1.6)

            states: State {
                name: "dentro"
                when: grade.mostrar
                PropertyChanges { target: celula; avanco: 1 }
            }
            transitions: [
                Transition {
                    to: "dentro"
                    SequentialAnimation {
                        PauseAnimation { duration: celula.index * 32 }
                        NumberAnimation { property: "avanco"; duration: 430; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                    }
                },
                Transition {
                    from: "dentro"
                    NumberAnimation { property: "avanco"; duration: 120 }
                }
            ]

            CelulaArquivo {
                anchors.fill: parent
                nome: celula.modelData.nome
                url: celula.modelData.url
                pasta: celula.modelData.pasta
                sobre: toque.containsMouse
                apertado: toque.pressed
            }
            MouseArea {
                id: toque
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    Qt.openUrlExternally(celula.modelData.url)
                    grade.aberto()
                }
            }
        }
    }
}
