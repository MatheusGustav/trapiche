import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "comp"
import "util.js" as Util

// Notas adesivas guardadas atrás do vidro da dock: só a ponta colorida de cada uma aparece acima dele.
// Passar o mouse levanta a ponta; clicar faz a nota subir de trás da barra. A última ponta, com "+", cria uma nota.
Item {
    id: adesivos

    property Item painel: null      // painel do Plasma, onde as pontas são desenhadas, por baixo do vidro
    property Item molde: null       // item do painel com a geometria do vidro
    property real fim: 0            // onde a fileira de pontas termina, na largura da dock

    readonly property var cores: [Tema.amarelo, Tema.laranja, Tema.verde, Tema.ciano, Tema.roxo, Tema.vermelho]
    // { cor: índice em cores, texto }
    readonly property var notas: Util.ler(Plasmoid.configuration.dados, "adesivos", [])
    property int aberta: -1
    property int sobre: -1
    // Nota que acabou de fechar: o clique na ponta dela pode chegar depois de o balão já ter fechado sozinho, e não a reabre.
    property int recemFechada: -1

    readonly property int larguraPonta: 34
    readonly property int alturaPonta: 30
    readonly property int vao: 6
    // Canto da dock dentro do painel. Refeito quando a dock ou o painel mudam de tamanho.
    readonly property point origem: {
        fim; parent.width; parent.height
        if (!painel || !molde) return Qt.point(0, 0)
        painel.width; molde.y
        return parent.mapToItem(painel, 0, 0)
    }
    // Espaço que sobra na janela do painel acima do vidro: é o quanto uma ponta consegue aparecer.
    readonly property real folga: molde ? molde.y : 0
    readonly property real inicio: Math.max(0, fim - (notas.length + 1) * (larguraPonta + vao))

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

    // Pontas, desenhadas no painel por baixo do vidro.
    Item {
        parent: adesivos.painel
        visible: adesivos.visible
        z: -2
        x: adesivos.origem.x + adesivos.inicio
        y: adesivos.molde ? adesivos.molde.y : 0

        Repeater {
            model: adesivos.notas.length + 1

            Rectangle {
                id: ponta
                required property int index
                readonly property bool nova: index === adesivos.notas.length
                readonly property bool levantada: adesivos.sobre === index || adesivos.aberta === index

                x: index * (adesivos.larguraPonta + adesivos.vao)
                y: -Math.min(adesivos.folga, levantada ? 8 : 5)
                width: adesivos.larguraPonta
                height: adesivos.alturaPonta
                topLeftRadius: 6
                topRightRadius: 6
                color: nova ? (Tema.escuro ? "#59ffffff" : "#59000000") : adesivos.cores[adesivos.notas[index].cor % adesivos.cores.length]
                Behavior on y { SpringAnimation { spring: 5; damping: 0.35; mass: 0.5 } }

                Icone {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 11 }
                    visible: ponta.nova
                    source: "list-add-symbolic"
                    tam: 12
                    cor: "white"
                }
            }
        }
    }

    // O toque fica na dock, por cima do painel; as pontas, por baixo do vidro, não receberiam o mouse.
    Repeater {
        id: toques
        model: adesivos.notas.length + 1

        MouseArea {
            required property int index

            x: adesivos.inicio + index * (adesivos.larguraPonta + adesivos.vao)
            y: -adesivos.origem.y
            width: adesivos.larguraPonta
            height: adesivos.folga + adesivos.alturaPonta - 5
            hoverEnabled: true
            onEntered: adesivos.sobre = index
            onExited: if (adesivos.sobre === index) adesivos.sobre = -1
            onClicked: index === adesivos.notas.length ? adesivos.criar() : adesivos.abrir(index)
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
