import QtQuick
import org.kde.kirigami as Kirigami
import "../comp"
import "../dados" as Dados
import "../util.js" as Util

Tile {
    id: raiz
    largura: 316

    Dados.Clima { id: clima }

    Texto { anchors.centerIn: parent; visible: !clima.pronto; text: clima.aviso; tam: 12; fraco: true }

    Row {
        visible: clima.pronto
        anchors.centerIn: parent
        Repeater {
            model: clima.pronto ? Math.min(6, clima.dados.hourly.time.length) : 0
            Rectangle {
                required property int index
                width: 50; height: 63; radius: 14
                color: index === 0 ? Tema.botao : "transparent"
                Texto {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 4 }
                    text: index === 0 ? "Agora" : clima.dados.hourly.time[index].substr(11, 2) + "h"
                    tam: 11
                    forte: index === 0
                    fraco: index !== 0
                }
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 22; height: 22
                    source: Util.climaIcone(clima.dados.hourly.weather_code[index], clima.dados.hourly.is_day[index] === 1)
                }
                Texto {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 3 }
                    text: Math.round(clima.dados.hourly.temperature_2m[index]) + "°"
                    tam: 13
                    forte: true
                }
            }
        }
    }
}
