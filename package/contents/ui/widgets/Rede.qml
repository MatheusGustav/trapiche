import QtQuick
import org.kde.ksysguard.sensors as Sensores
import "../comp"
import "../util.js" as Util

Tile {
    id: raiz
    property var historico: []

    largura: 226

    Sensores.Sensor { id: baixando; sensorId: "network/all/download"; updateRateLimit: 2000 }
    Sensores.Sensor { id: enviando; sensorId: "network/all/upload"; updateRateLimit: 2000 }

    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: {
            const lista = raiz.historico.slice(-29)
            lista.push(baixando.value || 0)
            raiz.historico = lista
        }
    }

    Texto {
        anchors { left: parent.left; leftMargin: 16; top: parent.top; topMargin: 13 }
        text: "↓ " + Util.bytes(baixando.value || 0) + "/s"
        tam: 13
        forte: true
    }
    Texto {
        anchors { right: parent.right; rightMargin: 16; top: parent.top; topMargin: 13 }
        text: Util.bytes(enviando.value || 0) + "/s ↑"
        tam: 13
        forte: true
        color: Tema.roxo
    }
    Faisca {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 16; rightMargin: 16; bottomMargin: 12 }
        height: 26
        valores: raiz.historico
        cor: Tema.ciano
    }
}
