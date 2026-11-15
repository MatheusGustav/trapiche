import QtQuick
import "../util.js" as Util

// Tokens usados no Claude Code, lidos dos registros locais por um script do pacote.
Item {
    id: uso
    property var dados: null                // { h5, d7, modelo, modeloTokens }
    readonly property bool pronto: dados !== null

    Periodico {
        comando: "python3 " + Util.script(Qt.resolvedUrl("."), "uso-claude.py")
        intervalo: 300000
        onAtualizado: saida => {
            try { uso.dados = JSON.parse(saida) } catch (e) { uso.dados = null }
        }
    }
}
