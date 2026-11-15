import QtQuick
import "../comp"
import "../dados"

Tile {
    id: raiz
    property string tela: ""
    property int maximo: 0
    property real valor: 0
    readonly property string servico: "qdbus-qt6 org.kde.ScreenBrightness"

    largura: 283

    Comando { id: executor }
    Periodico {
        // Uma linha por tela: caminho, brilho, máximo, interna.
        comando: "for d in $(" + raiz.servico + " | grep /display); do echo \"$d $(" + raiz.servico + " $d org.kde.ScreenBrightness.Display.Brightness) $(" + raiz.servico + " $d org.kde.ScreenBrightness.Display.MaxBrightness) $(" + raiz.servico + " $d org.kde.ScreenBrightness.Display.IsInternal)\"; done"
        intervalo: 4000
        ativo: !barra.arrastando
        onAtualizado: saida => {
            const telas = saida.trim().split("\n").map(l => l.split(" ")).filter(p => p.length === 4 && parseInt(p[2]) > 0)
            const escolhida = telas.find(p => p[3] === "true") || telas[0]
            if (!escolhida) { raiz.tela = ""; return }
            raiz.tela = escolhida[0]
            raiz.maximo = parseInt(escolhida[2])
            raiz.valor = parseInt(escolhida[1]) / raiz.maximo
        }
    }

    function definir(novo) {
        if (tela === "") return
        valor = Math.max(0.02, novo)
        executor.rodar(servico + " " + tela + " org.kde.ScreenBrightness.Display.SetBrightness " + Math.round(valor * maximo) + " 0", null)
    }

    Icone {
        id: icone
        anchors { left: parent.left; leftMargin: 16; top: parent.top; topMargin: 12 }
        source: "brightness-high-symbolic"
        tam: 17
        cor: Tema.textoFraco
        rotation: raiz.valor * 180
        Behavior on rotation { NumberAnimation { duration: Tema.normal } }
    }
    Texto {
        anchors { left: icone.right; leftMargin: 9; verticalCenter: icone.verticalCenter }
        text: "Brilho"
        tam: 14
        forte: true
    }
    Texto {
        anchors { right: parent.right; rightMargin: 17; verticalCenter: icone.verticalCenter }
        text: raiz.tela === "" ? "–" : Math.round(raiz.valor * 100) + "%"
        tam: 14
        fraco: true
    }
    Deslizante {
        id: barra
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 15; rightMargin: 15; bottomMargin: 12 }
        height: 24
        valor: raiz.valor
        cor: Tema.escuro ? "#f2f2f4" : "#3a3a40"
        onEscolhido: novo => raiz.definir(novo)
    }
}
