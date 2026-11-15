import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import "comp"
import "catalogo.js" as Catalogo

// Biblioteca de widgets: todos os widgets do catálogo, vivos, por categoria. Clicar põe na dock ou tira dela.
// A entrada "Opções" da lateral troca a grade pelas opções da dock e dos widgets que estão nela.
Balao {
    id: biblioteca

    property string categoria: ""           // vazia = todas
    property bool emOpcoes: false
    readonly property var naBarra: Plasmoid.configuration.widgets
    readonly property string busca: simples(campoBusca.text.trim())
    function simples(texto) { return texto.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "") }
    // Filtrar só esconde a célula: recriar o widget a cada letra digitada o faria recomeçar.
    function aparece(item) { return (categoria === "" || categoria === item.cat) && simples(item.nome).indexOf(busca) >= 0 }

    // Widget que aceita cópias entra de novo ("id:2", "id:3"...); os outros entram ou saem.
    function escolher(item) {
        const lista = Array.from(naBarra)
        if (!item.multi && lista.indexOf(item.id) >= 0) {
            Plasmoid.configuration.widgets = lista.filter(id => id !== item.id)
            return
        }
        let novo = item.id
        for (let n = 2; lista.indexOf(novo) >= 0; n++) novo = item.id + ":" + n
        Plasmoid.configuration.widgets = Catalogo.inserir(lista, novo)
    }

    fixo: true
    larguraConteudo: 900
    alturaConteudo: 580
    onAbriu: campoBusca.forceActiveFocus()

    Item {
        id: lateral
        x: 12; y: 12
        width: 196
        height: parent.height - 24

        PlasmaComponents.TextField {
            id: campoBusca
            width: parent.width
            placeholderText: "Buscar widgets"
            onTextEdited: biblioteca.emOpcoes = false
            Keys.onEscapePressed: text !== "" ? text = "" : biblioteca.visible = false
        }
        Column {
            anchors { top: campoBusca.bottom; topMargin: 10 }
            width: parent.width
            spacing: 2

            Repeater {
                model: [""].concat(Catalogo.categorias)

                Entrada {
                    required property string modelData
                    rotulo: modelData === "" ? "Todos os widgets" : modelData
                    escolhida: !biblioteca.emOpcoes && biblioteca.categoria === modelData
                    onClicado: {
                        biblioteca.emOpcoes = false
                        biblioteca.categoria = modelData
                        rolagem.contentY = 0
                    }
                }
            }
        }
        Entrada {
            anchors.bottom: parent.bottom
            rotulo: "Opções"
            escolhida: biblioteca.emOpcoes
            onClicado: biblioteca.emOpcoes = true
        }
    }

    component Entrada: Rectangle {
        id: entrada
        property string rotulo
        property bool escolhida: false
        signal clicado()

        width: parent.width
        height: 34
        radius: 10
        color: escolhida ? Tema.azul : (toque.containsMouse ? Tema.botao : "transparent")
        Behavior on color { ColorAnimation { duration: Tema.rapido } }

        Texto {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            text: entrada.rotulo
            tam: 13
            forte: entrada.escolhida
            color: entrada.escolhida ? "white" : Tema.texto
            renderType: Text.NativeRendering
        }
        MouseArea {
            id: toque
            anchors.fill: parent
            hoverEnabled: true
            onClicked: entrada.clicado()
        }
    }

    Texto {
        id: titulo
        x: lateral.x + lateral.width + 22; y: 10; height: 36
        text: biblioteca.emOpcoes ? "Opções" : (biblioteca.categoria === "" ? "Todos os widgets" : biblioteca.categoria)
        tam: 20
        forte: true
        renderType: Text.NativeRendering
    }
    Texto {
        anchors { left: titulo.right; leftMargin: 12; baseline: titulo.baseline }
        visible: !biblioteca.emOpcoes
        text: Catalogo.itens.length + " widgets · " + biblioteca.naBarra.length + " na dock"
        tam: 12
        fraco: true
        renderType: Text.NativeRendering
    }
    Row {
        anchors { right: parent.right; rightMargin: 12; verticalCenter: titulo.verticalCenter }
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: !biblioteca.emOpcoes
            width: rotuloOrdem.implicitWidth + 24
            height: 30
            radius: 15
            color: Tema.botao
            scale: toqueOrdem.pressed ? 0.94 : 1
            Behavior on scale { NumberAnimation { duration: Tema.rapido } }

            Texto {
                id: rotuloOrdem
                anchors.centerIn: parent
                text: "Ordem padrão"
                tam: 12
                renderType: Text.NativeRendering
            }
            MouseArea {
                id: toqueOrdem
                anchors.fill: parent
                onClicked: Plasmoid.configuration.widgets = Catalogo.ordenar(Array.from(biblioteca.naBarra))
            }
        }
        BotaoRedondo { tam: 30; icone: "window-close-symbolic"; onClicado: biblioteca.visible = false }
    }

    // As opções são montadas a cada abertura, com os valores daquele momento.
    Loader {
        anchors.fill: rolagem
        active: biblioteca.visible && biblioteca.emOpcoes
        sourceComponent: Opcoes { naBarra: biblioteca.naBarra }
    }
    Flickable {
        id: rolagem
        visible: !biblioteca.emOpcoes
        anchors { left: titulo.left; right: parent.right; top: titulo.bottom; bottom: parent.bottom; topMargin: 8; rightMargin: 4; bottomMargin: 8 }
        contentHeight: conteudo.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

        Column {
            id: conteudo
            width: rolagem.width - 14
            spacing: 6

            Texto {
                visible: !Catalogo.itens.some(item => biblioteca.aparece(item))
                height: 60
                text: "Nenhum widget com esse nome."
                tam: 13
                fraco: true
                renderType: Text.NativeRendering
            }
            Repeater {
                model: Catalogo.categorias

                Column {
                    id: secao
                    required property string modelData
                    readonly property var itens: Catalogo.itens.filter(item => item.cat === modelData)
                    width: conteudo.width
                    visible: itens.some(item => biblioteca.aparece(item))
                    spacing: 8

                    Texto {
                        visible: biblioteca.categoria === ""
                        height: 26
                        text: secao.modelData
                        tam: 12
                        forte: true
                        fraco: true
                        renderType: Text.NativeRendering
                    }
                    Flow {
                        width: parent.width
                        spacing: 12
                        leftPadding: 4
                        rightPadding: 8
                        bottomPadding: 10

                        Repeater {
                            model: secao.itens

                            Item {
                                id: celula
                                required property var modelData
                                readonly property bool usado: !modelData.multi && biblioteca.naBarra.indexOf(modelData.id) >= 0

                                width: Math.max(74, previa.width, Math.min(rotulo.implicitWidth, 120))
                                height: 58 + 24
                                visible: biblioteca.aparece(modelData)

                                // Widget de verdade; a área por cima fica com o clique e a roda.
                                Loader {
                                    id: previa
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    height: 58
                                    active: biblioteca.visible
                                    asynchronous: true
                                    source: "widgets/" + celula.modelData.arq
                                    scale: toqueCelula.pressed ? 0.95 : 1
                                    Behavior on scale { NumberAnimation { duration: Tema.rapido } }
                                }
                                Rectangle {
                                    anchors { fill: previa; margins: -3 }
                                    radius: 24 * 58 / 77 + 3
                                    color: "transparent"
                                    border.width: 2
                                    border.color: Tema.azul
                                    opacity: celula.usado || toqueCelula.containsMouse ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: Tema.rapido } }
                                }
                                Rectangle {
                                    anchors { right: previa.right; top: previa.top; rightMargin: -7; topMargin: -7 }
                                    visible: celula.usado
                                    width: 18; height: 18; radius: 9
                                    color: Tema.azul
                                    Icone { anchors.centerIn: parent; source: "checkmark-symbolic"; tam: 12; cor: "white" }
                                }
                                Texto {
                                    id: rotulo
                                    anchors { top: previa.bottom; topMargin: 5; horizontalCenter: parent.horizontalCenter }
                                    width: Math.min(implicitWidth, celula.width)
                                    text: celula.modelData.nome
                                    tam: 11
                                    fraco: true
                                    renderType: Text.NativeRendering
                                }
                                MouseArea {
                                    id: toqueCelula
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: biblioteca.escolher(celula.modelData)
                                    onWheel: roda => rolagem.contentY = Math.max(0, Math.min(rolagem.contentHeight - rolagem.height, rolagem.contentY - roda.angleDelta.y))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
