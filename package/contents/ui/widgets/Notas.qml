import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import "../comp"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property string nota: Util.ler(Plasmoid.configuration.dados, "nota", "")
    readonly property var linhas: nota.split("\n").filter(l => l.trim() !== "")

    largura: 270
    clicavel: true
    onClicado: balao.alternar()

    Rectangle {
        id: bloco
        anchors { left: parent.left; leftMargin: 11; verticalCenter: parent.verticalCenter }
        width: 55; height: 55; radius: 12
        color: "#f7f5ee"
        clip: true
        rotation: raiz.sobre ? -5 : 0
        Behavior on rotation { SpringAnimation { spring: 4; damping: 0.25 } }
        Rectangle { width: parent.width; height: 15; radius: 12; color: Tema.amarelo }
        Rectangle { y: 8; width: parent.width; height: 8; color: Tema.amarelo }
        Repeater {
            model: 3
            Rectangle { required property int index; x: 8; y: 25 + index * 9; width: parent.width - 16; height: 1.5; color: "#d5d2c6" }
        }
    }
    Column {
        anchors { left: bloco.right; leftMargin: 13; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        spacing: 2
        Texto { width: parent.width; text: raiz.linhas.length > 0 ? raiz.linhas[0] : "Nota"; tam: 15; forte: true }
        Texto {
            width: parent.width
            text: raiz.linhas.length > 1 ? raiz.linhas.slice(1).join(" ") : (raiz.linhas.length === 0 ? "Clique para escrever" : "")
            visible: text !== ""
            tam: 12
            fraco: true
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }
    }

    Balao {
        id: balao
        visualParent: raiz
        larguraConteudo: 340
        alturaConteudo: 260
        onAbriu: {
            editor.text = raiz.nota
            editor.forceActiveFocus()
        }
        onVisibleChanged: if (!visible) gravacao.gravar()

        PlasmaComponents.TextArea {
            id: editor
            anchors.fill: parent
            anchors.margins: 4
            placeholderText: "Escreva aqui"
            wrapMode: TextEdit.Wrap
            onTextChanged: if (balao.visible) gravacao.restart()
        }
        Timer {
            id: gravacao
            interval: 800
            function gravar() {
                stop()
                if (editor.text !== raiz.nota)
                    Plasmoid.configuration.dados = Util.gravar(Plasmoid.configuration.dados, "nota", editor.text)
            }
            onTriggered: gravar()
        }
    }
}
