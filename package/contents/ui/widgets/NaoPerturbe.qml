import QtQuick
import org.kde.notificationmanager as Notificacoes
import "../comp"

Tile {
    id: raiz
    readonly property bool ligado: {
        const ate = ajustes.notificationsInhibitedUntil
        return ate !== undefined && !isNaN(ate.getTime()) && ate.getTime() > Date.now()
    }

    clicavel: true
    onClicado: {
        const ate = new Date()
        if (ligado) ate.setFullYear(ate.getFullYear() - 1)
        else ate.setFullYear(ate.getFullYear() + 1)
        ajustes.notificationsInhibitedUntil = ate
        ajustes.save()
    }

    Notificacoes.Settings { id: ajustes; live: true }

    Rectangle {
        anchors.centerIn: parent
        width: 52; height: 52; radius: 26
        color: raiz.ligado ? Tema.roxo : Tema.botao
        Behavior on color { ColorAnimation { duration: Tema.normal } }
        Icone {
            anchors.centerIn: parent
            source: "weather-clear-night-symbolic"
            tam: 24
            cor: raiz.ligado ? "white" : Tema.textoFraco
            rotation: raiz.ligado ? -20 : 0
            scale: raiz.ligado ? 1.1 : 1
            Behavior on rotation { SpringAnimation { spring: 3; damping: 0.25 } }
            Behavior on scale { SpringAnimation { spring: 3; damping: 0.25 } }
        }
    }
}
