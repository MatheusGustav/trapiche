import QtQuick
import "../comp"
import "../dados"

Tile {
    id: raiz
    property bool wifi: false
    property bool bluetooth: false
    readonly property bool aviao: !wifi && !bluetooth

    largura: 208

    Comando { id: executor }
    Periodico {
        id: leitura
        comando: "nmcli radio wifi; bluetoothctl show | grep -c 'Powered: yes'"
        intervalo: 5000
        onAtualizado: saida => {
            const linhas = saida.trim().split("\n")
            raiz.wifi = linhas[0] === "enabled"
            raiz.bluetooth = linhas[1] === "1"
        }
    }

    function rodar(comando) { executor.rodar(comando, () => leitura.agora()) }

    component Chave: Rectangle {
        id: chave
        property bool ligada
        property string icone
        signal clicado()
        width: 56; height: 50; radius: 25
        color: ligada ? Tema.azul : Tema.botao
        scale: area.pressed ? 0.9 : (area.containsMouse ? 1.06 : 1)
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.35; mass: 0.5 } }
        Behavior on color { ColorAnimation { duration: Tema.normal } }
        Icone {
            anchors.centerIn: parent
            source: chave.icone
            tam: 22
            cor: chave.ligada ? "white" : Tema.texto
        }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: chave.clicado() }
    }

    Row {
        anchors.centerIn: parent
        spacing: 8
        Chave {
            ligada: raiz.wifi
            icone: raiz.wifi ? "network-wireless-connected-100" : "network-wireless-disconnected"
            onClicado: raiz.rodar("nmcli radio wifi " + (raiz.wifi ? "off" : "on"))
        }
        Chave {
            ligada: raiz.bluetooth
            icone: "network-bluetooth-symbolic"
            onClicado: raiz.rodar("bluetoothctl power " + (raiz.bluetooth ? "off" : "on"))
        }
        Chave {
            ligada: raiz.aviao
            icone: "network-flightmode-on"
            onClicado: raiz.rodar(raiz.aviao ? "nmcli radio wifi on; bluetoothctl power on" : "nmcli radio wifi off; bluetoothctl power off")
        }
    }
}
