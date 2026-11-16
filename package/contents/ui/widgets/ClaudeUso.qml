import QtQuick
import "../comp"
import "../dados"

// Uso da sessão (5 horas) do plano do Claude Code.
Tile {
    id: raiz
    readonly property var sessao: uso.pronto ? uso.dados.sessao : null
    largura: 212

    UsoClaude { id: uso }

    Marca {
        id: marca
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        logotipo: "claude"
        corLogotipo: "#faf9f5"
        color: "#d97757"
    }
    Item {
        anchors { left: marca.right; leftMargin: 12; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        height: 52
        Texto { text: "Sessão"; tam: 13; forte: true }
        Texto { anchors.right: parent.right; text: uso.falta(raiz.sessao); tam: 12; fraco: true }
        Texto { y: 17; text: uso.porcento(raiz.sessao); tam: 18; forte: true }
        Barra {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 5
            valor: uso.fracao(raiz.sessao)
        }
    }
}
