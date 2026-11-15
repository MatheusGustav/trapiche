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

    largura: Math.max(77, 14 + (lista.count + atalhos.length) * 50)
    semFundo: true

    function salvarFixados() {
        Plasmoid.configuration.opcoes = Util.gravarOpcao(Plasmoid.configuration.opcoes, "apps", "fixados", tarefas.launcherList.join(","))
    }
    function salvarAtalhos(nova) { Plasmoid.configuration.dados = Util.gravar(Plasmoid.configuration.dados, "atalhos", nova) }

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

    Comando { id: executor }
    PlasmaExtras.Menu {
        id: menu
        property string rotulo
        property var acao
        placement: PlasmaExtras.Menu.TopPosedLeftAlignedPopup
        PlasmaExtras.MenuItem { text: menu.rotulo; icon: "window-pin"; onClicked: menu.acao() }
    }
    // Pega o que for solto nas margens do bloco; em cima de um ícone, quem pega é a área dele.
    DropArea {
        anchors.fill: parent
        keys: ["text/uri-list"]
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
        anchors.centerIn: parent
        Repeater {
            id: lista
            model: tarefas

            Item {
                id: app
                required property int index
                required property var model
                readonly property bool aberto: model.IsWindow === true || model.IsGroupParent === true
                readonly property bool ativo: model.IsActive === true

                width: 50; height: 77

                Kirigami.Icon {
                    id: icone
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: (toque.containsMouse ? 8 : 14) + salto
                    width: 42; height: 42
                    source: app.model.decoration
                    scale: toque.pressed ? 0.88 : (toque.containsMouse || soltura.containsDrag ? 1.18 : 1)
                    property real salto: 0
                    Behavior on scale { SpringAnimation { spring: 5; damping: 0.35; mass: 0.5 } }
                    Behavior on y { enabled: !pulo.running; SpringAnimation { spring: 5; damping: 0.4; mass: 0.5 } }

                    SequentialAnimation {
                        id: pulo
                        loops: 2
                        NumberAnimation { target: icone; property: "salto"; to: -14; duration: 190; easing.type: Easing.OutQuad }
                        NumberAnimation { target: icone; property: "salto"; to: 0; duration: 260; easing.type: Easing.OutBounce }
                    }
                }
                Rectangle {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
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
                    onClicked: mouse => {
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
            model: raiz.atalhos

            PlasmaCore.ToolTipArea {
                id: atalho
                required property var modelData
                required property int index
                readonly property string nome: decodeURIComponent(modelData.url.replace(/\/$/, "").split("/").pop())

                width: 50; height: 77
                mainText: nome

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: toqueAtalho.containsMouse ? 8 : 14
                    width: 42; height: 42
                    scale: toqueAtalho.pressed ? 0.88 : (toqueAtalho.containsMouse ? 1.18 : 1)
                    Behavior on scale { SpringAnimation { spring: 5; damping: 0.35; mass: 0.5 } }
                    Behavior on y { SpringAnimation { spring: 5; damping: 0.4; mass: 0.5 } }

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
