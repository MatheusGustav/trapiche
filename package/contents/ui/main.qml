import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg
import "comp"
import "catalogo.js" as Catalogo

PlasmoidItem {
    id: raiz

    readonly property bool emPainel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
    // Painel do Plasma em que a dock está e os itens dele que desenham o fundo do tema (todos com a mesma geometria).
    property Item painel: null
    property var fundosDoPainel: []
    readonly property Item moldeDoVidro: fundosDoPainel.length > 0 ? fundosDoPainel[0] : null

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    function acharPainel() {
        let item = raiz.parent
        while (item && item.floatingness === undefined) item = item.parent
        if (!item) return false
        // Os fundos ocupam o painel inteiro; os outros itens com imagePath são moldes pequenos do tema.
        const fundos = []
        for (let i = 0; i < item.children.length; i++) {
            const filho = item.children[i]
            if (filho.imagePath !== undefined && filho.width > item.width / 2) fundos.push(filho)
        }
        if (fundos.length === 0) return false
        painel = item
        fundosDoPainel = fundos
        return true
    }

    // O painel só fica pronto depois que o plasmoide é criado.
    Timer {
        interval: 400
        running: raiz.emPainel && raiz.painel === null
        repeat: true
        triggeredOnStart: true
        onTriggered: raiz.acharPainel()
    }

    // Esconde o fundo do tema sem desligar o desfoque que o Plasma aplica atrás do painel.
    Instantiator {
        model: raiz.fundosDoPainel
        delegate: Binding {
            required property var modelData
            target: modelData
            property: "visible"
            value: false
            restoreMode: Binding.RestoreBindingOrValue
        }
    }

    // O desfoque do Plasma segue a máscara do fundo do tema, de cantos quase retos; esta moldura dá a ele os cantos do vidro.
    KSvg.FrameSvgItem {
        id: mascara
        parent: raiz.painel
        opacity: 0
        x: vidro.x; y: vidro.y; width: vidro.width; height: vidro.height
        imagePath: decodeURIComponent(Qt.resolvedUrl("../images/mascara-vidro.svg").toString().replace(/^file:\/\//, ""))
    }
    Binding {
        target: raiz.painel
        property: "panelMask"
        value: mascara.mask
        when: raiz.moldeDoVidro !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    // Barra de vidro no lugar do fundo do painel, atrás de tudo o que está nele.
    Rectangle {
        id: vidro
        parent: raiz.painel
        visible: raiz.moldeDoVidro !== null
        z: -1
        x: raiz.moldeDoVidro ? raiz.moldeDoVidro.x : 0
        y: raiz.moldeDoVidro ? raiz.moldeDoVidro.y : 0
        width: raiz.moldeDoVidro ? raiz.moldeDoVidro.width : 0
        height: raiz.moldeDoVidro ? raiz.moldeDoVidro.height : 0
        color: Tema.vidro
        border.color: Tema.vidroBorda
        border.width: 1
        radius: 24      // o mesmo raio de images/mascara-vidro.svg

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
            height: parent.height * 0.5
            topLeftRadius: vidro.radius - 1
            topRightRadius: vidro.radius - 1
            gradient: Gradient {
                GradientStop { position: 0; color: Tema.brilho }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }

    fullRepresentation: Item {
        id: doca

        readonly property bool emPainel: raiz.emPainel
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
