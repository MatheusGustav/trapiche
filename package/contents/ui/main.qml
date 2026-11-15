import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "comp"
import "catalogo.js" as Catalogo

PlasmoidItem {
    id: raiz

    readonly property bool emPainel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
    // Painel do Plasma em que a dock está e os itens dele que desenhariam o fundo do tema (todos com a mesma geometria).
    property Item painel: null
    property var fundosDoPainel: []
    readonly property Item moldeDoVidro: fundosDoPainel.length > 0 ? fundosDoPainel[0] : null
    // 1 com o painel flutuando, 0 com ele encostado na borda da tela.
    readonly property real flutua: painel ? painel.floatingness : 1

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Widgets…"
            icon.name: "view-grid-symbolic"
            onTriggered: biblioteca.visible = true
        }
    ]

    Biblioteca {
        id: biblioteca
        visualParent: raiz
    }
    Timer {
        interval: 600
        running: Plasmoid.configuration.testeAbrir === "biblioteca"
        onTriggered: biblioteca.visible = true
    }

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

    // Painel sem fundo: o Plasma não desenha o tema nem desfoca o que está atrás, e o vidro fica transparente de verdade.
    Binding {
        target: Plasmoid.containment
        property: "backgroundHints"
        value: PlasmaCore.Types.NoBackground
        when: raiz.emPainel
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
        radius: 24 * raiz.flutua    // encostado na borda da tela, reto

        // Aro claro por dentro da borda, como a beirada de um vidro.
        Rectangle {
            anchors { fill: parent; margins: 1 }
            radius: Math.max(0, vidro.radius - 1)
            color: "transparent"
            border.color: Tema.brilho
            border.width: 2
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
            height: parent.height * 0.5
            topLeftRadius: Math.max(0, vidro.radius - 1)
            topRightRadius: Math.max(0, vidro.radius - 1)
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

        // Num painel que ocupa a tela inteira, a dock fica com a largura que sobra e os blocos vão para o meio.
        Layout.minimumWidth: linha.width
        Layout.preferredWidth: linha.width
        Layout.fillWidth: true
        Layout.minimumHeight: emPainel ? -1 : 77
        Layout.preferredHeight: emPainel ? -1 : 77

        Loader {
            active: Plasmoid.configuration.widgets.indexOf("tempo-de-tela") >= 0 || Plasmoid.configuration.widgets.indexOf("linha-do-dia") >= 0
            source: "dados/Rastreador.qml"
        }

        // Espelho da lista da configuração. Mover uma linha dele não recria os blocos, como trocar a lista inteira faria.
        ListModel { id: blocos }
        function sincronizar() {
            const alvo = Array.from(Plasmoid.configuration.widgets)
            for (let i = blocos.count - 1; i >= 0; i--)
                if (alvo.indexOf(blocos.get(i).wid) < 0) blocos.remove(i)
            for (let i = 0; i < alvo.length; i++) {
                let achado = -1
                for (let k = i; k < blocos.count && achado < 0; k++)
                    if (blocos.get(k).wid === alvo[i]) achado = k
                if (achado < 0) blocos.insert(i, { wid: alvo[i] })
                else if (achado !== i) blocos.move(achado, i, 1)
            }
            if (blocos.count > alvo.length) blocos.remove(alvo.length, blocos.count - alvo.length)
        }
        Component.onCompleted: sincronizar()
        Connections {
            target: Plasmoid.configuration
            function onWidgetsChanged() { doca.sincronizar() }
        }

        // Arrastar para ordenar: segurar o clique solta o bloco, que passa a seguir a alça; os outros abrem espaço.
        property Item arrastado: null
        Item {
            id: alca
            onXChanged: if (doca.arrastado) doca.abrirEspaco()
        }
        function pegar(bloco) {
            alca.x = bloco.x
            arrastado = bloco
        }
        // O bloco arrastado vai para depois dos blocos cujo centro ficou à esquerda do centro dele.
        function abrirEspaco() {
            const centro = alca.x + arrastado.width / 2
            let inicio = 0
            let lugar = 0
            for (let k = 0; k < blocos.count; k++) {
                const outro = repetidor.itemAt(k)
                if (outro !== arrastado && inicio + outro.width / 2 < centro) lugar++
                inicio += outro.width + linha.spacing
            }
            if (lugar !== arrastado.index) blocos.move(arrastado.index, lugar, 1)
        }
        function soltar(gravar) {
            if (!arrastado) return
            arrastado = null
            if (!gravar) return sincronizar()
            const nova = []
            for (let k = 0; k < blocos.count; k++) nova.push(blocos.get(k).wid)
            Plasmoid.configuration.widgets = nova
        }

        Row {
            id: linha
            anchors.centerIn: parent
            height: doca.alturaTile
            spacing: Math.round(8 * height / 77)
            move: Transition { NumberAnimation { properties: "x"; duration: 220; easing.type: Easing.OutCubic } }

            Repeater {
                id: repetidor
                model: blocos

                delegate: MouseArea {
                    id: vaga
                    required property string wid
                    required property int index
                    readonly property var registro: Catalogo.achar(wid)
                    readonly property bool solto: doca.arrastado === vaga

                    width: carga.width
                    height: linha.height
                    z: solto ? 1 : 0
                    opacity: 0
                    scale: solto ? 1.06 : 1
                    Behavior on scale { NumberAnimation { duration: Tema.rapido } }
                    transform: [
                        Translate { id: deslize; y: linha.height * 0.35 },
                        Translate {
                            x: vaga.solto ? alca.x - vaga.x : 0
                            Behavior on x { enabled: !vaga.solto; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }
                    ]

                    // Segurar o clique solta o bloco, mesmo começando num botão de dentro dele; daí em diante o arraste é desta área.
                    drag.filterChildren: true
                    drag.target: solto ? alca : undefined
                    drag.axis: Drag.XAxis
                    drag.threshold: 0
                    drag.minimumX: 0
                    drag.maximumX: linha.width - width
                    pressAndHoldInterval: 350
                    // Quem já está arrastando algo de dentro do bloco (um controle deslizante) não está segurando o bloco.
                    property point apertou
                    onPressed: mouse => apertou = Qt.point(mouse.x, mouse.y)
                    onPressAndHold: mouse => {
                        if (Math.abs(mouse.x - apertou.x) < 8 && Math.abs(mouse.y - apertou.y) < 8) doca.pegar(vaga)
                    }
                    // Soltar longe da dock devolve o bloco ao lugar de antes.
                    onReleased: mouse => doca.soltar(Math.abs(mouse.y - height / 2) < height * 1.5)
                    onCanceled: doca.soltar(false)

                    Loader {
                        id: carga
                        height: parent.height
                        source: vaga.registro ? "widgets/" + vaga.registro.arq : ""
                        onLoaded: {
                            if (item.instancia !== undefined) item.instancia = vaga.wid
                            entrada.start()
                            if (vaga.wid === Plasmoid.configuration.testeAbrir && item.clicavel)
                                item.clicado()
                        }
                    }
                    // Com a biblioteca aberta, cada bloco ganha o botão de tirar da dock.
                    Rectangle {
                        anchors { right: parent.right; top: parent.top; rightMargin: -5; topMargin: -3 }
                        width: 20; height: 20; radius: 10
                        color: Tema.vermelho
                        visible: scale > 0
                        scale: biblioteca.visible ? (tirar.pressed ? 0.85 : 1) : 0
                        Behavior on scale { NumberAnimation { duration: Tema.rapido; easing.type: Easing.OutBack } }

                        Icone { anchors.centerIn: parent; source: "list-remove-symbolic"; tam: 12; cor: "white" }
                        MouseArea {
                            id: tirar
                            anchors { fill: parent; margins: -4 }
                            onClicked: Plasmoid.configuration.widgets = Array.from(Plasmoid.configuration.widgets).filter((id, n) => n !== vaga.index)
                        }
                    }

                    SequentialAnimation {
                        id: entrada
                        PauseAnimation { duration: Math.max(0, vaga.index) * 45 }
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
