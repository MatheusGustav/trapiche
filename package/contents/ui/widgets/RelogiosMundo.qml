import QtQuick
import org.kde.plasma.plasmoid
import "../comp"
import "../dados"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "relogios-mundo")
    // "SIGLA:Fuso/Horario" separados por vírgula
    readonly property var cidades: op.cidades.split(",").map(t => t.trim().split(":")).filter(p => p.length === 2 && p[1] !== "")
    property var deslocamentos: []      // minutos em relação ao UTC, na ordem das cidades
    property real agora: Date.now()

    largura: 20 + Math.max(1, cidades.length) * 58

    Timer { interval: 15000; running: true; repeat: true; onTriggered: raiz.agora = Date.now() }
    Periodico {
        comando: raiz.cidades.map(c => "TZ=" + Util.aspas(c[1]) + " date +%z").join("; ")
        intervalo: 900000
        onAtualizado: saida => {
            raiz.deslocamentos = saida.trim().split("\n").map(z => {
                const sinal = z[0] === "-" ? -1 : 1
                return sinal * (parseInt(z.substr(1, 2)) * 60 + parseInt(z.substr(3, 2)))
            })
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 12
        Repeater {
            model: raiz.cidades
            Column {
                id: cidade
                required property var modelData
                required property int index
                readonly property real hora: {
                    const minutos = raiz.deslocamentos[index]
                    if (minutos === undefined || isNaN(minutos)) return 0
                    const local = new Date(raiz.agora + minutos * 60000)
                    return local.getUTCHours() + local.getUTCMinutes() / 60
                }
                spacing: 3
                Mostrador {
                    anchors.horizontalCenter: parent.horizontalCenter
                    tam: 40
                    hora: cidade.hora
                    claro: cidade.hora >= 6 && cidade.hora < 18
                    Behavior on hora { NumberAnimation { duration: Tema.lento; easing.type: Easing.OutCubic } }
                }
                Texto {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cidade.modelData[0]
                    tam: 10
                    forte: true
                    fraco: true
                }
            }
        }
    }
}
