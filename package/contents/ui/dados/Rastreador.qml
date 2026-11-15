import QtQuick
import org.kde.plasma.plasmoid
import "../util.js" as Util

// Conta, minuto a minuto, o tempo com a sessão desbloqueada. Guarda 7 dias em "tela": { "aaaa-mm-dd": [24 valores] }.
Item {
    property real ultimo: Date.now()

    function registrar() {
        const agora = new Date()
        const chave = Qt.formatDate(agora, "yyyy-MM-dd")
        const tela = Util.ler(Plasmoid.configuration.dados, "tela", {})
        const horas = tela[chave] || new Array(24).fill(0)
        horas[agora.getHours()] = Math.min(60, (horas[agora.getHours()] || 0) + 1)
        const novo = {}
        novo[chave] = horas
        Object.keys(tela).sort().slice(-7).forEach(dia => { if (dia !== chave) novo[dia] = tela[dia] })
        Plasmoid.configuration.dados = Util.gravar(Plasmoid.configuration.dados, "tela", novo)
    }

    Comando { id: executor }
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            const agora = Date.now()
            const lacuna = agora - parent.ultimo
            parent.ultimo = agora
            if (lacuna > 150000) return     // o computador estava suspenso
            executor.rodar("qdbus-qt6 org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver.GetActive", saida => {
                if (saida.trim() !== "true") parent.registrar()
            })
        }
    }
}
