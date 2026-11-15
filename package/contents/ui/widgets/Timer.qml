import QtQuick
import org.kde.plasma.plasmoid
import "../comp"
import "../dados"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "timer")
    property int duracao: Math.max(1, op.minutos) * 60
    property real fim: 0
    property bool rodando: false
    property int restante: duracao

    largura: 222
    rolavel: !rodando
    corBorda: rodando ? Tema.azul : Tema.borda
    espessuraBorda: rodando ? 2 : 1
    onRolado: passo => { duracao = Math.max(60, duracao + passo * 60); restante = duracao }
    onDuracaoChanged: if (!rodando) restante = duracao

    function alternar() {
        if (rodando) { rodando = false; return }
        if (restante <= 0) restante = duracao
        fim = Date.now() + restante * 1000
        rodando = true
    }

    Aviso { id: aviso }
    Timer {
        interval: 250; running: raiz.rodando; repeat: true
        onTriggered: {
            raiz.restante = Math.max(0, Math.ceil((raiz.fim - Date.now()) / 1000))
            if (raiz.restante === 0) {
                raiz.rodando = false
                raiz.restante = raiz.duracao
                aviso.mostrar("Timer", "O tempo acabou.")
                alerta.restart()
            }
        }
    }
    SequentialAnimation {
        id: alerta
        loops: 3
        NumberAnimation { target: raiz; property: "opacity"; to: 0.3; duration: 220 }
        NumberAnimation { target: raiz; property: "opacity"; to: 1; duration: 220 }
    }

    Texto {
        anchors { left: parent.left; leftMargin: 18; top: parent.top; topMargin: 11 }
        text: "Timer"
        tam: 13
        forte: true
        color: Tema.azul
    }
    Texto {
        anchors { left: parent.left; leftMargin: 18; bottom: parent.bottom; bottomMargin: 9 }
        text: Util.cronometro(raiz.restante)
        tam: 27
        forte: true
        font.features: { "tnum": 1 }
    }
    BotaoAcao {
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        rodando: raiz.rodando
        onClicado: raiz.alternar()
    }
}
