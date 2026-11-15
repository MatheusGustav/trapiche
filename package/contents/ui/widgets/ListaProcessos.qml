import QtQuick
import "../comp"
import "../dados"

// Três linhas "nome  valor" vindas de um comando que imprime "valor<TAB>nome".
Tile {
    id: raiz
    property string comando
    property int intervalo: 5000
    property var formatar: valor => valor
    property var linhas: []
    readonly property var cores: [Tema.azul, Tema.ciano, Tema.verde]

    largura: 236

    Periodico {
        comando: raiz.comando
        intervalo: raiz.intervalo
        onAtualizado: saida => {
            raiz.linhas = saida.trim().split("\n").filter(l => l.indexOf("\t") > 0).slice(0, 3).map(l => {
                const partes = l.split("\t")
                return { valor: parseFloat(partes[0]), nome: partes[1] }
            })
        }
    }

    Column {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 14; rightMargin: 14 }
        spacing: 5
        Repeater {
            model: raiz.linhas
            Item {
                required property var modelData
                required property int index
                width: parent.width; height: 17
                Rectangle {
                    id: marca
                    anchors.verticalCenter: parent.verticalCenter
                    width: 11; height: 11; radius: 3
                    color: raiz.cores[index]
                }
                Texto {
                    anchors { left: marca.right; leftMargin: 9; right: valor.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    text: modelData.nome
                    tam: 13
                }
                Texto {
                    id: valor
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: raiz.formatar(modelData.valor)
                    tam: 13
                    forte: true
                }
            }
        }
    }
}
