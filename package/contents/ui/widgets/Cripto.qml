import QtQuick
import org.kde.plasma.plasmoid
import "../comp"
import "../dados"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "cripto")
    readonly property string par: op.par.trim().toUpperCase()
    readonly property real mudanca: cotacao.dados ? parseFloat(cotacao.dados.priceChangePercent) : 0
    readonly property color cor: mudanca >= 0 ? Tema.verde : Tema.vermelho

    largura: 275

    Http {
        id: cotacao
        url: raiz.par === "" ? "" : "https://api.binance.com/api/v3/ticker/24hr?symbol=" + encodeURIComponent(raiz.par)
        intervalo: 60000
    }
    Http {
        id: velas
        url: raiz.par === "" ? "" : "https://api.binance.com/api/v3/klines?interval=1h&limit=24&symbol=" + encodeURIComponent(raiz.par)
        intervalo: 600000
    }

    Texto {
        anchors.centerIn: parent
        visible: !cotacao.dados
        text: cotacao.erro !== "" ? "Par não encontrado ou sem conexão" : "Carregando"
        tam: 12; fraco: true
    }
    Texto {
        visible: cotacao.dados !== null
        anchors { left: parent.left; leftMargin: 16; top: parent.top; topMargin: 10 }
        text: raiz.par
        tam: 14
        forte: true
    }
    Column {
        visible: cotacao.dados !== null
        anchors { right: parent.right; rightMargin: 16; top: parent.top; topMargin: 8 }
        Texto { anchors.right: parent.right; text: cotacao.dados ? Util.numero(parseFloat(cotacao.dados.lastPrice), 2) : ""; tam: 15; forte: true }
        Texto { anchors.right: parent.right; text: Util.variacao(raiz.mudanca); tam: 11; color: raiz.cor }
    }
    Faisca {
        visible: cotacao.dados !== null
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 16; rightMargin: 100; bottomMargin: 9 }
        height: 28
        valores: Array.isArray(velas.dados) ? velas.dados.map(v => parseFloat(v[4])) : []
        cor: raiz.cor
    }
}
