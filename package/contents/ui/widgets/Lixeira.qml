import QtQuick
import "../comp"
import "../dados"

Tile {
    id: raiz
    property int quantidade: 0

    clicavel: true
    onClicado: executor.rodar("kioclient exec trash:/", null)

    Comando { id: executor }
    Periodico {
        comando: "ls -A \"${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files\" 2>/dev/null | wc -l"
        intervalo: 15000
        onAtualizado: saida => raiz.quantidade = parseInt(saida) || 0
    }

    Rectangle {
        anchors.centerIn: parent
        width: 52; height: 52; radius: 26
        color: Tema.botao
        Icone {
            id: icone
            anchors.centerIn: parent
            source: raiz.quantidade > 0 ? "user-trash-full-symbolic" : "user-trash-symbolic"
            tam: 24
            cor: Tema.textoFraco
            rotation: raiz.sobre ? -12 : 0
            Behavior on rotation { SpringAnimation { spring: 4; damping: 0.2 } }
        }
    }
    Rectangle {
        visible: raiz.quantidade > 0
        anchors { right: parent.right; top: parent.top; rightMargin: 8; topMargin: 8 }
        height: 17; width: Math.max(17, numero.implicitWidth + 9); radius: 8.5
        color: Tema.vermelho
        Texto { id: numero; anchors.centerIn: parent; text: raiz.quantidade > 99 ? "99+" : raiz.quantidade; tam: 10; forte: true; color: "white" }
    }
}
