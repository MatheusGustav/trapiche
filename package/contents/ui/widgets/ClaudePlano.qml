import QtQuick
import "../comp"
import "../dados"
import "../util.js" as Util

// Uso do Claude Code: últimas 5 horas, 7 dias e modelo mais usado.
Tile {
    id: raiz
    largura: 330

    UsoClaude { id: uso }

    Marca {
        id: marca
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        sigla: "C"
        color: "#d97757"
    }
    Texto {
        anchors { left: marca.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
        visible: !uso.pronto
        text: "Sem registros locais"
        tam: 12; fraco: true
    }
    Column {
        visible: uso.pronto
        anchors { left: marca.right; leftMargin: 12; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 2
        Repeater {
            model: uso.pronto ? [
                { rotulo: "Sessão", dica: "5 horas", valor: uso.dados.h5 },
                { rotulo: "Semana", dica: "7 dias", valor: uso.dados.d7 },
                { rotulo: Util.nomeModelo(uso.dados.modelo), dica: "mais usado", valor: uso.dados.modeloTokens }
            ] : []
            Item {
                required property var modelData
                width: parent.width; height: 18
                Texto { anchors.verticalCenter: parent.verticalCenter; text: modelData.rotulo; tam: 13; forte: true; width: 110 }
                Texto { text: modelData.dica; tam: 12; fraco: true; anchors { right: valor.left; rightMargin: 10; verticalCenter: parent.verticalCenter } }
                Texto {
                    id: valor
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: 62
                    horizontalAlignment: Text.AlignRight
                    text: Util.compacto(modelData.valor)
                    tam: 13
                    forte: true
                }
            }
        }
    }
}
