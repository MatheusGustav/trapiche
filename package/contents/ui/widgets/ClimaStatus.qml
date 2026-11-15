import QtQuick
import org.kde.kirigami as Kirigami
import "../comp"
import "../dados" as Dados
import "../util.js" as Util

Tile {
    id: raiz
    readonly property int codigo: clima.pronto ? clima.dados.current.weather_code : 0
    readonly property bool dia: !clima.pronto || clima.dados.current.is_day === 1
    readonly property bool fechado: codigo >= 3
    largura: 270

    Dados.Clima { id: clima }

    Rectangle {
        anchors.fill: parent
        radius: 24
        visible: clima.pronto
        gradient: Gradient {
            GradientStop { position: 0; color: raiz.fechado ? "#7d8aa0" : (raiz.dia ? "#58a6f0" : "#2b2f6b") }
            GradientStop { position: 1; color: raiz.fechado ? "#4c566a" : (raiz.dia ? "#2f6fd6" : "#121433") }
        }
    }
    Texto { anchors.centerIn: parent; visible: !clima.pronto; text: clima.aviso; tam: 12; fraco: true }

    Column {
        visible: clima.pronto
        anchors { left: parent.left; leftMargin: 17; right: temperatura.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
        spacing: 2
        Texto { width: parent.width; text: Util.climaDescricao(raiz.codigo); tam: 15; forte: true; color: "white" }
        Texto { width: parent.width; text: clima.local ? clima.local.nome : ""; tam: 13; color: "#d8ffffff" }
    }
    Texto {
        id: temperatura
        visible: clima.pronto
        anchors { right: icone.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
        text: clima.pronto ? Math.round(clima.dados.current.temperature_2m) + "°" : ""
        tam: 36
        font.weight: Font.Light
        color: "white"
    }
    Kirigami.Icon {
        id: icone
        visible: clima.pronto
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        width: 46; height: 46
        source: Util.climaIcone(raiz.codigo, raiz.dia)
        SequentialAnimation on anchors.verticalCenterOffset {
            running: clima.pronto
            loops: Animation.Infinite
            NumberAnimation { to: -3; duration: 2200; easing.type: Easing.InOutSine }
            NumberAnimation { to: 3; duration: 2200; easing.type: Easing.InOutSine }
        }
    }
}
