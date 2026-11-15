import QtQuick
import org.kde.kirigami as Kirigami
import "../util.js" as Util

// Ícone (ou miniatura, se for imagem) e nome de um arquivo, numa célula de 92 de altura.
Item {
    id: celula
    property string nome
    property string url
    property bool pasta: false
    property bool sobre: false
    property bool apertado: false

    Item {
        id: figura
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 6 }
        width: 48; height: 48
        scale: celula.apertado ? 0.9 : (celula.sobre ? 1.14 : 1)
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.35; mass: 0.5 } }

        Kirigami.Icon {
            anchors.fill: parent
            visible: miniatura.status !== Image.Ready
            source: Util.iconeArquivo(celula.nome, celula.pasta)
        }
        Image {
            id: miniatura
            anchors.fill: parent
            source: !celula.pasta && Util.ehImagem(celula.nome) ? celula.url : ""
            sourceSize: Qt.size(96, 96)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
    }
    Texto {
        anchors { left: parent.left; right: parent.right; top: figura.bottom; topMargin: 4; leftMargin: 4; rightMargin: 4 }
        text: celula.nome
        tam: 11
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignTop
        wrapMode: Text.WrapAnywhere
        maximumLineCount: 2
        renderType: Text.NativeRendering
    }
}
