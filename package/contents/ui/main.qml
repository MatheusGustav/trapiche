import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "comp"
import "catalogo.js" as Catalogo
import "posicoes.js" as Posicoes
import "util.js" as Util

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

    // Com o painel escondido, o atalho de teclado do widget mostra a dock; ela volta a se esconder com o atalho
    // de novo ou quando o mouse sai dela.
    property bool chamada: false
    Plasmoid.onActivated: chamada = !chamada
    Binding {
        target: Plasmoid
        property: "status"
        value: PlasmaCore.Types.RequiresAttentionStatus
        when: raiz.chamada
        restoreMode: Binding.RestoreBindingOrValue
    }

    // Tudo o que se configura fica na biblioteca; a janela de configuração do Plasma não tem o que mostrar.
    Component.onCompleted: Plasmoid.internalAction("configure").visible = false

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

        // Num painel que ocupa a tela inteira, a dock fica com a largura que sobra e os blocos podem ficar afastados.
        Layout.minimumWidth: linha.minima
        Layout.preferredWidth: linha.minima
        Layout.fillWidth: true
        Layout.minimumHeight: emPainel ? -1 : 77
        Layout.preferredHeight: emPainel ? -1 : 77

        HoverHandler { onHoveredChanged: if (!hovered) raiz.chamada = false }

        Adesivos {
            visible: doca.emPainel && raiz.moldeDoVidro !== null
            painel: raiz.painel
            molde: raiz.moldeDoVidro
            inicio: linha.origem
        }

        Loader {
            active: Plasmoid.configuration.widgets.indexOf("tempo-de-tela") >= 0 || Plasmoid.configuration.widgets.indexOf("linha-do-dia") >= 0
            source: "dados/Rastreador.qml"
        }

        // Espelho da lista da configuração. Mover uma linha dele não recria os blocos, como trocar a lista inteira faria.
        ListModel { id: blocos }
        function sincronizar() {
            const lista = Array.from(Plasmoid.configuration.widgets)
            const alvo = lista.map(Catalogo.atual).filter((id, n, todos) => todos.indexOf(id) === n)
            // Lista com widget que saiu do catálogo: passa a ficar com o que entrou no lugar dele.
            if (alvo.join() !== lista.join()) Plasmoid.configuration.widgets = alvo
            // A posição de quem saiu da dock não fica guardada.
            const sobram = {}
            for (const id in posicoes)
                if (alvo.indexOf(id) >= 0) sobram[id] = posicoes[id]
            if (Object.keys(sobram).length !== Object.keys(posicoes).length)
                Plasmoid.configuration.dados = Util.gravar(Plasmoid.configuration.dados, "posicoes", sobram)
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
            arrumar()
        }
        Component.onCompleted: {
            const opcoes = Catalogo.opcoesAtuais(Plasmoid.configuration.opcoes)
            if (opcoes !== Plasmoid.configuration.opcoes) Plasmoid.configuration.opcoes = opcoes
            sincronizar()
        }
        Connections {
            target: Plasmoid.configuration
            function onWidgetsChanged() { doca.sincronizar() }
        }

        // Posição gravada de cada bloco, pelo id dele na dock (ver posicoes.js).
        readonly property var posicoes: Util.ler(Plasmoid.configuration.dados, "posicoes", {})
        onPosicoesChanged: arrumar()

        // Arrastar para mudar de lugar: segurar o clique solta o bloco, que passa a seguir a alça; os outros não se mexem.
        property Item arrastado: null
        Item { id: alca }
        function pegar(bloco) {
            alca.x = bloco.x
            arrastado = bloco
        }
        // Lugar de cada bloco na barra e a largura que todos ocupam encostados.
        function arrumar() {
            const itens = []
            for (let k = 0; k < blocos.count; k++) {
                const bloco = repetidor.itemAt(k)
                if (bloco) itens.push(bloco)
            }
            linha.ocupado = itens.reduce((soma, bloco) => soma + bloco.width, 0) + Math.max(0, itens.length - 1) * linha.vao
            const lugares = Posicoes.arrumar(itens.map(bloco => ({ larg: bloco.width, secao: bloco.secao, pos: posicoes[bloco.wid] })),
                                             linha.origem, linha.fim, linha.vao, linha.u)
            itens.forEach((bloco, k) => bloco.casa = lugares[k])
        }
        // O bloco solto fica no lugar vazio mais perto de onde foi largado. Daí em diante todos têm posição gravada:
        // os que ainda não tinham ficam com a de agora.
        function soltar(gravar) {
            if (!arrastado) return
            const solto = arrastado
            arrastado = null
            if (!gravar) return
            const ocupados = []
            const novas = {}
            for (let k = 0; k < blocos.count; k++) {
                const bloco = repetidor.itemAt(k)
                if (!bloco || bloco === solto) continue
                ocupados.push({ x: bloco.casa, larg: bloco.width })
                novas[bloco.wid] = posicoes[bloco.wid] || Posicoes.gravar(bloco.casa, bloco.width, linha.origem, linha.fim, linha.u)
            }
            const lugar = Posicoes.encaixar(alca.x, solto.width, ocupados, linha.origem, linha.fim, linha.vao)
            novas[solto.wid] = Posicoes.gravar(lugar, solto.width, linha.origem, linha.fim, linha.u)
            Plasmoid.configuration.dados = Util.gravar(Plasmoid.configuration.dados, "posicoes", novas)
        }

        // Link de site solto em qualquer ponto da dock vai para o bloco "Aplicativos", que o fixa como aplicativo.
        // Fica por baixo dos blocos: o que eles mesmos aceitam não chega aqui. Sem o bloco, ou sem link, quem recebe
        // é o painel do Plasma, como antes.
        function links(urls) { return Array.from(urls).filter(url => /^https?:\/\//i.test(url.toString())) }
        function blocoApps() {
            for (let k = 0; k < blocos.count; k++) {
                const vaga = repetidor.itemAt(k)
                if (vaga && vaga.wid === "apps" && vaga.bloco) return vaga.bloco
            }
            return null
        }
        DropArea {
            anchors.fill: parent
            keys: ["text/uri-list"]
            onEntered: evento => { if (!doca.blocoApps() || doca.links(evento.urls).length === 0) evento.accepted = false }
            onDropped: evento => {
                const apps = doca.blocoApps()
                if (apps) apps.soltou(doca.links(evento.urls))
            }
        }

        Item {
            id: linha
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: doca.alturaTile

            readonly property real u: height / 77
            readonly property int vao: Math.round(8 * u)
            readonly property int divisa: 2 * vao + 2
            property real ocupado: 0
            // Outro widget do Plasma antes da dock, no mesmo painel, fica separado dela por uma barrinha.
            readonly property bool vizinhoAntes: doca.emPainel && String(Plasmoid.containment.configuration.AppletOrder || "").split(";").indexOf(String(Plasmoid.id)) > 0
            // Trecho da barra em que os blocos podem ficar.
            readonly property real origem: vizinhoAntes ? divisa : 0
            readonly property real minima: origem + ocupado
            readonly property real fim: Math.max(width, minima)
            onOrigemChanged: Qt.callLater(doca.arrumar)
            onFimChanged: Qt.callLater(doca.arrumar)

            Rectangle {
                visible: linha.vizinhoAntes
                anchors.verticalCenter: parent.verticalCenter
                x: linha.vao
                width: 2
                height: Math.round(parent.height * 0.42)
                radius: 1
                color: Tema.trilho
            }

            Repeater {
                id: repetidor
                model: blocos
                onItemAdded: Qt.callLater(doca.arrumar)
                onItemRemoved: Qt.callLater(doca.arrumar)

                delegate: MouseArea {
                    id: vaga
                    required property string wid
                    required property int index
                    readonly property var registro: Catalogo.achar(wid)
                    readonly property Item bloco: carga.item
                    readonly property bool solto: doca.arrastado === vaga
                    readonly property int secao: Catalogo.secao(wid)
                    // Lugar do bloco na barra; ao mudar de lugar, ele desliza até lá.
                    property real casa: 0
                    property real recuo: casa
                    Behavior on recuo { enabled: vaga.opacity === 1; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    x: recuo
                    width: carga.width
                    onWidthChanged: Qt.callLater(doca.arrumar)
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
                    drag.minimumX: linha.origem
                    drag.maximumX: linha.fim - width
                    pressAndHoldInterval: 350
                    // Quem já está arrastando algo de dentro do bloco (um controle deslizante) não está segurando o bloco.
                    property point apertou
                    onPressed: mouse => apertou = Qt.point(mouse.x, mouse.y)
                    onPressAndHold: mouse => {
                        if (carga.item && carga.item.arrasteProprio === true) return
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
