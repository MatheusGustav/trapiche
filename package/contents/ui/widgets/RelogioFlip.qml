import QtQuick
import org.kde.plasma.plasmoid
import "../comp"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "relogio-flip")
    property date agora: new Date()
    readonly property int hora: op.h24 ? agora.getHours() : (agora.getHours() % 12 || 12)
    readonly property string digitos: Util.dois(hora) + Util.dois(agora.getMinutes())

    largura: op.h24 ? 164 : 190

    Timer { interval: 1000; running: true; repeat: true; onTriggered: raiz.agora = new Date() }

    component Ficha: Item {
        id: ficha
        property string valor
        property string mostrado: valor
        width: 30; height: 47

        onValorChanged: if (valor !== mostrado) virada.restart()

        Rectangle {
            id: cartao
            anchors.fill: parent
            radius: 8
            color: Tema.escuro ? "#101012" : "#ececf0"
            border.color: Tema.borda
            transform: Rotation { id: giro; origin.x: cartao.width / 2; origin.y: cartao.height / 2; axis { x: 1; y: 0; z: 0 } }

            Texto {
                anchors.centerIn: parent
                text: ficha.mostrado
                tam: 31
                forte: true
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 1
                color: Tema.escuro ? "#66000000" : "#22000000"
            }
        }
        SequentialAnimation {
            id: virada
            NumberAnimation { target: giro; property: "angle"; from: 0; to: 90; duration: 170; easing.type: Easing.InQuad }
            ScriptAction { script: ficha.mostrado = ficha.valor }
            NumberAnimation { target: giro; property: "angle"; from: -90; to: 0; duration: 260; easing.type: Easing.OutBack }
        }
    }

    Row {
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 14 }
        spacing: 4
        Ficha { valor: raiz.digitos[0] }
        Ficha { valor: raiz.digitos[1] }
        Item { width: 4; height: 1 }
        Ficha { valor: raiz.digitos[2] }
        Ficha { valor: raiz.digitos[3] }
        Texto {
            visible: !raiz.op.h24
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            leftPadding: 4
            text: raiz.agora.getHours() < 12 ? "AM" : "PM"
            tam: 11
            forte: true
            fraco: true
        }
    }
}
