import QtQuick
import org.kde.ksysguard.sensors as Sensores
import "../comp"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property real usado: ocupado.value === undefined ? 0 : ocupado.value

    largura: 180

    Sensores.Sensor { id: livre; sensorId: "disk/all/free"; updateRateLimit: 30000 }
    Sensores.Sensor { id: ocupado; sensorId: "disk/all/usedPercent"; updateRateLimit: 30000 }

    Row {
        anchors { left: parent.left; leftMargin: 17; top: parent.top; topMargin: 15 }
        spacing: 6
        Texto { text: Util.bytes(livre.value); tam: 21; forte: true }
        Texto { anchors.baseline: parent.children[0].baseline; text: "livres"; tam: 14; fraco: true }
    }
    Barra {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 17; rightMargin: 17; bottomMargin: 17 }
        height: 6
        valor: raiz.usado / 100
        cor: raiz.usado > 90 ? Tema.vermelho : (raiz.usado > 75 ? Tema.laranja : Tema.azul)
    }
}
