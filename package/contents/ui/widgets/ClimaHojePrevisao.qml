import QtQuick
import org.kde.kirigami as Kirigami
import "../comp"
import "../dados" as Dados
import "../util.js" as Util

Tile {
    id: raiz
    largura: 306

    Dados.Clima { id: clima }

    Texto { anchors.centerIn: parent; visible: !clima.pronto; text: clima.aviso; tam: 12; fraco: true }

    Row {
        visible: clima.pronto
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        spacing: 9
        Kirigami.Icon {
            anchors.verticalCenter: parent.verticalCenter
            width: 38; height: 38
            source: clima.pronto ? Util.climaIcone(clima.dados.current.weather_code, clima.dados.current.is_day === 1) : ""
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Texto { text: clima.pronto ? Math.round(clima.dados.current.temperature_2m) + "°" : ""; tam: 22; forte: true }
            Texto { text: "Hoje"; tam: 12; fraco: true }
        }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 44; color: Tema.trilho }
        Repeater {
            model: clima.pronto ? [1, 2, 3] : []
            Column {
                required property int modelData
                width: 56
                spacing: 1
                Texto {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: new Date(clima.dados.daily.time[modelData] + "T12:00").toLocaleDateString(Qt.locale("pt_BR"), "ddd").replace(".", "")
                    tam: 11; fraco: true
                    font.capitalization: Font.Capitalize
                }
                Kirigami.Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 24; height: 24
                    source: Util.climaIcone(clima.dados.daily.weather_code[modelData], true)
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    Texto { text: Math.round(clima.dados.daily.temperature_2m_max[modelData]) + "°"; tam: 12; forte: true }
                    Texto { text: Math.round(clima.dados.daily.temperature_2m_min[modelData]) + "°"; tam: 12; fraco: true }
                }
            }
        }
    }
}
