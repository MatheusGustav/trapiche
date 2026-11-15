import QtQuick
import org.kde.plasma.plasmoid
import "../comp"
import "../util.js" as Util

Tile {
    id: raiz
    property date agora: new Date()
    readonly property string chave: Qt.formatDate(agora, "yyyy-MM-dd")
    readonly property var horas: Util.ler(Plasmoid.configuration.dados, "tela", {})[chave] || []
    readonly property int minutos: horas.reduce((soma, v) => soma + (v || 0), 0)
    readonly property int rodadas: Util.ler(Plasmoid.configuration.dados, "rodadas", {})[chave] || 0

    largura: 400

    Timer { interval: 60000; running: true; repeat: true; onTriggered: raiz.agora = new Date() }

    Texto {
        anchors { left: parent.left; leftMargin: 18; top: parent.top; topMargin: 10 }
        text: raiz.agora.toLocaleDateString(Qt.locale("pt_BR"), "ddd d MMM").replace(/\./g, "")
        tam: 13
        forte: true
        font.capitalization: Font.Capitalize
    }
    Row {
        anchors { right: parent.right; rightMargin: 18; top: parent.top; topMargin: 10 }
        spacing: 5
        Texto { text: Util.duracao(raiz.minutos * 60) + " no PC"; tam: 12; fraco: true }
        Texto { visible: raiz.rodadas > 0; text: "· " + raiz.rodadas + (raiz.rodadas === 1 ? " rodada" : " rodadas"); tam: 12; color: Tema.vermelho }
    }
    BarrasHoras {
        id: barras
        anchors { left: parent.left; leftMargin: 18; bottom: parent.bottom; bottomMargin: 11 }
        larguraBarra: 13.2
        spacing: 2
        alturaMaxima: 30
        valores: raiz.horas
        horaAtual: raiz.agora.getHours()
    }
    Rectangle {
        x: barras.x + (raiz.agora.getHours() + raiz.agora.getMinutes() / 60) * 15.2 - 1
        anchors { bottom: parent.bottom; bottomMargin: 8 }
        width: 2; height: 36; radius: 1
        color: Tema.laranja
    }
}
