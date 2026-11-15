import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "catalogo.js" as Catalogo

PlasmoidItem {
    id: raiz

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    fullRepresentation: Item {
        id: doca

        readonly property bool emPainel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        readonly property real alturaTile: emPainel ? height : 77

        Layout.minimumWidth: linha.width
        Layout.preferredWidth: linha.width
        Layout.maximumWidth: emPainel ? linha.width : -1
        Layout.minimumHeight: emPainel ? -1 : 77
        Layout.preferredHeight: emPainel ? -1 : 77

        Loader {
            active: Plasmoid.configuration.widgets.indexOf("tempo-de-tela") >= 0 || Plasmoid.configuration.widgets.indexOf("linha-do-dia") >= 0
            source: "dados/Rastreador.qml"
        }

        Row {
            id: linha
            anchors.verticalCenter: parent.verticalCenter
            height: doca.alturaTile
            spacing: Math.round(8 * height / 77)

            Repeater {
                model: Plasmoid.configuration.widgets

                delegate: Loader {
                    id: vaga
                    required property string modelData
                    required property int index
                    readonly property var registro: Catalogo.achar(modelData)

                    height: linha.height
                    source: registro ? "widgets/" + registro.arq : ""
                    opacity: 0
                    transform: Translate { id: deslize; y: linha.height * 0.35 }
                    onLoaded: {
                        entrada.start()
                        if (modelData === Plasmoid.configuration.testeAbrir && item.clicavel)
                            item.clicado()
                    }

                    SequentialAnimation {
                        id: entrada
                        PauseAnimation { duration: vaga.index * 45 }
                        ParallelAnimation {
                            NumberAnimation { target: vaga; property: "opacity"; to: 1; duration: 260 }
                            NumberAnimation { target: deslize; property: "y"; to: 0; duration: 420; easing.type: Easing.OutBack }
                        }
                    }
                }
            }
        }
    }
}
