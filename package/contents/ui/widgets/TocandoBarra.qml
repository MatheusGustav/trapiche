import QtQuick
import "../comp"
import "../dados"

Tile {
    id: raiz
    largura: 366

    Tocador { id: tocador }

    Capa {
        id: capa
        anchors { left: parent.left; leftMargin: 11; verticalCenter: parent.verticalCenter }
        fonte: tocador.capa
        tocando: tocador.tocando
    }
    Column {
        anchors { left: capa.right; leftMargin: 12; right: botao.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 2
        Texto { width: parent.width; text: tocador.existe ? tocador.titulo : "Nada tocando"; tam: 14; forte: true }
        Texto { width: parent.width; text: tocador.artista; tam: 12; fraco: true }
        Item { width: 1; height: 3 }
        Barra { width: parent.width; valor: tocador.progresso; cor: Tema.texto }
    }
    BotaoRedondo {
        id: botao
        anchors { right: seguinte.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
        tam: 38
        visible: tocador.existe
        icone: tocador.tocando ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
        onClicado: tocador.alternar()
    }
    BotaoRedondo {
        id: seguinte
        anchors { right: parent.right; rightMargin: 11; verticalCenter: parent.verticalCenter }
        tam: 32
        color: "transparent"
        visible: tocador.existe
        icone: "media-skip-forward-symbolic"
        onClicado: tocador.proxima()
    }
}
