import QtQuick
import "../comp"
import "../util.js" as Util

Tile {
    id: raiz
    property real acumulado: 0      // ms já contados antes do último início
    property real inicio: 0         // instante do último início
    property bool rodando: false
    property real agora: Date.now()
    readonly property real total: acumulado + (rodando ? agora - inicio : 0)

    largura: 240

    function alternar() {
        if (rodando) { acumulado += Date.now() - inicio; rodando = false }
        else { inicio = Date.now(); agora = inicio; rodando = true }
    }
    function zerar() { rodando = false; acumulado = 0 }

    Timer { interval: 200; running: raiz.rodando; repeat: true; onTriggered: raiz.agora = Date.now() }

    Texto {
        anchors { left: parent.left; leftMargin: 18; top: parent.top; topMargin: 11 }
        text: "Cronômetro"
        tam: 13
        forte: true
        color: Tema.laranja
    }
    Texto {
        anchors { left: parent.left; leftMargin: 18; bottom: parent.bottom; bottomMargin: 9 }
        text: Util.cronometro(raiz.total / 1000)
        tam: 27
        forte: true
        font.features: { "tnum": 1 }
    }
    BotaoRedondo {
        anchors { right: botao.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        tam: 30
        visible: !raiz.rodando && raiz.acumulado > 0
        icone: "view-refresh-symbolic"
        onClicado: raiz.zerar()
    }
    BotaoAcao {
        id: botao
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        color: Tema.laranja
        rodando: raiz.rodando
        onClicado: raiz.alternar()
    }
}
