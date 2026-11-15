import QtQuick
import org.kde.kirigami as Kirigami
import "../util.js" as Util

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

            Item {
                id: figura
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 6 }
                width: 48; height: 48
                scale: toque.pressed ? 0.9 : (toque.containsMouse ? 1.14 : 1)
                Behavior on scale { SpringAnimation { spring: 5; damping: 0.35; mass: 0.5 } }

                Kirigami.Icon {
                    anchors.fill: parent
                    visible: miniatura.status !== Image.Ready
                    source: Util.iconeArquivo(celula.modelData.nome, celula.modelData.pasta)
                }
                Image {
                    id: miniatura
                    anchors.fill: parent
                    source: !celula.modelData.pasta && Util.ehImagem(celula.modelData.nome) ? celula.modelData.url : ""
                    sourceSize: Qt.size(96, 96)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
            }
            Texto {
                anchors { left: parent.left; right: parent.right; top: figura.bottom; topMargin: 4; leftMargin: 4; rightMargin: 4 }
                text: celula.modelData.nome
                tam: 11
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignTop
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 2
                renderType: Text.NativeRendering
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
