import QtQuick
import org.kde.ksysguard.sensors as Sensores
import "../comp"

Tile {
    id: raiz
    readonly property real graus: temperatura.value === undefined ? 0 : temperatura.value
    readonly property real cpu: usoCpu.value === undefined ? 0 : usoCpu.value
    readonly property real ram: usoRam.value === undefined ? 0 : usoRam.value

    largura: 226

    Sensores.Sensor { id: temperatura; sensorId: "cpu/all/averageTemperature"; updateRateLimit: 3000 }
    Sensores.Sensor { id: usoCpu; sensorId: "cpu/all/usage"; updateRateLimit: 2000 }
    Sensores.Sensor { id: usoRam; sensorId: "memory/physical/usedPercent"; updateRateLimit: 2000 }

    Anel {
        id: arco
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter; verticalCenterOffset: 3 }
        width: 54; height: 54
        inicio: 135; varredura: 270
        valor: Math.max(0, Math.min(1, (raiz.graus - 30) / 70))
        cor: raiz.graus >= 85 ? Tema.vermelho : (raiz.graus >= 70 ? Tema.laranja : Tema.verde)
        Texto {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -3
            text: raiz.graus > 0 ? Math.round(raiz.graus) + "°" : "–"
            tam: 16
            forte: true
        }
        Texto {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: -1 }
            text: "CPU"
            tam: 9
            forte: true
            fraco: true
        }
    }

    Column {
        anchors { left: arco.right; leftMargin: 16; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        spacing: 9
        Repeater {
            model: [{ nome: "CPU", valor: raiz.cpu }, { nome: "RAM", valor: raiz.ram }]
            Item {
                required property var modelData
                width: parent.width; height: 18
                Texto { id: nome; anchors.verticalCenter: parent.verticalCenter; text: modelData.nome; tam: 13; forte: true; fraco: true; width: 34 }
                Barra {
                    anchors { left: nome.right; right: numero.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    valor: modelData.valor / 100
                    cor: Tema.azul
                }
                Texto {
                    id: numero
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: 40
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(modelData.valor) + "%"
                    tam: 15
                    forte: true
                }
            }
        }
    }
}
