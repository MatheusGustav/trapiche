import QtQuick
import QtQuick.Controls as QQC2
import QtCore
import org.kde.plasma.components as PlasmaComponents
import "../dados"
import "../util.js" as Util

// Mini gerenciador de arquivos: navega, seleciona, arrasta, arruma, renomeia, copia, move e manda para a lixeira.
// As operações rodam em code/arquivos.py.
FocusScope {
    id: ger
    property string inicio
    property bool ocultos: false
    property bool mostrar: false
    readonly property bool arrastando: arrastados.length > 0
    property bool recebendo: false
    signal fechar()
    signal alternarOcultos()

    property string pasta: ""
    property var historico: []
    property var todos: []              // { nome, pasta, tamanho, data, url }, na ordem do script
    property string modo: "data"
    readonly property string busca: campoBusca.text
    property bool buscando: false
    property bool carregado: false
    property bool ocupado: false
    property int pedido: 0
    property string erro: ""
    property string falha: ""           // erro ao ler a pasta atual
    property string detalhe: ""
    property int marcados: 0
    property int ancora: -1
    property var transferencia: ({ acao: "", caminhos: [] })
    property string edicao: ""          // "renomear" ou "nova-pasta"
    property string editando: ""
    property string depois: ""          // nome a selecionar quando a lista chegar
    property bool cascata: false
    property var arrastados: []
    property string principal: ""
    property bool soltouDentro: false
    property int indiceAlvo: -1
    property real passoRolagem: 0
    readonly property bool podeReordenar: busca === "" && arrastados.length === 1
    readonly property int colunas: 5

    readonly property var atalhos: [
        { nome: "Pessoal", icone: "user-home-symbolic", caminho: local(StandardPaths.writableLocation(StandardPaths.HomeLocation)) },
        { nome: "Downloads", icone: "folder-download-symbolic", caminho: local(StandardPaths.writableLocation(StandardPaths.DownloadLocation)) },
        { nome: "Documentos", icone: "folder-documents-symbolic", caminho: local(StandardPaths.writableLocation(StandardPaths.DocumentsLocation)) },
        { nome: "Imagens", icone: "folder-pictures-symbolic", caminho: local(StandardPaths.writableLocation(StandardPaths.PicturesLocation)) }
    ]

    onOcultosChanged: if (mostrar) listar(false)

    function local(url) {
        const texto = String(url)
        return texto.startsWith("file://") ? decodeURIComponent(texto.slice(7)) : ""
    }
    function uri(caminho) { return "file://" + caminho.split("/").map(encodeURIComponent).join("/") }
    function caminhoDe(nome) { return (pasta === "/" ? "" : pasta) + "/" + nome }
    function paiDe(caminho) { return caminho.replace(/\/[^/]*$/, "") || "/" }
    function semAcento(texto) { return String(texto).normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase() }

    function operar(dados, retorno) {
        executor.rodar("python3 " + Util.script(Qt.resolvedUrl("."), "arquivos.py") + " " + Util.aspas(JSON.stringify(dados)), saida => {
            let resposta
            try { resposta = JSON.parse(saida) } catch (e) { resposta = { erro: "arquivos.py não respondeu" } }
            if (resposta.erro) avisar(resposta.erro)
            else if (resposta.erros && resposta.erros.length > 0) avisar(resposta.erros.join(" · "))
            if (retorno) retorno(resposta)
        })
    }
    function avisar(texto) {
        erro = texto
        limparAviso.restart()
    }

    // Navegação
    function abrir() {
        historico = []
        edicao = ""
        buscando = false
        campoBusca.text = ""
        ir(inicio, false)
        vista.forceActiveFocus()
    }
    function ir(caminho, guardar) {
        if (guardar && pasta !== "" && caminho !== pasta) historico = historico.concat([pasta])
        pasta = caminho
        edicao = ""
        buscando = false
        campoBusca.text = ""
        listar(true)
    }
    function voltar() {
        if (historico.length === 0) return
        const anterior = historico[historico.length - 1]
        historico = historico.slice(0, -1)
        depois = ""
        ir(anterior, false)
    }
    function subir() {
        if (pasta === "/") return
        depois = pasta.split("/").pop()
        ir(paiDe(pasta), true)
    }

    // Lista
    function listar(nova) {
        const numero = ++pedido
        ocupado = true
        operar({ acao: "listar", pasta: pasta, ocultos: ocultos }, resposta => {
            if (numero !== pedido) return
            ocupado = false
            carregado = true
            todos = resposta.erro ? [] : resposta.itens
            falha = resposta.erro || ""
            if (!resposta.erro) {
                pasta = resposta.pasta
                modo = resposta.modo
            }
            if (nova) preencher()
            else sincronizar()
            if (depois !== "") {
                selecionarNome(depois)
                depois = ""
            }
        })
    }
    function visiveis() {
        if (busca === "") return todos
        const procura = semAcento(busca)
        return todos.filter(i => semAcento(i.nome).indexOf(procura) >= 0)
    }
    function linha(item) {
        return { nome: item.nome, url: item.url, pasta: item.pasta, tamanho: item.tamanho, data: item.data, marcado: false }
    }
    function preencher() {
        cascata = true
        modelo.clear()
        modelo.append(visiveis().map(linha))
        ancora = -1
        contar()
        vista.positionViewAtBeginning()
        fimCascata.restart()
    }
    // Leva o modelo à lista atual sem recriar tudo, para as células deslizarem até o lugar novo.
    function sincronizar() {
        const lista = visiveis()
        const quer = {}
        for (const item of lista) quer[item.nome] = true
        for (let i = modelo.count - 1; i >= 0; i--)
            if (!quer[modelo.get(i).nome]) modelo.remove(i)
        for (let i = 0; i < lista.length; i++) {
            const item = lista[i]
            let j = i
            while (j < modelo.count && modelo.get(j).nome !== item.nome) j++
            if (j === modelo.count) {
                modelo.insert(i, linha(item))
                continue
            }
            if (j !== i) modelo.move(j, i, 1)
            const atual = modelo.get(i)
            if (atual.data !== item.data || atual.tamanho !== item.tamanho || atual.pasta !== item.pasta)
                modelo.set(i, { url: item.url, pasta: item.pasta, tamanho: item.tamanho, data: item.data })
        }
        contar()
    }
    function indiceDe(nome) {
        for (let i = 0; i < modelo.count; i++)
            if (modelo.get(i).nome === nome) return i
        return -1
    }

    // Seleção
    function selecionar(indice, modificadores) {
        if (indice < 0 || indice >= modelo.count) return
        if ((modificadores & Qt.ShiftModifier) && ancora >= 0) {
            const de = Math.min(ancora, indice), ate = Math.max(ancora, indice)
            const somar = (modificadores & Qt.ControlModifier) !== 0
            for (let i = 0; i < modelo.count; i++) {
                const marcar = (i >= de && i <= ate) || (somar && modelo.get(i).marcado === true)
                if (modelo.get(i).marcado !== marcar) modelo.setProperty(i, "marcado", marcar)
            }
        } else if (modificadores & Qt.ControlModifier) {
            modelo.setProperty(indice, "marcado", !modelo.get(indice).marcado)
            ancora = indice
        } else {
            for (let i = 0; i < modelo.count; i++)
                if (modelo.get(i).marcado !== (i === indice)) modelo.setProperty(i, "marcado", i === indice)
            ancora = indice
        }
        vista.currentIndex = indice
        contar()
    }
    function marcarTodos(marcar) {
        for (let i = 0; i < modelo.count; i++)
            if (modelo.get(i).marcado !== marcar) modelo.setProperty(i, "marcado", marcar)
        contar()
    }
    function selecionarNome(nome) {
        const i = indiceDe(nome)
        if (i < 0) return
        selecionar(i, 0)
        vista.positionViewAtIndex(i, GridView.Contain)
    }
    function contar() {
        let n = 0, unico = null
        for (let i = 0; i < modelo.count; i++) {
            if (modelo.get(i).marcado) {
                n++
                unico = modelo.get(i)
            }
        }
        marcados = n
        if (n !== 1) {
            detalhe = ""
            return
        }
        const quando = new Date(unico.data * 1000).toLocaleString(Qt.locale("pt_BR"), "dd/MM/yyyy HH:mm")
        detalhe = unico.nome + " · " + (unico.pasta ? quando : Util.bytes(unico.tamanho) + " · " + quando)
    }
    function itensMarcados() {
        const lista = []
        for (let i = 0; i < modelo.count; i++) {
            const item = modelo.get(i)
            if (item.marcado) lista.push({ nome: item.nome, pasta: item.pasta, url: item.url, caminho: caminhoDe(item.nome) })
        }
        return lista
    }

    // Ações
    function abrirSelecao() {
        const itens = itensMarcados()
        if (itens.length === 1 && itens[0].pasta) {
            ir(itens[0].caminho, true)
            return
        }
        const arquivos = itens.filter(i => !i.pasta)
        for (const item of arquivos) Qt.openUrlExternally(item.url)
        if (arquivos.length > 0) fechar()
    }
    function mover(caminhos, destino) {
        operar({ acao: "mover", itens: caminhos, destino: destino }, () => { if (mostrar) listar(false) })
    }
    function copiar(caminhos, destino) {
        operar({ acao: "copiar", itens: caminhos, destino: destino }, resposta => {
            if (!mostrar) return
            if (destino === pasta && resposta.nomes && resposta.nomes.length > 0) depois = resposta.nomes[0]
            listar(false)
        })
    }
    function receber(urls, destino) {
        const caminhos = []
        for (const url of urls) {
            const caminho = local(url)
            if (caminho !== "") caminhos.push(caminho)
        }
        if (caminhos.length < urls.length) avisar("Só dá para receber arquivos deste computador")
        if (caminhos.length > 0) copiar(caminhos, destino)
    }
    function lixeira() {
        const caminhos = itensMarcados().map(i => i.caminho)
        if (caminhos.length > 0) operar({ acao: "lixeira", itens: caminhos }, () => listar(false))
    }
    function copiarSelecao(recortar) {
        const itens = itensMarcados()
        if (itens.length === 0) return
        transferencia = { acao: recortar ? "recortar" : "copiar", caminhos: itens.map(i => i.caminho) }
        const lista = itens.map(i => i.url).join("\r\n")
        executor.rodar("printf '%s' " + Util.aspas(lista) + " | wl-copy --type text/uri-list >/dev/null 2>&1", null)
    }
    // Cola o que estiver na área de transferência do sistema; sem nada lá, o que foi copiado aqui.
    function colar() {
        executor.rodar("wl-paste --no-newline --type text/uri-list 2>/dev/null", saida => {
            const nossos = transferencia.caminhos
            let caminhos = saida.split(/\r?\n/).map(local).filter(c => c !== "")
            if (caminhos.length === 0) caminhos = nossos
            if (caminhos.length === 0) {
                avisar("Nada para colar")
                return
            }
            const mesmos = caminhos.length === nossos.length && caminhos.every((c, i) => c === nossos[i])
            if (mesmos && transferencia.acao === "recortar") {
                transferencia = { acao: "", caminhos: [] }
                mover(caminhos, pasta)
            } else {
                copiar(caminhos, pasta)
            }
        })
    }
    function mudarModo(novo) {
        operar({ acao: "modo", pasta: pasta, modo: novo, nomes: todos.map(i => i.nome) }, resposta => {
            if (!resposta.erro) listar(false)
        })
    }
    function gravarOrdem() {
        const porNome = {}
        for (const item of todos) porNome[item.nome] = item
        const nomes = []
        for (let i = 0; i < modelo.count; i++) nomes.push(modelo.get(i).nome)
        todos = nomes.map(n => porNome[n]).filter(i => i !== undefined)
        modo = "manual"
        operar({ acao: "ordem", pasta: pasta, nomes: nomes }, null)
    }

    // Renomear e nova pasta usam o campo da barra de baixo.
    function comecarRenomear() {
        const itens = itensMarcados()
        if (itens.length !== 1) return
        edicao = "renomear"
        editando = itens[0].caminho
        campo.text = itens[0].nome
        const extensao = /(\.tar)?\.[^.]+$/i.exec(itens[0].nome)
        campo.forceActiveFocus()
        campo.select(0, !itens[0].pasta && extensao && extensao.index > 0 ? extensao.index : itens[0].nome.length)
    }
    function comecarNovaPasta() {
        const existe = {}
        for (const item of todos) existe[item.nome] = true
        let nome = "Nova pasta"
        for (let n = 1; existe[nome]; n++) nome = "Nova pasta (" + n + ")"
        edicao = "nova-pasta"
        campo.text = nome
        campo.forceActiveFocus()
        campo.selectAll()
    }
    function confirmarEdicao() {
        const dados = edicao === "renomear"
            ? { acao: "renomear", caminho: editando, nome: campo.text }
            : { acao: "nova-pasta", pasta: pasta, nome: campo.text }
        operar(dados, resposta => {
            if (resposta.erro) return
            depois = resposta.nome
            terminarEdicao()
            listar(false)
        })
    }
    function terminarEdicao() {
        edicao = ""
        vista.forceActiveFocus()
    }
    function buscar(texto) {
        buscando = true
        campoBusca.text += texto
        campoBusca.forceActiveFocus()
    }
    function pararBusca() {
        buscando = false
        campoBusca.text = ""
        vista.forceActiveFocus()
    }

    // Arraste. O mesmo gesto arruma (prévia ao vivo), move para uma subpasta ou solta em outro programa.
    function comecarArrasto(celula) {
        const itens = celula.marcado ? itensMarcados() : [{ caminho: celula.caminho, url: celula.url }]
        arrastados = itens.map(i => i.caminho)
        principal = celula.nome
        soltouDentro = false
        arrastador.Drag.mimeData = { "text/uri-list": itens.map(i => i.url).join("\n") }
        arrastador.Drag.imageSource = celula.imagem
        arrastador.Drag.active = true
    }
    function terminarArrasto(acao) {
        const dentro = soltouDentro
        arrastados = []
        principal = ""
        indiceAlvo = -1
        passoRolagem = 0
        if (!dentro) sincronizar()
        if (!dentro && acao === Qt.MoveAction) listar(false)
    }
    function pairou(dentro) {
        if (arrastando) return
        if (dentro) {
            fimRecebendo.stop()
            recebendo = true
        } else {
            fimRecebendo.restart()
        }
    }
    function indiceEm(x, y) {
        if (x < 0 || y < 0 || x >= vista.width) return -1
        const coluna = Math.min(colunas - 1, Math.floor(x / vista.cellWidth))
        const fileira = Math.floor((y + vista.contentY - vista.originY) / vista.cellHeight)
        const indice = fileira * colunas + coluna
        return indice < modelo.count ? indice : -1
    }
    function sobre(arraste) {
        pairou(true)
        passoRolagem = arraste.y < 28 ? -10 : (arraste.y > vista.height - 28 ? 10 : 0)
        const indice = indiceEm(arraste.x, arraste.y)
        const item = indice >= 0 ? modelo.get(indice) : null
        const fracao = (arraste.x % vista.cellWidth) / vista.cellWidth
        const meio = fracao > 0.22 && fracao < 0.78
        const naPasta = item !== null && item.pasta && arrastados.indexOf(caminhoDe(item.nome)) < 0
            && (!arrastando || !podeReordenar || meio)
        indiceAlvo = naPasta ? indice : -1
        if (arrastando && !naPasta && podeReordenar) {
            const de = indiceDe(principal)
            const para = indice >= 0 ? indice : modelo.count - 1
            if (de >= 0 && para !== de) modelo.move(de, para, 1)
        }
        arraste.accept(arrastando ? Qt.MoveAction : Qt.CopyAction)
    }
    function soltar(evento) {
        const alvo = indiceAlvo
        indiceAlvo = -1
        passoRolagem = 0
        const destino = alvo >= 0 ? caminhoDe(modelo.get(alvo).nome) : pasta
        if (arrastando) {
            soltouDentro = true
            if (alvo >= 0) {
                mover(arrastados.slice(), destino)
            } else if (podeReordenar) {
                const antes = visiveis()
                let mudou = false
                for (let i = 0; i < modelo.count && !mudou; i++) mudou = modelo.get(i).nome !== antes[i].nome
                if (mudou) gravarOrdem()
            }
            evento.accept(Qt.MoveAction)
        } else if (evento.hasUrls) {
            recebendo = false
            receber(evento.urls, destino)
            evento.accept(Qt.CopyAction)
        }
    }
    function soltarEm(destino, evento) {
        if (arrastando) {
            soltouDentro = true
            mover(arrastados.slice(), destino)
            evento.accept(Qt.MoveAction)
        } else if (evento.hasUrls) {
            recebendo = false
            receber(evento.urls, destino)
            evento.accept(Qt.CopyAction)
        }
    }

    function tecla(evento) {
        const ctrl = evento.modifiers & Qt.ControlModifier
        const alt = evento.modifiers & Qt.AltModifier
        const shift = evento.modifiers & Qt.ShiftModifier
        const codigo = evento.key
        const passos = { [Qt.Key_Left]: -1, [Qt.Key_Right]: 1, [Qt.Key_Up]: -colunas, [Qt.Key_Down]: colunas }
        evento.accepted = true
        if (alt && codigo === Qt.Key_Left) voltar()
        else if (alt && codigo === Qt.Key_Up) subir()
        else if (passos[codigo] !== undefined && !alt && modelo.count > 0) {
            const atual = vista.currentIndex < 0 || marcados === 0 ? -passos[codigo] : vista.currentIndex
            const novo = Math.max(0, Math.min(modelo.count - 1, atual + passos[codigo]))
            selecionar(novo, shift ? Qt.ShiftModifier : 0)
            vista.positionViewAtIndex(novo, GridView.Contain)
        }
        else if (codigo === Qt.Key_Delete) lixeira()
        else if (codigo === Qt.Key_F2) comecarRenomear()
        else if (codigo === Qt.Key_F5) listar(false)
        else if (codigo === Qt.Key_Return || codigo === Qt.Key_Enter) abrirSelecao()
        else if (codigo === Qt.Key_Backspace) subir()
        else if (codigo === Qt.Key_Escape) {
            if (busca !== "" || buscando) pararBusca()
            else if (marcados > 0) marcarTodos(false)
            else fechar()
        }
        else if (ctrl && codigo === Qt.Key_A) marcarTodos(true)
        else if (ctrl && codigo === Qt.Key_C) copiarSelecao(false)
        else if (ctrl && codigo === Qt.Key_X) copiarSelecao(true)
        else if (ctrl && codigo === Qt.Key_V) colar()
        else if (ctrl && codigo === Qt.Key_F) buscar("")
        else if (ctrl && codigo === Qt.Key_H) alternarOcultos()
        else if (ctrl && shift && codigo === Qt.Key_N) comecarNovaPasta()
        else if (!ctrl && !alt && evento.text.length === 1 && evento.text > " ") buscar(evento.text)
        else evento.accepted = false
    }

    Comando { id: executor }
    ListModel { id: modelo }
    // O arraste sai daqui, e não da célula: a célula pode ser destruída no meio (rolagem automática) e levar o arraste junto.
    Item {
        id: arrastador
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction | Qt.MoveAction | Qt.LinkAction
        Drag.proposedAction: Qt.CopyAction
        Drag.hotSpot.x: 46
        Drag.hotSpot.y: 30
        Drag.onDragFinished: acao => ger.terminarArrasto(acao)
    }
    Timer {
        id: fimCascata
        interval: 1300
        onTriggered: ger.cascata = false
    }
    Timer {
        id: limparAviso
        interval: 7000
        onTriggered: ger.erro = ""
    }
    Timer {
        id: fimRecebendo
        interval: 700
        onTriggered: ger.recebendo = false
    }
    // Acompanha mudanças feitas por outros programas enquanto o balão está aberto.
    Timer {
        interval: 3000
        repeat: true
        running: ger.mostrar && ger.carregado && !ger.ocupado && !ger.arrastando && ger.edicao === ""
        onTriggered: ger.listar(false)
    }
    Timer {
        interval: 16
        repeat: true
        running: ger.passoRolagem !== 0 && (ger.arrastando || ger.recebendo)
        onTriggered: {
            const limite = Math.max(vista.originY, vista.originY + vista.contentHeight - vista.height)
            vista.contentY = Math.max(vista.originY, Math.min(limite, vista.contentY + ger.passoRolagem))
        }
    }

    Item {
        id: barra
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 36

        Row {
            id: navegacao
            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            spacing: 4
            BotaoRedondo {
                tam: 28
                icone: "go-previous-symbolic"
                enabled: ger.historico.length > 0
                opacity: enabled ? 1 : 0.35
                onClicado: ger.voltar()
            }
            BotaoRedondo {
                tam: 28
                icone: "go-up-symbolic"
                enabled: ger.pasta !== "/"
                opacity: enabled ? 1 : 0.35
                onClicado: ger.subir()
            }
        }
        Migalhas {
            anchors { left: navegacao.right; leftMargin: 6; right: acoes.left; rightMargin: 6; top: parent.top; bottom: parent.bottom }
            visible: !ger.buscando
            caminho: ger.pasta
            onEscolhido: caminho => { if (caminho !== ger.pasta) ger.ir(caminho, true) }
            onPairou: dentro => ger.pairou(dentro)
            onSolto: (caminho, evento) => ger.soltarEm(caminho, evento)
        }
        PlasmaComponents.TextField {
            id: campoBusca
            anchors { left: navegacao.right; leftMargin: 6; right: acoes.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
            visible: ger.buscando
            placeholderText: "Filtrar por nome"
            onTextChanged: if (ger.carregado) ger.sincronizar()
            Keys.onEscapePressed: ger.pararBusca()
            Keys.onDownPressed: {
                vista.forceActiveFocus()
                ger.selecionar(0, 0)
            }
            onAccepted: {
                vista.forceActiveFocus()
                ger.selecionar(0, 0)
            }
        }
        Row {
            id: acoes
            anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
            spacing: 4
            BotaoRedondo {
                tam: 28
                icone: "search-symbolic"
                color: ger.buscando ? Tema.azul : Tema.botao
                onClicado: ger.buscando ? ger.pararBusca() : ger.buscar("")
            }
            BotaoRedondo {
                id: botaoMenu
                tam: 28
                icone: "view-more-symbolic"
                onClicado: menuPasta.popup(botaoMenu, 0, botaoMenu.height)
            }
            BotaoRedondo {
                tam: 28
                icone: "folder-open-symbolic"
                onClicado: {
                    Qt.openUrlExternally(ger.uri(ger.pasta))
                    ger.fechar()
                }
            }
        }
    }

    Row {
        id: fileiraAtalhos
        anchors { left: parent.left; leftMargin: 6; top: barra.bottom }
        height: 30
        spacing: 6

        Repeater {
            model: ger.atalhos

            Rectangle {
                id: atalho
                required property var modelData
                readonly property bool aqui: ger.pasta === modelData.caminho
                anchors.verticalCenter: parent.verticalCenter
                width: conteudoAtalho.implicitWidth + 18
                height: 26
                radius: 13
                color: alvoAtalho.containsDrag || aqui ? Tema.azul : (toqueAtalho.containsMouse ? Tema.trilho : Tema.botao)
                Behavior on color { ColorAnimation { duration: Tema.rapido } }

                Row {
                    id: conteudoAtalho
                    anchors.centerIn: parent
                    spacing: 5
                    Icone {
                        anchors.verticalCenter: parent.verticalCenter
                        source: atalho.modelData.icone
                        tam: 14
                        cor: atalho.aqui ? "white" : Tema.texto
                    }
                    Texto {
                        anchors.verticalCenter: parent.verticalCenter
                        text: atalho.modelData.nome
                        tam: 12
                        color: atalho.aqui ? "white" : Tema.texto
                        renderType: Text.NativeRendering
                    }
                }
                MouseArea {
                    id: toqueAtalho
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: if (!atalho.aqui) ger.ir(atalho.modelData.caminho, true)
                }
                DropArea {
                    id: alvoAtalho
                    anchors.fill: parent
                    keys: ["text/uri-list"]
                    onEntered: ger.pairou(true)
                    onExited: ger.pairou(false)
                    onDropped: evento => ger.soltarEm(atalho.modelData.caminho, evento)
                }
            }
        }
    }

    // Fundo da grade: clique no vazio limpa a seleção, botão direito abre o menu da pasta, roda rola.
    MouseArea {
        id: fundo
        anchors.fill: vista
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: mouse => {
            vista.forceActiveFocus()
            if (!(mouse.modifiers & (Qt.ControlModifier | Qt.ShiftModifier))) ger.marcarTodos(false)
        }
        onClicked: mouse => { if (mouse.button === Qt.RightButton) menuPasta.popup(fundo, mouse.x, mouse.y) }
        onWheel: roda => {
            const passo = roda.pixelDelta.y !== 0 ? roda.pixelDelta.y : roda.angleDelta.y / 2
            const limite = Math.max(vista.originY, vista.originY + vista.contentHeight - vista.height)
            vista.contentY = Math.max(vista.originY, Math.min(limite, vista.contentY - passo))
        }
    }

    GridView {
        id: vista
        anchors { left: parent.left; right: parent.right; top: fileiraAtalhos.bottom; topMargin: 4; bottom: rodape.top }
        clip: true
        focus: true
        model: modelo
        cellWidth: width / ger.colunas
        cellHeight: 92
        keyNavigationEnabled: false
        interactive: false
        QQC2.ScrollBar.vertical: PlasmaComponents.ScrollBar {}
        Keys.onPressed: evento => ger.tecla(evento)

        move: Transition { NumberAnimation { properties: "x,y"; duration: 260; easing.type: Easing.OutCubic } }
        moveDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 260; easing.type: Easing.OutCubic } }
        displaced: Transition { NumberAnimation { properties: "x,y"; duration: 260; easing.type: Easing.OutCubic } }
        add: Transition {
            enabled: !ger.cascata
            NumberAnimation { property: "scale"; from: 0.4; to: 1; duration: 260; easing.type: Easing.OutBack }
        }
        remove: Transition {
            enabled: !ger.cascata
            NumberAnimation { property: "opacity"; to: 0; duration: 160 }
        }

        delegate: Item {
            id: celula
            required property int index
            required property string nome
            required property string url
            required property bool pasta
            required property bool marcado
            readonly property string caminho: ger.caminhoDe(nome)
            readonly property bool apagado: ger.arrastados.indexOf(caminho) >= 0
                || (ger.transferencia.acao === "recortar" && ger.transferencia.caminhos.indexOf(caminho) >= 0)
            property real avanco: 0
            property url imagem

            width: vista.cellWidth
            height: vista.cellHeight

            Component.onCompleted: {
                if (ger.cascata) entrada.start()
                else avanco = 1
            }

            SequentialAnimation {
                id: entrada
                PauseAnimation { duration: Math.max(0, Math.min(celula.index, 25)) * 32 }
                NumberAnimation { target: celula; property: "avanco"; to: 1; duration: 430; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            }

            // Sai do ponto de origem (embaixo, no meio) até o lugar da célula.
            Item {
                id: corpo
                anchors.fill: parent
                scale: 0.35 + 0.65 * celula.avanco
                opacity: Math.min(1, celula.avanco * 1.6) * (celula.apagado ? 0.45 : 1)
                transform: Translate {
                    x: (1 - celula.avanco) * (vista.width / 2 - vista.cellWidth / 2 - (celula.x - vista.contentX))
                    y: (1 - celula.avanco) * (vista.height - (celula.y - vista.contentY))
                }

                Rectangle {
                    anchors { fill: parent; margins: 3 }
                    radius: 12
                    color: ger.indiceAlvo === celula.index ? Qt.rgba(Tema.azul.r, Tema.azul.g, Tema.azul.b, 0.5)
                        : celula.marcado ? Qt.rgba(Tema.azul.r, Tema.azul.g, Tema.azul.b, 0.22)
                        : toque.containsMouse && !ger.arrastando ? Tema.botao : "transparent"
                    border.color: celula.marcado ? Qt.rgba(Tema.azul.r, Tema.azul.g, Tema.azul.b, 0.6) : "transparent"
                    Behavior on color { ColorAnimation { duration: Tema.rapido } }
                }
                CelulaArquivo {
                    id: figura
                    anchors.fill: parent
                    nome: celula.nome
                    url: celula.url
                    pasta: celula.pasta
                    sobre: toque.containsMouse && !ger.arrastando
                    apertado: toque.pressed
                }
            }
            Item { id: fantasma }
            MouseArea {
                id: toque
                property bool jaMarcado: false
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                preventStealing: true
                drag.target: pressedButtons & Qt.LeftButton ? fantasma : null
                drag.threshold: 8
                onPressed: mouse => {
                    vista.forceActiveFocus()
                    jaMarcado = celula.marcado
                    if (!celula.marcado) ger.selecionar(celula.index, mouse.button === Qt.RightButton ? 0 : mouse.modifiers)
                    // A imagem do arraste é tirada uma vez por célula: o Qt avisa no log a cada carga dela.
                    if (mouse.button === Qt.LeftButton && String(celula.imagem) === "")
                        figura.grabToImage(resultado => celula.imagem = resultado.url)
                }
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) menuItens.popup(celula, mouse.x, mouse.y)
                    else if (jaMarcado) ger.selecionar(celula.index, mouse.modifiers)
                }
                onDoubleClicked: mouse => { if (mouse.button === Qt.LeftButton) ger.abrirSelecao() }
                drag.onActiveChanged: if (drag.active) ger.comecarArrasto(celula)
            }
        }
    }

    // Uma área só para soltar na grade: o índice vem da posição, não da célula embaixo do cursor,
    // para a prévia da arrumação não oscilar enquanto as células deslizam.
    DropArea {
        anchors.fill: vista
        keys: ["text/uri-list"]
        onEntered: arraste => ger.sobre(arraste)
        onPositionChanged: arraste => ger.sobre(arraste)
        onExited: {
            ger.indiceAlvo = -1
            ger.passoRolagem = 0
            ger.pairou(false)
        }
        onDropped: evento => ger.soltar(evento)
    }

    Texto {
        anchors.centerIn: vista
        visible: ger.carregado && modelo.count === 0
        text: ger.busca !== "" ? "Nada com “" + ger.busca + "”" : (ger.falha !== "" ? ger.falha : "Pasta vazia")
        fraco: true
        renderType: Text.NativeRendering
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: rodape.top; margins: 8 }
        height: textoAviso.implicitHeight + 14
        radius: 10
        color: Tema.vermelho
        opacity: ger.erro !== "" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Tema.rapido } }

        Texto {
            id: textoAviso
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
            text: ger.erro
            tam: 12
            color: "white"
            wrapMode: Text.Wrap
            maximumLineCount: 3
            renderType: Text.NativeRendering
        }
        MouseArea {
            anchors.fill: parent
            onClicked: ger.erro = ""
        }
    }

    Item {
        id: rodape
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 34

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 8; rightMargin: 8 }
            height: 1
            color: Tema.borda
        }
        Texto {
            anchors { left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 10; verticalCenter: parent.verticalCenter }
            visible: ger.edicao === ""
            tam: 12
            fraco: true
            renderType: Text.NativeRendering
            text: {
                if (!ger.carregado) return ""
                const total = modelo.count === 1 ? "1 item" : modelo.count + " itens"
                if (ger.marcados === 0) return total
                if (ger.marcados === 1) return ger.detalhe
                return ger.marcados + " de " + total + " selecionados"
            }
        }
        Row {
            anchors { left: parent.left; right: parent.right; leftMargin: 8; rightMargin: 8; verticalCenter: parent.verticalCenter }
            visible: ger.edicao !== ""
            spacing: 6
            Texto {
                id: rotuloCampo
                anchors.verticalCenter: parent.verticalCenter
                text: ger.edicao === "renomear" ? "Novo nome" : "Nova pasta"
                tam: 12
                fraco: true
                renderType: Text.NativeRendering
            }
            PlasmaComponents.TextField {
                id: campo
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - rotuloCampo.width - parent.spacing
                onAccepted: ger.confirmarEdicao()
                Keys.onEscapePressed: ger.terminarEdicao()
            }
        }
    }

    PlasmaComponents.Menu {
        id: menuItens
        onClosed: if (ger.edicao === "") vista.forceActiveFocus()
        PlasmaComponents.MenuItem { text: "Abrir"; icon.name: "document-open"; onTriggered: ger.abrirSelecao() }
        PlasmaComponents.MenuItem { text: "Renomear"; icon.name: "edit-rename"; enabled: ger.marcados === 1; onTriggered: ger.comecarRenomear() }
        PlasmaComponents.MenuSeparator {}
        PlasmaComponents.MenuItem { text: "Recortar"; icon.name: "edit-cut"; onTriggered: ger.copiarSelecao(true) }
        PlasmaComponents.MenuItem { text: "Copiar"; icon.name: "edit-copy"; onTriggered: ger.copiarSelecao(false) }
        PlasmaComponents.MenuItem { text: "Colar"; icon.name: "edit-paste"; onTriggered: ger.colar() }
        PlasmaComponents.MenuSeparator {}
        PlasmaComponents.MenuItem { text: "Mover para a lixeira"; icon.name: "user-trash"; onTriggered: ger.lixeira() }
    }
    PlasmaComponents.Menu {
        id: menuPasta
        onClosed: if (ger.edicao === "") vista.forceActiveFocus()
        PlasmaComponents.MenuItem { text: "Nova pasta"; icon.name: "folder-new"; onTriggered: ger.comecarNovaPasta() }
        PlasmaComponents.MenuItem { text: "Colar"; icon.name: "edit-paste"; onTriggered: ger.colar() }
        PlasmaComponents.MenuItem { text: "Selecionar tudo"; icon.name: "edit-select-all"; onTriggered: ger.marcarTodos(true) }
        PlasmaComponents.MenuSeparator {}
        PlasmaComponents.MenuItem { text: "Ordenar por nome"; icon.name: ger.modo === "nome" ? "checkmark" : ""; onTriggered: ger.mudarModo("nome") }
        PlasmaComponents.MenuItem { text: "Ordenar por data"; icon.name: ger.modo === "data" ? "checkmark" : ""; onTriggered: ger.mudarModo("data") }
        PlasmaComponents.MenuItem { text: "Ordenar por tipo"; icon.name: ger.modo === "tipo" ? "checkmark" : ""; onTriggered: ger.mudarModo("tipo") }
        PlasmaComponents.MenuItem { text: "Arrumação manual"; icon.name: ger.modo === "manual" ? "checkmark" : ""; onTriggered: ger.mudarModo("manual") }
        PlasmaComponents.MenuSeparator {}
        PlasmaComponents.MenuItem { text: "Mostrar ocultos"; icon.name: ger.ocultos ? "checkmark" : ""; onTriggered: ger.alternarOcultos() }
    }
}
