import QtQuick
import QtCore

// Caminho clicável de uma pasta, mostrando sempre o fim. Cada parte também recebe arquivos soltos.
Item {
    id: migalhas
    property string caminho
    signal escolhido(string caminho)
    signal pairou(bool dentro)
    signal solto(string caminho, var evento)

    readonly property string casa: decodeURIComponent(StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace(/^file:\/\//, ""))
    readonly property var partes: {
        const lista = []
        let base = ""
        let resto = caminho
        if (caminho === casa || caminho.startsWith(casa + "/")) {
            lista.push({ nome: "Pessoal", caminho: casa })
            base = casa
            resto = caminho.slice(casa.length)
        } else {
            lista.push({ nome: "Raiz", caminho: "/" })
        }
        for (const nome of resto.split("/").filter(p => p !== "")) {
            base += "/" + nome
            lista.push({ nome: nome, caminho: base })
        }
        return lista
    }

    clip: true

    Row {
        x: Math.min(0, migalhas.width - width)
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: migalhas.partes

            Row {
                id: parte
                required property var modelData
                required property int index
                readonly property bool ultima: index === migalhas.partes.length - 1

                Texto {
                    visible: parte.index > 0
                    height: 26
                    text: "›"
                    tam: 13
                    fraco: true
                }
                Rectangle {
                    width: rotulo.implicitWidth + 12
                    height: 26
                    radius: 8
                    color: alvo.containsDrag ? Tema.azul : (toque.containsMouse ? Tema.botao : "transparent")
                    Behavior on color { ColorAnimation { duration: Tema.rapido } }

                    Texto {
                        id: rotulo
                        anchors.centerIn: parent
                        text: parte.modelData.nome
                        tam: 13
                        forte: parte.ultima
                        fraco: !parte.ultima
                        renderType: Text.NativeRendering
                    }
                    MouseArea {
                        id: toque
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: migalhas.escolhido(parte.modelData.caminho)
                    }
                    DropArea {
                        id: alvo
                        anchors.fill: parent
                        keys: ["text/uri-list"]
                        onEntered: migalhas.pairou(true)
                        onExited: migalhas.pairou(false)
                        onDropped: evento => migalhas.solto(parte.modelData.caminho, evento)
                    }
                }
            }
        }
    }
}
