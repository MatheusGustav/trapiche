import QtQuick
import org.kde.plasma.plasmoid
import "../comp"
import "../util.js" as Util

Tile {
    id: raiz
    property date agora: new Date()
    readonly property var horas: Util.ler(Plasmoid.configuration.dados, "tela", {})[Qt.formatDate(agora, "yyyy-MM-dd")] || []
    readonly property int minutos: horas.reduce((soma, v) => soma + (v || 0), 0)

    largura: 300

    Timer { interval: 60000; running: true; repeat: true; onTriggered: raiz.agora = new Date() }

    Rectangle {
        id: bloco
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        width: 36; height: 44; radius: 11
        color: Tema.azul
        Mostrador {
            anchors.centerIn: parent
            tam: 26
            claro: true
            hora: raiz.agora.getHours() + raiz.agora.getMinutes() / 60
        }
    }
    Column {
        anchors { left: bloco.right; leftMargin: 13; verticalCenter: parent.verticalCenter }
        Texto { text: "Tempo de tela"; tam: 12; forte: true; fraco: true }
        Texto { text: Util.duracao(raiz.minutos * 60); tam: 23; forte: true }
    }
    BarrasHoras {
        anchors { right: parent.right; rightMargin: 14; bottom: parent.bottom; bottomMargin: 15 }
        larguraBarra: 3
        spacing: 1.5
        alturaMaxima: 26
        valores: raiz.horas
        horaAtual: raiz.agora.getHours()
    }
}
