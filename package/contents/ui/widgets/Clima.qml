import QtQuick
import org.kde.kirigami as Kirigami
import "../comp"
import "../dados" as Dados
import "../util.js" as Util

Tile {
    id: raiz
    largura: 150

    Dados.Clima { id: clima }

    Texto { anchors.centerIn: parent; visible: !clima.pronto; text: clima.aviso; tam: 12; fraco: true }

    Kirigami.Icon {
        id: icone
        visible: clima.pronto
        anchors { left: parent.left; leftMargin: 13; verticalCenter: parent.verticalCenter }
        width: 42; height: 42
        source: clima.pronto ? Util.climaIcone(clima.dados.current.weather_code, clima.dados.current.is_day === 1) : ""
    }
    Column {
        visible: clima.pronto
        anchors { left: icone.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
        Texto { text: clima.pronto ? Math.round(clima.dados.current.temperature_2m) + "°" : ""; tam: 24; forte: true }
        Texto {
            text: clima.pronto ? "↑" + Math.round(clima.dados.daily.temperature_2m_max[0]) + "° ↓" + Math.round(clima.dados.daily.temperature_2m_min[0]) + "°" : ""
            tam: 11
            fraco: true
        }
    }
}
