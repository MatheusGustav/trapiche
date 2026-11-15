import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "comp"
import "util.js" as Util

// Notas adesivas guardadas atrás da dock: de cada uma só aparece uma aba colorida em cima do vidro, a partir do começo da dock.
// Passar o mouse levanta a aba; clicar faz a nota subir de trás da barra. A última aba, com "+", cria uma nota.
Item {
    id: adesivos

    property Item painel: null      // painel do Plasma
    property Item molde: null       // item do painel com a geometria do vidro
    property real inicio: 0         // onde a fileira começa, na largura da dock

    // Mostarda, laranja, verde, azul, roxo e vermelho, todos escuros; o texto da nota é claro.
    readonly property var cores: ["#946c12", "#b3530f", "#1e6e4a", "#1f4f8f", "#5c3a8a", "#9e2a2b"]
    readonly property color tinta: "#f5f5f7"
    // { cor: índice em cores, texto }
    readonly property var notas: Util.ler(Plasmoid.configuration.dados, "adesivos", [])
    property int aberta: -1
    // Aba com o mouse em cima. Zerada quando a nota fecha: a saída do mouse nem sempre chega com o balão aberto.
    property int sobre: -1
    // Nota que acabou de fechar: o clique na aba dela pode chegar depois de o balão já ter fechado sozinho, e não a reabre.
    property int recemFechada: -1

    readonly property int larguraAba: 140
    // Começo da dock dentro do painel. Refeito quando a dock ou o painel mudam de tamanho.
    readonly property real origem: {
        inicio; parent.width
        if (!painel || !molde) return 0
        painel.width; molde.x
        return parent.mapToItem(painel, 0, 0).x
    }
    readonly property int vao: 8
    readonly property int alturaAba: 16
    readonly property int alturaLevantada: 22
    // A nota aberta tem a largura de duas abas.
    readonly property int larguraNota: 2 * larguraAba + vao
    readonly property int alturaNota: 140

    function salvar(nova) { Plasmoid.configuration.dados = Util.gravar(Plasmoid.configuration.dados, "adesivos", nova) }
    function criar() {
        let cor = 0
        while (cor < cores.length - 1 && notas.some(n => n.cor === cor)) cor++
        if (notas.some(n => n.cor === cor)) cor = notas.length % cores.length
        const nova = notas.concat([{ cor: cor, texto: "" }])
        salvar(nova)
        Qt.callLater(abrir, nova.length - 1)
    }
    // Com outra nota aberta, o balão continua aberto e só troca de nota: fechar e abrir em seguida o faria perder o foco e sumir.
    function abrir(indice) {
        if (indice === recemFechada) return
        if (aberta === indice) {
            balao.visible = false
            return
        }
        indice -= largar(indice)
        if (!notas[indice]) {
            balao.visible = false
            return
        }
        aberta = indice
        editor.text = notas[indice].texto
        balao.visualParent = abas.itemAt(indice).ancora
        descer.stop()
        cartao.y = caixa.height
        balao.visible = true
        subir.restart()
        editor.forceActiveFocus()
        editor.cursorPosition = editor.length
    }
    // Grava a nota aberta e a tira da lista se ficou vazia. Devolve 1 se a que saiu estava antes da posição dada.
    function largar(posicao) {
        const indice = aberta
        guardar()
        aberta = -1
        if (indice < 0 || !notas[indice] || notas[indice].texto.trim() !== "") return 0
        salvar(notas.filter((n, k) => k !== indice))
        return indice < posicao ? 1 : 0
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
    function fechou() {
        sobre = -1
        recemFechada = aberta
        esquecer.restart()
        largar(0)
        cartao.y = caixa.height
    }

    // As abas ficam numa janela filha da do painel, encostada na borda de cima do vidro: aparece e some com ele.
    // Dentro da janela do painel não daria: ela acaba pouco acima do vidro, e o Plasma desvia para os blocos o clique nessa beirada.
    WindowContainer {
        parent: adesivos.painel
        visible: adesivos.visible && adesivos.painel !== null
        x: adesivos.origem + adesivos.inicio
        y: (adesivos.molde ? adesivos.molde.y : 0) - height
        width: (adesivos.notas.length + 1) * (adesivos.larguraAba + adesivos.vao) - adesivos.vao
        height: adesivos.alturaLevantada + 4

        window: Window {
            color: "transparent"
            flags: Qt.FramelessWindowHint

            Repeater {
                id: abas
                model: adesivos.notas.length + 1

                MouseArea {
                    id: aba
                    required property int index
                    readonly property bool nova: index === adesivos.notas.length
                    property real altura: adesivos.sobre === index || adesivos.aberta === index ? adesivos.alturaLevantada : adesivos.alturaAba
                    Behavior on altura { SpringAnimation { spring: 5; damping: 0.35; mass: 0.5 } }

                    x: index * (adesivos.larguraAba + adesivos.vao)
                    width: adesivos.larguraAba
                    height: parent.height
                    hoverEnabled: true
                    onEntered: adesivos.sobre = index
                    onExited: if (adesivos.sobre === index) adesivos.sobre = -1
                    onClicked: nova ? adesivos.criar() : adesivos.abrir(index)

                    // O balão se centra neste item: a nota sobe com a borda esquerda na da aba.
                    property alias ancora: ancora
                    Item { id: ancora; width: adesivos.larguraNota; height: parent.height }

                    // O que passa do fim da janela fica escondido, como se estivesse atrás da barra.
                    Rectangle {
                        y: parent.height - aba.altura
                        width: parent.width
                        height: aba.altura + 8
                        radius: 6
                        color: aba.nova ? (Tema.escuro ? "#8cffffff" : "#8c000000") : adesivos.cores[adesivos.notas[aba.index].cor % adesivos.cores.length]

                        Icone {
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: (adesivos.alturaAba - tam) / 2 }
                            visible: aba.nova
                            source: "list-add-symbolic"
                            tam: 12
                            cor: Tema.escuro ? "#1c1c1e" : "white"
                        }
                    }
                }
            }
        }
    }

    Balao {
        id: balao
        backgroundHints: PlasmaCore.Dialog.NoBackground
        larguraConteudo: adesivos.larguraNota
        alturaConteudo: adesivos.alturaNota + 16
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
                height: adesivos.alturaNota
                radius: 4
                color: papel
                Behavior on color { ColorAnimation { duration: Tema.rapido } }

                Rectangle { width: parent.width; height: 14; radius: 4; color: Qt.darker(cartao.papel, 1.15) }
                Flickable {
                    id: rolagem
                    anchors { fill: parent; topMargin: 16; bottomMargin: 34; leftMargin: 6; rightMargin: 6 }
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    QQC2.TextArea.flickable: QQC2.TextArea {
                        id: editor
                        background: null
                        color: adesivos.tinta
                        placeholderText: "Escreva aqui"
                        placeholderTextColor: Qt.alpha(adesivos.tinta, 0.5)
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
                            border.color: Qt.alpha(adesivos.tinta, 0.7)
                            MouseArea { anchors { fill: parent; margins: -3 } onClicked: adesivos.pintar(parent.index) }
                        }
                    }
                }
                Icone {
                    anchors { right: parent.right; rightMargin: 12; bottom: parent.bottom; bottomMargin: 8 }
                    source: "edit-delete-symbolic"
                    tam: 18
                    cor: adesivos.tinta
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
