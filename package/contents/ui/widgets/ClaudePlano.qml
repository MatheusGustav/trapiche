import QtQuick
import "../comp"
import "../dados"
import "../util.js" as Util

// Uso do plano do Claude Code: sessão (5 horas), semana e modelo mais usado.
Tile {
    id: raiz
    largura: 385

    UsoClaude { id: uso }

    Marca {
        id: marca
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        logotipo: "claude"
        corLogotipo: "#faf9f5"
        color: "#d97757"
    }
    Column {
        anchors { left: marca.right; leftMargin: 12; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 2
        Repeater {
            model: [
                { rotulo: "Sessão", janela: uso.pronto ? uso.dados.sessao : null, dica: uso.pronto ? uso.falta(uso.dados.sessao) : "" },
                { rotulo: "Semana", janela: uso.pronto ? uso.dados.semana : null, dica: uso.pronto ? uso.dia(uso.dados.semana) : "" }
            ]
            Item {
                id: linha
                required property var modelData
                width: parent.width; height: 18
                Texto { anchors.verticalCenter: parent.verticalCenter; text: linha.modelData.rotulo; tam: 13; forte: true }
                Barra {
                    anchors { left: parent.left; leftMargin: 92; right: dica.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    valor: uso.fracao(linha.modelData.janela)
                }
                Texto {
                    id: dica
                    anchors { right: valor.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    width: 52
                    horizontalAlignment: Text.AlignRight
                    text: linha.modelData.dica
                    tam: 12
                    fraco: true
                }
                Texto {
                    id: valor
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: 48
                    horizontalAlignment: Text.AlignRight
                    text: uso.porcento(linha.modelData.janela)
                    tam: 13
                    forte: true
                }
            }
        }
        Item {
            width: parent.width; height: 18
            Texto {
                anchors { left: parent.left; right: maisUsado.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: uso.pronto ? Util.nomeModelo(uso.dados.modelo) : "–"
                tam: 13
                forte: true
            }
            Texto {
                id: maisUsado
                anchors { right: tokens.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: "mais usado"
                tam: 12
                fraco: true
            }
            Texto {
                id: tokens
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: 62
                horizontalAlignment: Text.AlignRight
                text: uso.pronto ? Util.compacto(uso.dados.modeloTokens) : "–"
                tam: 13
                forte: true
            }
        }
    }
}
