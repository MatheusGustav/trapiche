import QtQuick
import org.kde.ksysguard.sensors as Sensores
import "../comp"

Tile {
    id: raiz
    readonly property real uso: sensor.value === undefined ? 0 : sensor.value

    Sensores.Sensor { id: sensor; sensorId: "memory/physical/usedPercent"; updateRateLimit: 2000 }

    Anel {
        anchors.centerIn: parent
        width: 55; height: 55
        valor: raiz.uso / 100
        cor: raiz.uso > 90 ? Tema.vermelho : Tema.azul
    }
    Texto {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 23 }
        text: "RAM"
        tam: 9
        forte: true
        fraco: true
    }
    Texto {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 33 }
        text: Math.round(raiz.uso)
        tam: 17
        forte: true
    }
}
