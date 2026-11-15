import QtQuick
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "../comp"
import "../dados"
import "../util.js" as Util

// Pasta de aplicativos: quatro miniaturas no bloco; ao clicar, abre a grade com todos.
Tile {
    id: raiz
    property string instancia: "grupo-apps"
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, instancia)
    readonly property string pedido: JSON.stringify({ acao: "resolver", ids: op.apps })
    property var apps: []           // { id, nome, icone, caminho }

    clicavel: true
    onClicado: balao.alternar()
    onPedidoChanged: carregar()

    function carregar() {
        executor.rodar("python3 " + Util.script(Qt.resolvedUrl("."), "apps.py") + " " + Util.aspas(pedido), saida => {
            try { raiz.apps = JSON.parse(saida) } catch (e) { raiz.apps = [] }
        })
    }
    function abrir(app) {
        executor.rodar("kioclient exec " + Util.aspas(app.caminho), null)
        balao.visible = false
    }

    Comando { id: executor }

    Rectangle {
        anchors.centerIn: parent
        width: 57; height: 57; radius: 15
        color: Tema.botao

        Grid {
            anchors.centerIn: parent
            columns: 2
            spacing: raiz.sobre ? 5 : 3
            Behavior on spacing { NumberAnimation { duration: Tema.rapido } }
            Repeater {
                model: raiz.apps.slice(0, 4)
                Kirigami.Icon {
                    required property var modelData
                    width: 22; height: 22
                    source: modelData.icone
                }
            }
        }
        Icone {
            anchors.centerIn: parent
            visible: raiz.apps.length === 0
            source: "list-add-symbolic"
            tam: 22
            cor: Tema.textoFraco
        }
    }

    Balao {
        id: balao
        readonly property int colunas: Math.max(2, Math.min(4, raiz.apps.length))
        visualParent: raiz
        larguraConteudo: colunas * 96
        alturaConteudo: 40 + Math.max(1, Math.ceil(raiz.apps.length / colunas)) * 96

        Texto {
            x: 10; height: 38
            text: raiz.op.nome
            tam: 15
            forte: true
            renderType: Text.NativeRendering
        }
        Texto {
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 44; leftMargin: 10; rightMargin: 10 }
            visible: raiz.apps.length === 0
            text: "Escolha os aplicativos em Configurar Trapiche, aba Opções."
            tam: 12
            fraco: true
            wrapMode: Text.WordWrap
            renderType: Text.NativeRendering
        }
        Item {
            id: grade
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 40; bottom: parent.bottom }

            Repeater {
                model: raiz.apps
                Item {
                    id: celula
                    required property var modelData
                    required property int index
                    readonly property real destinoX: (index % balao.colunas) * 96
                    readonly property real destinoY: Math.floor(index / balao.colunas) * 96
                    property real avanco: 0

                    width: 96; height: 96
                    x: destinoX + (1 - avanco) * (grade.width / 2 - 48 - destinoX)
                    y: destinoY + (1 - avanco) * (grade.height - destinoY)
                    scale: 0.35 + 0.65 * avanco
                    opacity: Math.min(1, avanco * 1.6)

                    states: State {
                        name: "dentro"
                        when: balao.visible
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

                    Kirigami.Icon {
                        id: figura
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 8 }
                        width: 48; height: 48
                        source: celula.modelData.icone
                        scale: toque.pressed ? 0.9 : (toque.containsMouse ? 1.14 : 1)
                        Behavior on scale { SpringAnimation { spring: 5; damping: 0.35; mass: 0.5 } }
                    }
                    Texto {
                        anchors { left: parent.left; right: parent.right; top: figura.bottom; topMargin: 5; leftMargin: 4; rightMargin: 4 }
                        text: celula.modelData.nome
                        tam: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignTop
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        renderType: Text.NativeRendering
                    }
                    MouseArea {
                        id: toque
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: raiz.abrir(celula.modelData)
                    }
                }
            }
        }
    }
}
