import QtQuick
import "../comp"
import "../dados"

Tile {
    id: raiz
    property real volume: 0
    property bool mudo: false
    property string nome: ""

    largura: 283

    Comando { id: executor }
    Periodico {
        id: leitura
        comando: "wpctl get-volume @DEFAULT_AUDIO_SINK@; wpctl inspect @DEFAULT_AUDIO_SINK@ | sed -n 's/.*node.description = \"\\(.*\\)\"/\\1/p'"
        intervalo: 2500
        ativo: !barra.arrastando
        onAtualizado: saida => {
            const linhas = saida.trim().split("\n")
            const achado = /Volume: ([0-9.]+)/.exec(linhas[0] || "")
            if (!achado) return
            raiz.volume = parseFloat(achado[1])
            raiz.mudo = linhas[0].indexOf("MUTED") >= 0
            raiz.nome = linhas[1] || "Saída de áudio"
        }
    }

    function definir(novo) {
        volume = novo
        executor.rodar("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ " + novo.toFixed(2), null)
    }

    BotaoRedondo {
        id: botao
        anchors { left: parent.left; leftMargin: 13; top: parent.top; topMargin: 8 }
        tam: 25
        icone: raiz.mudo ? "audio-volume-muted-symbolic" : (raiz.volume < 0.5 ? "audio-volume-medium-symbolic" : "audio-volume-high-symbolic")
        corIcone: raiz.mudo ? Tema.vermelho : Tema.textoFraco
        onClicado: executor.rodar("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", () => leitura.agora())
    }
    Texto {
        anchors { left: botao.right; leftMargin: 8; right: porcento.left; rightMargin: 8; verticalCenter: botao.verticalCenter }
        text: raiz.nome
        tam: 14
        forte: true
    }
    Texto {
        id: porcento
        anchors { right: parent.right; rightMargin: 17; verticalCenter: botao.verticalCenter }
        text: raiz.mudo ? "mudo" : Math.round(raiz.volume * 100) + "%"
        tam: 14
        fraco: true
    }
    Deslizante {
        id: barra
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 15; rightMargin: 15; bottomMargin: 12 }
        height: 24
        valor: raiz.mudo ? 0 : raiz.volume
        onEscolhido: novo => raiz.definir(novo)
    }
}
