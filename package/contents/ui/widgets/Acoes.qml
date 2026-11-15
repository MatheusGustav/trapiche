import QtQuick
import org.kde.plasma.plasmoid
import "../comp"
import "../dados"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "acoes")
    readonly property var simbolos: op.simbolos.split(",").map(t => t.trim().toUpperCase()).filter(t => t !== "").slice(0, 3)

    largura: 300

    Column {
        anchors { left: parent.left; right: parent.right; leftMargin: 17; rightMargin: 17; verticalCenter: parent.verticalCenter }
        spacing: 3
        Repeater {
            model: raiz.simbolos
            Item {
                id: linha
                required property string modelData
                readonly property var meta: cotacao.dados && cotacao.dados.chart && cotacao.dados.chart.result ? cotacao.dados.chart.result[0].meta : null
                readonly property real mudanca: meta && meta.chartPreviousClose ? (meta.regularMarketPrice / meta.chartPreviousClose - 1) * 100 : NaN
                width: parent.width; height: 18

                Http {
                    id: cotacao
                    url: "https://query1.finance.yahoo.com/v8/finance/chart/" + encodeURIComponent(linha.modelData) + "?interval=1d&range=1d"
                    cabecalhos: ({ "User-Agent": "Mozilla/5.0" })
                    intervalo: 300000
                }
                Texto { anchors.verticalCenter: parent.verticalCenter; text: linha.modelData.replace(/\..*$/, ""); tam: 13; forte: true; width: 78 }
                Texto {
                    x: 82
                    anchors.verticalCenter: parent.verticalCenter
                    text: linha.meta ? Util.numero(linha.meta.regularMarketPrice, 2) : (cotacao.erro !== "" ? "indisponível" : "…")
                    tam: 13
                    fraco: !linha.meta
                }
                Texto {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: isNaN(linha.mudanca) ? "" : (linha.mudanca >= 0 ? "+" : "−") + Math.abs(linha.mudanca).toFixed(2).replace(".", ",") + "%"
                    tam: 13
                    color: linha.mudanca >= 0 ? Tema.verde : Tema.vermelho
                }
            }
        }
    }
}
