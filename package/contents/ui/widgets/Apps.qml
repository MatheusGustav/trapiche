import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami
import "../comp"
import "../dados"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "apps")
    // Arquivos e pastas soltos na dock: { url, pasta }.
    readonly property var atalhos: Util.ler(Plasmoid.configuration.dados, "atalhos", [])

    // Pastas de aplicativos, criadas ao arrastar um ícone para cima de outro: { nome, apps: [ids de code/apps.py] }.
    readonly property var pastas: Util.ler(Plasmoid.configuration.dados, "pastasApps", [])
    // Com o clique num ícone de aplicativo, quem arrasta é o ícone: a dock não solta o bloco inteiro.
    property bool arrasteProprio: false
    // Largura da vaga de cada ícone.
    readonly property int passo: 60
    // Ícone de aplicativo sendo arrastado (-1 = nenhum), o centro dele na linha e a vaga em que cairia.
    property int levado: -1
    property real levadoX: 0
    readonly property int alvo: {
        const vaga = Math.floor(levadoX / passo)
        if (levado < 0 || vaga < 0 || Math.abs(levadoX - (vaga + 0.5) * passo) >= passo / 3) return -1
        // As vagas são dos ícones que aparecem: os aplicativos fora de pasta e, depois deles, as pastas.
        let soltos = 0
        for (let k = 0; k < lista.count; k++) {
            const item = lista.itemAt(k)
            if (!item || !item.visible) continue
            if (soltos === vaga) return k === levado ? -1 : k
            soltos++
        }
        return vaga - soltos < pastas.length ? lista.count + vaga - soltos : -1
    }

    largura: Math.max(77, 10 + fileira.width)
    semFundo: true

    // Sem nenhum fixado grava um espaço: opção vazia voltaria para os fixados padrão.
    function salvarFixados() {
        Plasmoid.configuration.opcoes = Util.gravarOpcao(Plasmoid.configuration.opcoes, "apps", "fixados", tarefas.launcherList.join(",") || " ")
    }
    function salvarAtalhos(nova) { Plasmoid.configuration.dados = Util.gravar(Plasmoid.configuration.dados, "atalhos", nova) }

    function salvarPastas(nova) { Plasmoid.configuration.dados = Util.gravar(Plasmoid.configuration.dados, "pastasApps", nova) }
    // O aplicativo que está numa pasta aparece só dentro dela, mesmo aberto.
    function naPasta(ident) { return ident !== "" && pastas.some(p => p.apps.indexOf(ident) >= 0) }
    // Põe o aplicativo arrastado numa pasta: a que já existe na vaga ou uma nova, com o aplicativo que estava lá.
    function juntar(de, para) {
        const origem = lista.itemAt(de)
        const destino = para < lista.count ? lista.itemAt(para) : null
        if (!origem || origem.ident === "") return
        if (para < lista.count && (!destino || destino.ident === "" || destino.ident === origem.ident)) return
        const nova = pastas.map(p => ({ nome: p.nome, apps: p.apps.slice() }))
        const desafixar = [origem, destino].filter(item => item && item.model.HasLauncher === true).map(item => item.model.LauncherUrlWithoutIcon)
        if (destino) nova.push({ nome: "Pasta", apps: [destino.ident, origem.ident] })
        else if (nova[para - lista.count].apps.indexOf(origem.ident) < 0) nova[para - lista.count].apps.push(origem.ident)
        for (const url of desafixar) tarefas.requestRemoveLauncher(url)
        salvarFixados()
        salvarPastas(nova)
    }
    function fixarDeVolta(ids) {
        for (const id of ids) tarefas.requestAddLauncher("applications:" + id + ".desktop")
        salvarFixados()
    }
    function desfazerPasta(indice) {
        fixarDeVolta(pastas[indice].apps)
        salvarPastas(pastas.filter((p, n) => n !== indice))
    }
    // Tira o aplicativo da pasta e o fixa de volta. A pasta que ficaria com um aplicativo só é desfeita.
    function tirarDaPasta(indice, id) {
        if (!pastas[indice] || pastas[indice].apps.indexOf(id) < 0) return
        const resto = pastas[indice].apps.filter(a => a !== id)
        if (resto.length <= 1) return desfazerPasta(indice)
        fixarDeVolta([id])
        salvarPastas(pastas.map((p, n) => n === indice ? { nome: p.nome, apps: resto } : p))
    }
    function alternarFixado(url, fixado) {
        if (fixado ? tarefas.requestRemoveLauncher(url) : tarefas.requestAddLauncher(url)) salvarFixados()
    }
    function tirarAtalho(indice) { salvarAtalhos(atalhos.filter((a, n) => n !== indice)) }

    // Solto de fora: aplicativo (.desktop) fica fixado; arquivo ou pasta vira atalho. O que não existe é ignorado.
    function soltou(urls) {
        const locais = []
        for (const url of urls) {
            const texto = url.toString()
            if (texto.startsWith("file://") && locais.indexOf(texto) < 0) locais.push(texto)
        }
        if (locais.length === 0) return
        const caminhos = locais.map(u => Util.aspas(decodeURIComponent(u.slice(7))))
        executor.rodar("for f in " + caminhos.join(" ") + "; do if [ -d \"$f\" ]; then echo d; elif [ -e \"$f\" ]; then echo f; else echo n; fi; done", saida => {
            const tipos = saida.trim().split("\n")
            const novos = []
            let fixou = false
            locais.forEach((u, n) => {
                if (tipos[n] !== "d" && tipos[n] !== "f") return
                if (tipos[n] === "f" && /\.desktop$/i.test(u)) fixou = tarefas.requestAddLauncher(u) || fixou
                else if (!raiz.atalhos.some(a => a.url === u)) novos.push({ url: u, pasta: tipos[n] === "d" })
            })
            if (fixou) raiz.salvarFixados()
            if (novos.length > 0) raiz.salvarAtalhos(raiz.atalhos.concat(novos))
        })
    }
    function abrirMenu(item, rotulo, acao) {
        menu.rotulo = rotulo
        menu.acao = acao
        menu.visualParent = item
        menu.openRelative()
    }

    // Área de cada ícone: solto, sem fundo, cresce ao passar o mouse.
    component Figura: Item {
        property bool sobre: false
        property bool apertado: false
        property real salto: 0

        anchors.horizontalCenter: parent.horizontalCenter
        y: 11 + salto
        width: 50; height: 50
        scale: apertado ? 0.88 : (sobre ? 1.15 : 1)
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.35; mass: 0.5 } }
    }

    Comando { id: executor }
    PlasmaExtras.Menu {
        id: menu
        property string rotulo
        property var acao
        placement: PlasmaExtras.Menu.TopPosedLeftAlignedPopup
        PlasmaExtras.MenuItem { text: menu.rotulo; icon: "window-pin"; onClicked: menu.acao() }
    }
    // Pega o que for solto nas margens do bloco; em cima de um ícone, quem pega é a área dele.
    // O aplicativo arrastado para fora de uma pasta também é aceito aqui, sem nada a fazer: quem o tira da pasta é o fim do arraste.
    DropArea {
        anchors.fill: parent
        keys: ["text/uri-list", "application/x-trapiche-app"]
        onDropped: evento => raiz.soltou(evento.urls)
    }

    TaskManager.TasksModel {
        id: tarefas
        groupMode: TaskManager.TasksModel.GroupApplications
        sortMode: TaskManager.TasksModel.SortManual
        launchInPlace: true
        separateLaunchers: false
        filterByVirtualDesktop: false
        filterByActivity: false
        filterByScreen: false
        launcherList: raiz.op.fixados.split(",").map(t => t.trim()).filter(t => t !== "")
    }

    Row {
        id: fileira
        anchors.centerIn: parent
        Repeater {
            id: lista
            model: tarefas

            PlasmaCore.ToolTipArea {
                id: app
                required property int index
                required property var model
                mainText: model.AppName || model.display
                readonly property bool aberto: model.IsWindow === true || model.IsGroupParent === true
                readonly property bool ativo: model.IsActive === true
                readonly property string ident: String(model.AppId || "").replace(/\.desktop$/, "")
                property real desloc: 0
                Behavior on desloc { enabled: raiz.levado !== app.index; NumberAnimation { duration: Tema.rapido } }

                visible: !raiz.naPasta(ident)
                width: raiz.passo; height: 77
                z: raiz.levado === index ? 1 : 0

                Figura {
                    id: figura
                    sobre: toque.containsMouse || soltura.containsDrag || raiz.alvo === app.index
                    apertado: toque.pressed && raiz.levado !== app.index
                    transform: Translate { x: app.desloc }

                    Kirigami.Icon {
                        anchors.fill: parent
                        source: app.model.decoration
                    }
                    SequentialAnimation {
                        id: pulo
                        loops: 2
                        NumberAnimation { target: figura; property: "salto"; to: -10; duration: 190; easing.type: Easing.OutQuad }
                        NumberAnimation { target: figura; property: "salto"; to: 0; duration: 260; easing.type: Easing.OutBounce }
                    }
                }
                Rectangle {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 3 }
                    height: 4; radius: 2
                    width: app.ativo ? 16 : 4
                    color: app.model.IsDemandingAttention === true ? Tema.laranja : Tema.azul
                    opacity: app.aberto ? 1 : 0
                    Behavior on width { NumberAnimation { duration: Tema.normal; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: Tema.normal } }
                }
                MouseArea {
                    id: toque
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    // Arrastar o ícone para cima de outro (ou de uma pasta) junta os dois numa pasta.
                    property real inicio: 0
                    property bool arrastou: false
                    function largar(valendo) {
                        raiz.arrasteProprio = false
                        if (raiz.levado !== app.index) return
                        const para = raiz.alvo
                        raiz.levado = -1
                        app.desloc = 0
                        if (valendo && para >= 0) raiz.juntar(app.index, para)
                    }
                    onPressed: mouse => {
                        inicio = mouse.x
                        arrastou = false
                        raiz.arrasteProprio = mouse.button === Qt.LeftButton && app.ident !== ""
                    }
                    onPositionChanged: mouse => {
                        if (!(mouse.buttons & Qt.LeftButton) || app.ident === "") return
                        if (raiz.levado !== app.index && Math.abs(mouse.x - inicio) > 10) {
                            raiz.levado = app.index
                            arrastou = true
                        }
                        if (raiz.levado === app.index) {
                            app.desloc = mouse.x - inicio
                            raiz.levadoX = app.x + raiz.passo / 2 + app.desloc
                        }
                    }
                    onReleased: largar(true)
                    onCanceled: largar(false)
                    onClicked: mouse => {
                        if (arrastou) return
                        const indice = tarefas.makeModelIndex(app.index)
                        if (mouse.button === Qt.RightButton) {
                            const url = app.model.LauncherUrlWithoutIcon
                            const fixado = app.model.HasLauncher === true
                            raiz.abrirMenu(app, fixado ? "Desafixar" : "Fixar", () => raiz.alternarFixado(url, fixado))
                        } else if (mouse.button === Qt.MiddleButton || !app.aberto) {
                            pulo.restart()
                            tarefas.requestNewInstance(indice)
                        } else if (app.ativo) {
                            tarefas.requestToggleMinimized(indice)
                        } else {
                            tarefas.requestActivate(indice)
                        }
                    }
                }
                // Arquivo arrastado parado em cima de um app aberto traz a janela dele para a frente, para soltar lá.
                DropArea {
                    id: soltura
                    anchors.fill: parent
                    keys: ["text/uri-list"]
                    onEntered: if (app.aberto && !app.ativo) ativarAoPairar.restart()
                    onExited: ativarAoPairar.stop()
                    onDropped: evento => {
                        ativarAoPairar.stop()
                        raiz.soltou(evento.urls)
                    }
                }
                Timer {
                    id: ativarAoPairar
                    interval: 400
                    onTriggered: tarefas.requestActivate(tarefas.makeModelIndex(app.index))
                }
            }
        }
        Repeater {
            model: raiz.pastas

            Item {
                id: grupo
                required property var modelData
                required property int index

                width: raiz.passo; height: 77

                PastaApps {
                    id: conteudo
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -2
                    ids: grupo.modelData.apps
                    nome: grupo.modelData.nome
                    sobre: toqueGrupo.containsMouse
                    destaque: raiz.alvo === lista.count + grupo.index
                    arrastavel: true
                    onLevadoParaFora: aplicativo => Qt.callLater(raiz.tirarDaPasta, grupo.index, aplicativo.id)
                    onMenuDoApp: (aplicativo, celula) => raiz.abrirMenu(celula, "Tirar da pasta", () => raiz.tirarDaPasta(grupo.index, aplicativo.id))
                }
                MouseArea {
                    id: toqueGrupo
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) raiz.abrirMenu(grupo, "Desfazer a pasta", () => raiz.desfazerPasta(grupo.index))
                        else conteudo.alternar()
                    }
                }
            }
        }
        Repeater {
            model: raiz.atalhos

            PlasmaCore.ToolTipArea {
                id: atalho
                required property var modelData
                required property int index
                readonly property string nome: decodeURIComponent(modelData.url.replace(/\/$/, "").split("/").pop())

                width: raiz.passo; height: 77
                mainText: nome

                Figura {
                    sobre: toqueAtalho.containsMouse
                    apertado: toqueAtalho.pressed

                    Kirigami.Icon {
                        anchors.fill: parent
                        visible: miniatura.status !== Image.Ready
                        source: Util.iconeArquivo(atalho.nome, atalho.modelData.pasta)
                    }
                    Image {
                        id: miniatura
                        anchors.fill: parent
                        source: !atalho.modelData.pasta && Util.ehImagem(atalho.nome) ? atalho.modelData.url : ""
                        sourceSize: Qt.size(84, 84)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                }
                MouseArea {
                    id: toqueAtalho
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            raiz.abrirMenu(atalho, "Desafixar", () => raiz.tirarAtalho(atalho.index))
                        else
                            executor.rodar("kioclient exec " + Util.aspas(atalho.modelData.url), null)
                    }
                }
            }
        }
    }
}
