import QtQuick
import "../comp"
import "../dados"
import "../util.js" as Util

// Uma linha por ferramenta de IA: tokens das últimas 5 horas e dos últimos 7 dias.
Tile {
    id: raiz
    largura: 330

    UsoIA { id: claude; roteiro: "uso-claude.py" }
    UsoIA { id: opencode; roteiro: "uso-opencode.py" }

    Column {
        anchors { left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 6
        Repeater {
            model: [
                { nome: "Claude", sigla: "C", cor: "#d97757", uso: claude },
                { nome: "OpenCode", sigla: "OC", cor: "#26262b", uso: opencode }
            ]
            Item {
                id: linha
                required property var modelData
                readonly property var dados: modelData.uso.dados
                width: parent.width; height: 24
                Marca { id: marca; tam: 24; sigla: linha.modelData.sigla; color: linha.modelData.cor }
                Texto { text: linha.modelData.nome; tam: 14; forte: true; anchors { left: marca.right; leftMargin: 9; verticalCenter: parent.verticalCenter } }
                Barra {
                    anchors { left: parent.left; leftMargin: 122; right: semana.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    valor: linha.dados && linha.dados.d7 > 0 ? linha.dados.h5 / linha.dados.d7 : 0
                }
                Texto {
                    id: semana
                    anchors { right: sessao.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    width: 62; horizontalAlignment: Text.AlignRight
                    text: linha.dados ? Util.compacto(linha.dados.d7) : "–"
                    tam: 12; fraco: true
                }
                Texto {
                    id: sessao
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: 58; horizontalAlignment: Text.AlignRight
                    text: linha.dados ? Util.compacto(linha.dados.h5) : "–"
                    tam: 14; forte: true
                }
            }
        }
    }
}
