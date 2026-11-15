import QtQuick
import "../comp"
import "../dados"

Tile {
    id: raiz
    property bool microfoneMudo: false
    property bool saidaMuda: false

    largura: 134

    Comando { id: executor }
    Periodico {
        id: leitura
        comando: "wpctl get-volume @DEFAULT_AUDIO_SOURCE@; wpctl get-volume @DEFAULT_AUDIO_SINK@"
        intervalo: 3000
        onAtualizado: saida => {
            const linhas = saida.trim().split("\n")
            raiz.microfoneMudo = (linhas[0] || "").indexOf("MUTED") >= 0
            raiz.saidaMuda = (linhas[1] || "").indexOf("MUTED") >= 0
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 10
        BotaoRedondo {
            tam: 52
            tamIcone: 22
            icone: raiz.microfoneMudo ? "microphone-sensitivity-muted-symbolic" : "microphone-sensitivity-high-symbolic"
            corIcone: raiz.microfoneMudo ? "white" : Tema.texto
            color: raiz.microfoneMudo ? Tema.vermelho : Tema.botao
            onClicado: executor.rodar("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", () => leitura.agora())
        }
        BotaoRedondo {
            tam: 52
            tamIcone: 22
            icone: raiz.saidaMuda ? "audio-volume-muted-symbolic" : "audio-headphones-symbolic"
            corIcone: raiz.saidaMuda ? "white" : Tema.texto
            color: raiz.saidaMuda ? Tema.vermelho : Tema.botao
            onClicado: executor.rodar("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", () => leitura.agora())
        }
    }
}
