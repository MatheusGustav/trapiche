import QtQuick
import "../comp"
import "../dados"

Tile {
    id: raiz
    largura: 320

    Tocador { id: tocador }

    Capa {
        id: capa
        anchors { left: parent.left; leftMargin: 11; verticalCenter: parent.verticalCenter }
        fonte: tocador.capa
        tocando: tocador.tocando
    }
    Column {
        anchors { left: capa.right; leftMargin: 12; right: botao.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 2
        Texto { width: parent.width; text: tocador.existe ? tocador.titulo : "Nada tocando"; tam: 15; forte: true }
        Texto { width: parent.width; visible: text !== ""; text: tocador.artista; tam: 13; fraco: true }
    }
    BotaoRedondo {
        id: botao
        anchors { right: parent.right; rightMargin: 13; verticalCenter: parent.verticalCenter }
        tam: 40
        visible: tocador.existe
        icone: tocador.tocando ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
        onClicado: tocador.alternar()
    }
}
