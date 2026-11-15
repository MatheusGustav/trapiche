import QtQuick
import org.kde.kirigami as Kirigami
import "../dados"
import "../util.js" as Util

// Pasta de aplicativos: um quadro com até quatro miniaturas; alternar() abre a grade com todos.
Item {
    id: pasta
    property var ids: []            // ids dos arquivos .desktop, como code/apps.py os dá
    property string nome
    property string textoVazio
    property bool sobre: false
    property bool destaque: false
    readonly property string pedido: JSON.stringify({ acao: "resolver", ids: ids })
    property var apps: []           // { id, nome, icone, caminho }

    signal menuDoApp(var app, Item celula)

    width: 48; height: 48
    onPedidoChanged: carregar()

    function alternar() { balao.alternar() }
    function carregar() {
        executor.rodar("python3 " + Util.script(Qt.resolvedUrl("."), "apps.py") + " " + Util.aspas(pedido), saida => {
            try { pasta.apps = JSON.parse(saida) } catch (e) { pasta.apps = [] }
        })
    }
    function abrir(app) {
        executor.rodar("kioclient exec " + Util.aspas(app.caminho), null)
        balao.visible = false
    }

    Comando { id: executor }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Tema.botao
        border.width: pasta.destaque ? 2 : 0
        border.color: Tema.azul
        scale: pasta.destaque ? 1.12 : 1
        Behavior on scale { NumberAnimation { duration: Tema.rapido } }

        Grid {
            anchors.centerIn: parent
            columns: 2
            spacing: pasta.sobre ? 4 : 2
            Behavior on spacing { NumberAnimation { duration: Tema.rapido } }
            Repeater {
                model: pasta.apps.slice(0, 4)
                Kirigami.Icon {
                    required property var modelData
                    width: 18; height: 18
                    source: modelData.icone
                }
            }
        }
        Icone {
            anchors.centerIn: parent
            visible: pasta.apps.length === 0
            source: "list-add-symbolic"
            tam: 18
            cor: Tema.textoFraco
        }
    }

    Balao {
        id: balao
        readonly property int colunas: Math.max(2, Math.min(4, pasta.apps.length))
        visualParent: pasta
        larguraConteudo: colunas * 96
        alturaConteudo: 40 + Math.max(1, Math.ceil(pasta.apps.length / colunas)) * 96

        Texto {
            x: 10; height: 38
            text: pasta.nome
            tam: 15
            forte: true
            renderType: Text.NativeRendering
        }
        Texto {
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 44; leftMargin: 10; rightMargin: 10 }
            visible: pasta.apps.length === 0
            text: pasta.textoVazio
            tam: 12
            fraco: true
            wrapMode: Text.WordWrap
            renderType: Text.NativeRendering
        }
        Item {
            id: grade
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 40; bottom: parent.bottom }

            Repeater {
                model: pasta.apps
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
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => mouse.button === Qt.RightButton ? pasta.menuDoApp(celula.modelData, celula) : pasta.abrir(celula.modelData)
                    }
                }
            }
        }
    }
}
