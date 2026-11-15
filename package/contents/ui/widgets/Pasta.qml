import QtQuick
import QtCore
import org.kde.plasma.plasmoid
import "../comp"
import "../dados"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "pasta")
    readonly property string caminho: {
        if (op.caminho !== "") return op.caminho
        const padrao = StandardPaths.writableLocation(StandardPaths.DownloadLocation).toString()
        return decodeURIComponent(padrao.replace(/^file:\/\//, ""))
    }
    readonly property string nome: caminho.replace(/\/+$/, "").split("/").pop()
    property var arquivos: []

    clicavel: true
    onClicado: {
        if (!balao.visible) listar()
        balao.alternar()
    }

    function listar() {
        executor.rodar("find " + Util.aspas(caminho) + " -maxdepth 1 -mindepth 1 -not -name '.*' -printf '%T@\\t%y\\t%f\\n' | sort -rn | head -12", saida => {
            raiz.arquivos = saida.split("\n").filter(l => l !== "").map(l => {
                const partes = l.split("\t")
                const nomeArquivo = partes.slice(2).join("\t")
                return {
                    nome: nomeArquivo,
                    pasta: partes[1] === "d",
                    url: "file://" + (raiz.caminho + "/" + nomeArquivo).split("/").map(encodeURIComponent).join("/")
                }
            })
        })
    }

    Comando { id: executor }

    // Pasta desenhada em vetor: a tampa inclina e uma folha sobe quando está aberta.
    Item {
        id: desenho
        readonly property bool aberta: balao.visible
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 2
        width: 42; height: 34

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
        larguraConteudo: 380
        alturaConteudo: cabecalho.height + grade.implicitHeight + 20

        Item {
            id: cabecalho
            width: parent.width; height: 38
            Texto {
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                text: raiz.nome
                tam: 15
                forte: true
                renderType: Text.NativeRendering
            }
            BotaoRedondo {
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                tam: 28
                icone: "folder-open-symbolic"
                onClicado: {
                    Qt.openUrlExternally("file://" + raiz.caminho)
                    balao.visible = false
                }
            }
        }
        GradeArquivos {
            id: grade
            anchors { left: parent.left; right: parent.right; top: cabecalho.bottom; topMargin: 6 }
            itens: raiz.arquivos
            mostrar: balao.visible && raiz.arquivos.length > 0
            vazio: "Pasta vazia"
            onAberto: balao.visible = false
        }
    }
}
