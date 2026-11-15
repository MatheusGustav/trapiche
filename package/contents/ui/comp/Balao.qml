import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

// Janela que abre a partir de um tile.
PlasmaCore.Dialog {
    id: balao
    property real larguraConteudo: 300
    property real alturaConteudo: 220
    property bool fixo: false           // não some ao perder o foco (durante um arraste, por exemplo)
    default property alias conteudo: caixa.data
    signal abriu()

    location: Plasmoid.location
    type: PlasmaCore.Dialog.AppletPopup
    hideOnWindowDeactivate: !fixo
    flags: Qt.WindowStaysOnTopHint

    function alternar() { visible = !visible }
    onVisibleChanged: if (visible) abriu()

    mainItem: Item {
        id: caixa
        width: balao.larguraConteudo
        height: balao.alturaConteudo
    }
}
