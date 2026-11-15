import QtQuick
import "../comp"

Tile {
    id: raiz
    property date agora: new Date()

    Timer { interval: 1000; running: true; repeat: true; onTriggered: raiz.agora = new Date() }

    Mostrador {
        anchors.centerIn: parent
        tam: 57
        hora: raiz.agora.getHours() + raiz.agora.getMinutes() / 60 + raiz.agora.getSeconds() / 3600
        segundos: raiz.agora.getSeconds()
        claro: !Tema.escuro
    }
}
