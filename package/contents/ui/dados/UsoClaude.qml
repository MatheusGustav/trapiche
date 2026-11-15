import QtQuick
import "../util.js" as Util

// Uso do Claude Code, lido por um script do pacote: limites do plano e modelo mais usado.
Item {
    id: uso
    property var dados: null                // { sessao: { pct, renova }, semana: { pct, renova }, modelo, modeloTokens }
    property real agora: Date.now() / 1000  // segundos
    readonly property bool pronto: dados !== null

    function porcento(janela) { return janela ? Math.round(janela.pct) + "%" : "–" }
    function fracao(janela) { return janela ? janela.pct / 100 : 0 }
    // Tempo que falta para a janela renovar, ex.: "1h 25m".
    function falta(janela) { return janela && janela.renova ? Util.duracao(janela.renova - agora) : "" }
    // Dia em que a janela renova, ex.: "17 ter".
    function dia(janela) {
        if (!janela || !janela.renova) return ""
        return new Date(janela.renova * 1000).toLocaleDateString(Qt.locale("pt_BR"), "d ddd").replace(".", "")
    }

    Periodico {
        comando: "python3 " + Util.script(Qt.resolvedUrl("."), "uso-claude.py")
        intervalo: 60000
        onAtualizado: saida => {
            uso.agora = Date.now() / 1000
            try { uso.dados = JSON.parse(saida) } catch (e) { uso.dados = null }
        }
    }
}
