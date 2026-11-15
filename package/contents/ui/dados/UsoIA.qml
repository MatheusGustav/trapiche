import QtQuick
import "../util.js" as Util

// Tokens usados numa ferramenta de IA, lidos por um script do pacote.
Item {
    id: uso
    property string roteiro                 // nome do arquivo em code/
    property var dados: null                // { h5, d7, modelo, modeloTokens }
    readonly property bool pronto: dados !== null

    Periodico {
        comando: "python3 " + Util.script(Qt.resolvedUrl("."), uso.roteiro)
        intervalo: 300000
        onAtualizado: saida => {
            try { uso.dados = JSON.parse(saida) } catch (e) { uso.dados = null }
        }
    }
}
