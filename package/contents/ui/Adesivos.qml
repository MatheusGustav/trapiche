import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "comp"
import "util.js" as Util

// Notas adesivas guardadas atrás da dock: de cada uma só aparece um tracinho colorido preso à borda de cima do vidro, a partir do começo da dock.
// Passar o mouse levanta o tracinho; clicar faz a nota subir de trás da barra. O último tracinho, com "+", cria uma nota.
Item {
    id: adesivos

    property Item painel: null      // painel do Plasma, onde os tracinhos são desenhados
    property Item molde: null       // item do painel com a geometria do vidro
    property real inicio: 0         // onde a fileira começa, na largura da dock

    readonly property var cores: [Tema.amarelo, Tema.laranja, Tema.verde, Tema.ciano, Tema.roxo, Tema.vermelho]
    // { cor: índice em cores, texto }
    readonly property var notas: Util.ler(Plasmoid.configuration.dados, "adesivos", [])
    property int aberta: -1
    property int sobre: -1
    // Nota que acabou de fechar: o clique na ponta dela pode chegar depois de o balão já ter fechado sozinho, e não a reabre.
    property int recemFechada: -1

    readonly property int larguraPonta: 120
    // Começo da dock dentro do painel. Refeito quando a dock ou o painel mudam de tamanho.
    readonly property real origem: {
        inicio; parent.width
        if (!painel || !molde) return 0
        painel.width; molde.x
        return parent.mapToItem(painel, 0, 0).x
    }
    readonly property int vao: 8
    // Espaço que sobra na janela do painel acima do vidro: é o quanto um tracinho consegue passar da borda.
    readonly property real folga: molde ? molde.y : 0
    // Quanto o tracinho desce por cima do vidro e da beirada dos blocos.
    readonly property int descida: 8

    function salvar(nova) { Plasmoid.configuration.dados = Util.gravar(Plasmoid.configuration.dados, "adesivos", nova) }
    function criar() {
        let cor = 0
        while (cor < cores.length - 1 && notas.some(n => n.cor === cor)) cor++
        if (notas.some(n => n.cor === cor)) cor = notas.length % cores.length
        const nova = notas.concat([{ cor: cor, texto: "" }])
        salvar(nova)
        Qt.callLater(abrir, nova.length - 1)
    }
    function abrir(indice) {
        const mesma = aberta === indice
        if (balao.visible) balao.visible = false
        if (mesma || indice === recemFechada || !notas[indice]) return
        aberta = indice
        editor.text = notas[indice].texto
        balao.visualParent = toques.itemAt(indice)
        balao.visible = true
        descer.stop()
        subir.restart()
        editor.forceActiveFocus()
    }
    function guardar() {
        gravacao.stop()
        if (aberta >= 0 && notas[aberta] && editor.text !== notas[aberta].texto)
            salvar(notas.map((n, k) => k === aberta ? { cor: n.cor, texto: editor.text } : n))
    }
    function pintar(cor) {
        gravacao.stop()
        salvar(notas.map((n, k) => k === aberta ? { cor: cor, texto: editor.text } : n))
    }
    function apagar() {
        const indice = aberta
        aberta = -1
        balao.visible = false
        salvar(notas.filter((n, k) => k !== indice))
    }
    // Ao fechar, o texto é gravado; a nota que ficou vazia some.
    function fechou() {
        const indice = aberta
        guardar()
        aberta = -1
        recemFechada = indice
        esquecer.restart()
        cartao.y = caixa.height
        if (indice >= 0 && notas[indice] && notas[indice].texto.trim() === "") salvar(notas.filter((n, k) => k !== indice))
    }

    // Fileira no painel, por cima do vidro.
    Item {
        parent: adesivos.painel
        visible: adesivos.visible
        z: 1
        x: adesivos.origem + adesivos.inicio

        Repeater {
            model: adesivos.notas.length + 1

            Rectangle {
                id: ponta
                required property int index
                readonly property bool nova: index === adesivos.notas.length
                // Quanto passa da borda do vidro: mais com o mouse em cima ou com a nota aberta.
                property real sobra: Math.min(adesivos.folga, adesivos.sobre === index || adesivos.aberta === index ? 8 : 5)
                Behavior on sobra { SpringAnimation { spring: 5; damping: 0.35; mass: 0.5 } }

                x: index * (adesivos.larguraPonta + adesivos.vao)
                y: adesivos.folga - sobra
                width: adesivos.larguraPonta
                height: sobra + adesivos.descida
                radius: 4
                color: nova ? (Tema.escuro ? "#8cffffff" : "#8c000000") : adesivos.cores[adesivos.notas[index].cor % adesivos.cores.length]

                Icone {
                    anchors.centerIn: parent
                    visible: ponta.nova
                    source: "list-add-symbolic"
                    tam: 10
                    cor: Tema.escuro ? "#1c1c1e" : "white"
                }
            }
        }
        // O toque cobre o tracinho inteiro, levantado.
        Repeater {
            id: toques
            model: adesivos.notas.length + 1

            PlasmaCore.ToolTipArea {
                id: toque
                required property int index
                readonly property bool nova: index === adesivos.notas.length

                x: index * (adesivos.larguraPonta + adesivos.vao)
                width: adesivos.larguraPonta
                height: adesivos.folga + adesivos.descida
                active: !balao.visible
                mainText: nova ? "Nova nota" : adesivos.notas[index].texto.trim().split("\n")[0]

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: adesivos.sobre = toque.index
                    onExited: if (adesivos.sobre === toque.index) adesivos.sobre = -1
                    onClicked: toque.nova ? adesivos.criar() : adesivos.abrir(toque.index)
                }
            }
        }
    }

    Balao {
        id: balao
        backgroundHints: PlasmaCore.Dialog.NoBackground
        larguraConteudo: 250
        alturaConteudo: 246
        onVisibleChanged: if (!visible) adesivos.fechou()

        Item {
            id: caixa
            anchors.fill: parent
            clip: true

            Rectangle {
                id: cartao
                readonly property color papel: adesivos.aberta >= 0 && adesivos.notas[adesivos.aberta]
                    ? adesivos.cores[adesivos.notas[adesivos.aberta].cor % adesivos.cores.length] : adesivos.cores[0]
                y: caixa.height
                width: parent.width
                height: 230
                radius: 4
                color: papel
                Behavior on color { ColorAnimation { duration: Tema.rapido } }

                Rectangle { width: parent.width; height: 26; radius: 4; color: Qt.darker(cartao.papel, 1.08) }
                Flickable {
                    id: rolagem
                    anchors { fill: parent; topMargin: 30; bottomMargin: 34; leftMargin: 6; rightMargin: 6 }
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    QQC2.TextArea.flickable: QQC2.TextArea {
                        id: editor
                        background: null
                        color: "#1c1c1e"
                        placeholderText: "Escreva aqui"
                        placeholderTextColor: "#801c1c1e"
                        wrapMode: TextEdit.Wrap
                        onTextChanged: if (balao.visible) gravacao.restart()
                        Keys.onEscapePressed: balao.visible = false
                    }
                }
                Row {
                    anchors { left: parent.left; leftMargin: 12; bottom: parent.bottom; bottomMargin: 10 }
                    spacing: 7

                    Repeater {
                        model: adesivos.cores
                        Rectangle {
                            required property color modelData
                            required property int index
                            width: 14; height: 14; radius: 7
                            color: modelData
                            border.width: 1.5
                            border.color: "#801c1c1e"
                            MouseArea { anchors { fill: parent; margins: -3 } onClicked: adesivos.pintar(parent.index) }
                        }
                    }
                }
                Icone {
                    anchors { right: parent.right; rightMargin: 12; bottom: parent.bottom; bottomMargin: 8 }
                    source: "edit-delete-symbolic"
                    tam: 18
                    cor: "#1c1c1e"
                    MouseArea { anchors { fill: parent; margins: -4 } onClicked: adesivos.apagar() }
                }
            }
            NumberAnimation { id: subir; target: cartao; property: "y"; to: caixa.height - cartao.height; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            NumberAnimation { id: descer; target: cartao; property: "y"; to: caixa.height; duration: 160 }
        }
        Timer {
            id: esquecer
            interval: 250
            onTriggered: adesivos.recemFechada = -1
        }
        Timer {
            id: gravacao
            interval: 800
            onTriggered: adesivos.guardar()
        }
    }
}
