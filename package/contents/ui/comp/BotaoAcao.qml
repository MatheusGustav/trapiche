import QtQuick

// Botão redondo colorido de iniciar/pausar.
Rectangle {
    id: botao
    property bool rodando: false
    property real tam: 42
    signal clicado()

    width: tam; height: tam; radius: tam / 2
    color: Tema.azul
    scale: area.pressed ? 0.88 : (area.containsMouse ? 1.08 : 1)
    Behavior on scale { SpringAnimation { spring: 5; damping: 0.35; mass: 0.5 } }

    Icone {
        anchors.centerIn: parent
        source: botao.rodando ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
        tam: botao.tam * 0.46
        cor: "white"
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: botao.clicado() }
}
