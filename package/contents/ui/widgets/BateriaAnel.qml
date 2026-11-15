import QtQuick
import "../comp"
import "../dados"

Tile {
    id: raiz

    Bateria { id: bateria }

    Connections {
        target: bateria
        function onNaTomadaChanged() { pulso.restart() }
    }

    Item {
        id: palco
        anchors.centerIn: parent
        width: 57; height: 57

        Anel {
            id: anel
            anchors.fill: parent
            valor: bateria.porcento / 100
            cor: bateria.cor
            espessura: 6
        }

        // Cometa que percorre o arco enquanto carrega.
        Item {
            anchors.fill: parent
            visible: bateria.carregando
            rotation: 0
            NumberAnimation on rotation {
                running: bateria.carregando
                from: 0; to: 360 * anel.mostrado
                duration: 1800
                loops: Animation.Infinite
                easing.type: Easing.InOutSine
            }
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    width: 6 - index; height: width; radius: width / 2
                    color: "white"
                    opacity: 0.9 - index * 0.22
                    x: parent.width / 2 - width / 2
                    y: 3 - height / 2
                    transform: Rotation { origin.x: width / 2; origin.y: palco.height / 2 - 3 + height / 2; angle: -index * 7 }
                }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 2
            Raio {
                anchors.verticalCenter: parent.verticalCenter
                visible: bateria.naTomada
                tam: 13
                SequentialAnimation on scale {
                    running: bateria.carregando
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.25; duration: 500; easing.type: Easing.OutQuad }
                    NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutQuad }
                    PauseAnimation { duration: 900 }
                }
            }
            Texto {
                anchors.verticalCenter: parent.verticalCenter
                text: bateria.existe ? bateria.porcento : "–"
                tam: bateria.porcento === 100 ? 15 : 18
                forte: true
            }
        }

        // Respiração quando a carga está baixa.
        SequentialAnimation on opacity {
            running: bateria.baixa
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { to: 0.45; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
        }

        SequentialAnimation {
            id: pulso
            NumberAnimation { target: palco; property: "scale"; to: 1.18; duration: 160; easing.type: Easing.OutQuad }
            SpringAnimation { target: palco; property: "scale"; to: 1; spring: 4; damping: 0.25 }
        }
    }
}
