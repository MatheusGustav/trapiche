import QtQuick

// Quadrado colorido com o logotipo de um serviço, pintado de uma cor só. "logotipo" é o nome do arquivo em contents/images.
Rectangle {
    id: marca
    property string logotipo
    property color corLogotipo: "white"
    property real tam: 57

    width: tam
    height: tam
    radius: tam * 0.24
    color: Tema.azul

    Icone {
        anchors.centerIn: parent
        source: Qt.resolvedUrl("../../images/" + marca.logotipo + ".svg")
        tam: marca.tam * 0.64
        cor: marca.corLogotipo
    }
}
