import QtQuick

Text {
    property real tam: 14
    property bool forte: false
    property bool fraco: false

    font.pixelSize: tam
    font.weight: forte ? Font.Bold : Font.Medium
    color: fraco ? Tema.textoFraco : Tema.texto
    renderType: Text.QtRendering
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
