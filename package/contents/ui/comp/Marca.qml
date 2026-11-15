import QtQuick

// Quadrado colorido com iniciais: fica no lugar do logotipo de um serviço.
Rectangle {
    id: marca
    property string sigla
    property color corTexto: "white"
    property real tam: 57

    width: tam
    height: tam
    radius: tam * 0.24
    color: Tema.azul

    Texto {
        anchors.centerIn: parent
        text: marca.sigla
        tam: marca.tam * (marca.sigla.length > 1 ? 0.36 : 0.5)
        forte: true
        color: marca.corTexto
    }
}
