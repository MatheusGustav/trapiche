import QtQuick
import org.kde.plasma.plasmoid
import "../comp"
import "../util.js" as Util

// Pasta de aplicativos como widget: os aplicativos são escolhidos nas opções.
Tile {
    id: raiz
    property string instancia: "grupo-apps"
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, instancia)

    clicavel: true
    onClicado: pasta.alternar()

    PastaApps {
        id: pasta
        anchors.centerIn: parent
        ids: raiz.op.apps
        nome: raiz.op.nome
        textoVazio: "Escolha os aplicativos em Configurar Trapiche, aba Opções."
        sobre: raiz.sobre
    }
}
