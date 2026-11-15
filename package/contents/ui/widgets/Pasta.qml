import QtQuick
import QtCore
import org.kde.plasma.plasmoid
import "../comp"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "pasta")
    readonly property string caminho: {
        if (op.caminho !== "") return op.caminho
        const padrao = StandardPaths.writableLocation(StandardPaths.DownloadLocation).toString()
        return decodeURIComponent(padrao.replace(/^file:\/\//, ""))
    }

    clicavel: true
    semFundo: true
    onClicado: balao.alternar()

    // Arquivo arrastado de outro programa: parar em cima do bloco abre o balão; soltar nele copia para a pasta.
    DropArea {
        id: soltarNoBloco
        anchors.fill: parent
        keys: ["text/uri-list"]
        onEntered: arraste => {
            if (gerenciador.arrastando) arraste.accepted = false
            else abrirAoPairar.restart()
        }
        onExited: abrirAoPairar.stop()
        onDropped: evento => {
            abrirAoPairar.stop()
            gerenciador.receber(evento.urls, balao.visible ? gerenciador.pasta : raiz.caminho)
            evento.accept(Qt.CopyAction)
        }
    }
    Timer {
        id: abrirAoPairar
        interval: 400
        onTriggered: balao.visible = true
    }

    // Pasta desenhada em vetor: a tampa inclina e uma folha sobe quando está aberta.
    Item {
        id: desenho
        readonly property bool aberta: balao.visible
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -3
        width: 42; height: 34
        scale: 1.15

        Rectangle { x: 2; y: 0; width: 17; height: 10; radius: 3.5; color: Qt.darker(Tema.azul, 1.35) }
        Rectangle { y: 5; width: 42; height: 29; radius: 6; color: Qt.darker(Tema.azul, 1.35) }
        Rectangle {
            x: 6; width: 30; height: 22; radius: 3
            y: desenho.aberta ? -3 : 9
            color: "#f4f4f6"
            Behavior on y { SpringAnimation { spring: 3.5; damping: 0.3 } }
        }
        Rectangle {
            id: tampa
            y: 11; width: 42; height: 23; radius: 6
            color: Tema.azul
            transform: Rotation {
                origin.x: 21; origin.y: 23
                axis { x: 1; y: 0; z: 0 }
                angle: desenho.aberta ? -48 : (raiz.sobre ? -18 : 0)
                Behavior on angle { SpringAnimation { spring: 3.5; damping: 0.3 } }
            }
        }
    }

    Balao {
        id: balao
        visualParent: raiz
        larguraConteudo: 460
        alturaConteudo: 474
        fixo: gerenciador.arrastando || gerenciador.recebendo || soltarNoBloco.containsDrag
        onAbriu: gerenciador.abrir()

        Gerenciador {
            id: gerenciador
            anchors.fill: parent
            inicio: raiz.caminho
            mostrar: balao.visible
            ocultos: Util.ler(Plasmoid.configuration.dados, "pastaOcultos", false)
            onAlternarOcultos: Plasmoid.configuration.dados = Util.gravar(Plasmoid.configuration.dados, "pastaOcultos", !ocultos)
            onFechar: balao.visible = false
        }
    }
}
