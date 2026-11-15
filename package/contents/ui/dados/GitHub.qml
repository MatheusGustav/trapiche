import QtQuick
import "../util.js" as Util

// Dados do GitHub do usuário logado no gh.
Item {
    id: github
    property var perfil: null               // { login, estrelas, dias: [contribuições por dia, o mais recente no fim] }
    property int naoLidas: 0
    property int prs: 0
    readonly property bool pronto: perfil !== null
    readonly property string aviso: pronto ? "" : (tentou ? "Entre com: gh auth login" : "Carregando")
    property bool tentou: false

    readonly property var dias: pronto ? perfil.dias : []
    readonly property int hoje: dias.length > 0 ? dias[dias.length - 1] : 0
    readonly property int semana: dias.slice(-7).reduce((soma, n) => soma + n, 0)
    readonly property int sequencia: {
        // O dia de hoje ainda pode estar zerado sem quebrar a sequência.
        let i = dias.length - 1
        if (i >= 0 && dias[i] === 0) i--
        let total = 0
        while (i >= 0 && dias[i] > 0) { total++; i-- }
        return total
    }

    Periodico {
        comando: "sh " + Util.script(Qt.resolvedUrl("."), "github.sh")
        intervalo: 300000
        onAtualizado: saida => {
            github.tentou = true
            const linhas = saida.trim().split("\n")
            if (linhas.length < 3) { github.perfil = null; return }
            try { github.perfil = JSON.parse(linhas[0]) } catch (e) { github.perfil = null; return }
            github.naoLidas = parseInt(linhas[1]) || 0
            github.prs = parseInt(linhas[2]) || 0
        }
    }
}
