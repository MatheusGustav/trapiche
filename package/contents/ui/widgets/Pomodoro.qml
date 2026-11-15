import QtQuick
import org.kde.plasma.plasmoid
import "../comp"
import "../dados"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "pomodoro")
    property bool foco: true
    property int rodada: 1
    property real fim: 0
    property bool rodando: false
    property int restante: minutosDaFase() * 60
    readonly property color corFase: foco ? Tema.vermelho : Tema.verde

    largura: 238
    corBorda: rodando ? corFase : Tema.borda
    espessuraBorda: rodando ? 2 : 1

    function minutosDaFase() {
        if (foco) return Math.max(1, op.foco)
        return Math.max(1, rodada % 4 === 0 ? op.pausaLonga : op.pausa)
    }
    function alternar() {
        if (rodando) { rodando = false; return }
        fim = Date.now() + restante * 1000
        rodando = true
    }
    function avancar(concluiu) {
        if (foco && concluiu) {
            const hoje = Qt.formatDate(new Date(), "yyyy-MM-dd")
            const rodadas = Util.ler(Plasmoid.configuration.dados, "rodadas", {})
            const novo = {}
            novo[hoje] = (rodadas[hoje] || 0) + 1
            Plasmoid.configuration.dados = Util.gravar(Plasmoid.configuration.dados, "rodadas", novo)
        }
        if (!foco) rodada = rodada % 4 + 1
        foco = !foco
        rodando = false
        restante = minutosDaFase() * 60
    }

    Aviso { id: aviso }
    Timer {
        interval: 250; running: raiz.rodando; repeat: true
        onTriggered: {
            raiz.restante = Math.max(0, Math.ceil((raiz.fim - Date.now()) / 1000))
            if (raiz.restante === 0) {
                aviso.mostrar("Pomodoro", raiz.foco ? "Foco concluído. Hora da pausa." : "Pausa encerrada. De volta ao foco.")
                raiz.avancar(true)
            }
        }
    }

    Row {
        anchors { left: parent.left; leftMargin: 18; top: parent.top; topMargin: 11 }
        spacing: 7
        Texto { text: raiz.foco ? "Foco" : "Pausa"; tam: 13; forte: true; color: raiz.corFase }
        Texto { text: raiz.rodada + "/4"; tam: 13; fraco: true }
    }
    Texto {
        anchors { left: parent.left; leftMargin: 18; bottom: parent.bottom; bottomMargin: 9 }
        text: Util.cronometro(raiz.restante)
        tam: 27
        forte: true
        font.features: { "tnum": 1 }
    }
    BotaoRedondo {
        anchors { right: botao.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        tam: 30
        icone: "media-skip-forward-symbolic"
        onClicado: raiz.avancar(false)
    }
    BotaoAcao {
        id: botao
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        color: raiz.corFase
        rodando: raiz.rodando
        onClicado: raiz.alternar()
    }
}
