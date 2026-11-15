import QtQuick

// Mostrador de relógio analógico. "hora" é a hora do dia em decimal (ex.: 14.5 = 14h30).
Item {
    id: mostrador
    property real hora: 0
    property real segundos: -1
    property bool claro: false
    property real tam: 55
    readonly property color tinta: claro ? "#1c1c1e" : "#f5f5f7"

    width: tam; height: tam

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: mostrador.claro ? "#f1f1f4" : "#0f0f12"
        border.color: Tema.borda
    }
    Repeater {
        model: 12
        Item {
            required property int index
            x: mostrador.tam / 2; y: mostrador.tam / 2
            rotation: index * 30
            Rectangle {
                x: -0.75; y: -mostrador.tam / 2 + 3
                width: 1.5; height: index % 3 === 0 ? mostrador.tam * 0.11 : mostrador.tam * 0.06
                radius: 0.75
                color: mostrador.tinta
                opacity: index % 3 === 0 ? 0.9 : 0.4
            }
        }
    }
    Rectangle {
        x: mostrador.tam / 2 - 1.25; y: mostrador.tam / 2 - height + 1
        width: 2.5; height: mostrador.tam * 0.26; radius: 1.25
        color: mostrador.tinta
        transformOrigin: Item.Bottom
        rotation: (mostrador.hora % 12) * 30
    }
    Rectangle {
        x: mostrador.tam / 2 - 1; y: mostrador.tam / 2 - height + 1
        width: 2; height: mostrador.tam * 0.37; radius: 1
        color: mostrador.tinta
        transformOrigin: Item.Bottom
        rotation: (mostrador.hora % 1) * 360
    }
    Rectangle {
        visible: mostrador.segundos >= 0
        x: mostrador.tam / 2 - 0.5; y: mostrador.tam / 2 - height + 4
        width: 1; height: mostrador.tam * 0.42
        color: Tema.laranja
        transformOrigin: Item.Bottom
        transform: Rotation { origin.x: 0.5; origin.y: mostrador.tam * 0.42 - 4; angle: mostrador.segundos * 6 }
    }
    Rectangle {
        anchors.centerIn: parent
        width: 4.5; height: 4.5; radius: 2.25
        color: Tema.laranja
    }
}
