import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import "../comp"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var lista: Util.ler(Plasmoid.configuration.dados, "tarefas", [])      // { t: texto, f: feita }
    readonly property var pendentes: lista.filter(i => !i.f)
    readonly property real feitas: lista.length > 0 ? (lista.length - pendentes.length) / lista.length : 0

    largura: 270
    clicavel: true
    onClicado: balao.alternar()

    function salvar(nova) { Plasmoid.configuration.dados = Util.gravar(Plasmoid.configuration.dados, "tarefas", nova) }
    function marcar(indice, feita) {
        const nova = lista.map((i, n) => n === indice ? { t: i.t, f: feita } : i)
        salvar(nova)
    }
    function remover(indice) { salvar(lista.filter((i, n) => n !== indice)) }
    function adicionar(texto) {
        if (texto.trim() === "") return
        salvar(lista.concat([{ t: texto.trim(), f: false }]))
    }

    component Caixa: Rectangle {
        id: caixa
        property bool feita
        signal clicado()
        width: 20; height: 20; radius: 10
        color: feita ? Tema.verde : "transparent"
        border.color: feita ? Tema.verde : Tema.textoFraco
        border.width: 1.5
        scale: toque.pressed ? 0.8 : (toque.containsMouse ? 1.15 : 1)
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; mass: 0.5 } }
        Behavior on color { ColorAnimation { duration: Tema.rapido } }
        Icone { anchors.centerIn: parent; visible: caixa.feita; source: "checkmark"; tam: 12; cor: "white" }
        MouseArea { id: toque; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; onClicked: caixa.clicado() }
    }

    Anel {
        id: anel
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        width: 42; height: 42
        valor: raiz.feitas
        cor: Tema.azul
        espessura: 4
        Texto { anchors.centerIn: parent; text: raiz.pendentes.length; tam: 16; forte: true }
    }
    Caixa {
        id: primeira
        anchors { left: anel.right; leftMargin: 16; verticalCenter: parent.verticalCenter }
        visible: raiz.pendentes.length > 0
        feita: false
        onClicado: raiz.marcar(raiz.lista.indexOf(raiz.pendentes[0]), true)
    }
    Texto {
        anchors { left: primeira.visible ? primeira.right : anel.right; leftMargin: primeira.visible ? 10 : 16; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        text: raiz.pendentes.length > 0 ? raiz.pendentes[0].t : (raiz.lista.length > 0 ? "Tudo feito" : "Sem tarefas")
        fraco: raiz.pendentes.length === 0
        tam: 14
    }

    Balao {
        id: balao
        visualParent: raiz
        larguraConteudo: 320
        alturaConteudo: 44 + Math.min(8, Math.max(1, raiz.lista.length)) * 34 + 46
        onAbriu: campo.forceActiveFocus()

        Texto { x: 10; height: 40; text: "Tarefas"; tam: 15; forte: true; renderType: Text.NativeRendering }
        ListView {
            id: itens
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 40; bottom: campo.top; bottomMargin: 8 }
            clip: true
            model: raiz.lista
            delegate: Item {
                id: linha
                required property var modelData
                required property int index
                width: itens.width; height: 34
                Caixa {
                    id: marca
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    feita: linha.modelData.f
                    onClicado: raiz.marcar(linha.index, !linha.modelData.f)
                }
                Texto {
                    anchors { left: marca.right; leftMargin: 10; right: apagar.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    text: linha.modelData.t
                    tam: 13
                    fraco: linha.modelData.f
                    font.strikeout: linha.modelData.f
                    renderType: Text.NativeRendering
                }
                BotaoRedondo {
                    id: apagar
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    tam: 24; color: "transparent"
                    icone: "edit-delete-symbolic"
                    corIcone: Tema.textoFraco
                    onClicado: raiz.remover(linha.index)
                }
            }
            Texto {
                anchors.centerIn: parent
                visible: raiz.lista.length === 0
                text: "Nenhuma tarefa"
                fraco: true
                renderType: Text.NativeRendering
            }
        }
        PlasmaComponents.TextField {
            id: campo
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 6 }
            placeholderText: "Nova tarefa"
            onAccepted: { raiz.adicionar(text); text = "" }
        }
    }
}
