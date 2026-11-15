import QtQuick
import "../comp"
import "../dados"
import "../util.js" as Util

// Bloco com os tokens das últimas 5 horas.
Tile {
    id: raiz
    property string roteiro
    property string sigla
    property color corMarca

    largura: 212

    UsoIA { id: uso; roteiro: raiz.roteiro }

    Marca {
        id: marca
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        sigla: raiz.sigla
        color: raiz.corMarca
    }
    Item {
        anchors { left: marca.right; leftMargin: 12; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        height: 46
        Texto { text: "Sessão"; tam: 13; forte: true }
        Texto { anchors.right: parent.right; text: "5 horas"; tam: 12; fraco: true }
        Texto {
            anchors.bottom: parent.bottom
            text: uso.pronto ? Util.compacto(uso.dados.h5) : "–"
            tam: 20
            forte: true
        }
    }
}
