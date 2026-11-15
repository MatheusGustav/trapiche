import QtQuick
import "../comp"
import "../dados"

Tile {
    id: raiz

    Bateria { id: bateria }

    Item {
        id: mostrador
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 11 }
        width: 58; height: 34

        Repeater {
            model: 9
            Item {
                required property int index
                x: mostrador.width / 2; y: mostrador.height - 3
                rotation: -90 + index * 180 / 8
                Rectangle {
                    x: -1; y: -29
                    width: index % 4 === 0 ? 2.4 : 1.6
                    height: index % 4 === 0 ? 7 : 4
                    radius: 1
                    color: index === 0 ? Tema.vermelho : Tema.textoFraco
                }
            }
        }
        Texto { x: 9; y: 20; text: "V"; tam: 8; forte: true; fraco: true }
        Texto { x: mostrador.width - 14; y: 20; text: "C"; tam: 8; forte: true; fraco: true }

        Item {
            id: ponteiro
            x: mostrador.width / 2; y: mostrador.height - 3
            rotation: -90 + (bateria.existe ? bateria.porcento : 0) * 1.8
            Behavior on rotation { SpringAnimation { spring: 2.2; damping: 0.18; mass: 0.8 } }
            Rectangle { x: -1; y: -22; width: 2; height: 22; radius: 1; color: Tema.laranja }
        }
        Rectangle {
            x: mostrador.width / 2 - 4; y: mostrador.height - 7
            width: 8; height: 8; radius: 4
            color: Tema.tile
            border.color: Tema.textoFraco
            border.width: 1.5
        }
    }

    Row {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
        spacing: 6
        Texto {
            text: bateria.existe ? bateria.porcento : "–"
            tam: 15
            forte: true
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 6; height: 6; radius: 3
            color: bateria.cor
            visible: bateria.existe
            SequentialAnimation on opacity {
                running: bateria.carregando
                loops: Animation.Infinite
                alwaysRunToEnd: true
                NumberAnimation { to: 0.2; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }
    }
}
