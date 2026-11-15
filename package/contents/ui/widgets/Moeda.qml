import QtQuick
import org.kde.plasma.plasmoid
import "../comp"
import "../dados"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "moeda")
    property bool invertido: false
    readonly property string de: (invertido ? op.para : op.de).trim().toUpperCase()
    readonly property string para: (invertido ? op.de : op.para).trim().toUpperCase()
    readonly property real taxa: cambio.dados && cambio.dados.rates && cambio.dados.rates[para] ? cambio.dados.rates[para] : NaN

    largura: 250

    Http {
        id: cambio
        url: raiz.de === "" ? "" : "https://open.er-api.com/v6/latest/" + encodeURIComponent(raiz.de)
        intervalo: 3600000
    }

    Column {
        anchors { left: parent.left; leftMargin: 17; right: moedas.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 1
        Texto { text: Util.numero(raiz.op.valor, raiz.op.valor % 1 === 0 ? 0 : 2); tam: 15; forte: true; fraco: true }
        Texto {
            width: parent.width
            text: isNaN(raiz.taxa) ? (cambio.erro !== "" ? "sem conexão" : "…") : Util.numero(raiz.op.valor * raiz.taxa, 2)
            tam: 22
            forte: true
        }
    }
    Column {
        id: moedas
        anchors { right: parent.right; rightMargin: 13; verticalCenter: parent.verticalCenter }
        spacing: 2
        Rectangle {
            width: 58; height: 19; radius: 9.5; color: Tema.botao
            Texto { anchors.centerIn: parent; text: raiz.de; tam: 12; forte: true }
        }
        Icone {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "exchange-positions"
            tam: 15
            cor: Tema.textoFraco
            rotation: raiz.invertido ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: Tema.normal; easing.type: Easing.OutBack } }
            MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: raiz.invertido = !raiz.invertido }
        }
        Rectangle {
            width: 58; height: 19; radius: 9.5; color: Tema.botao
            Texto { anchors.centerIn: parent; text: raiz.para; tam: 12; forte: true }
        }
    }
}
