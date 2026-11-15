import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import "../comp"
import "../dados"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var local: Qt.locale("pt_BR")
    property date agora: new Date()
    property date mes: new Date(agora.getFullYear(), agora.getMonth(), 1)
    property date escolhido: agora
    property int versao: 0                   // muda quando os feriados do mês mostrado chegam
    readonly property int primeiroDia: Qt.locale().firstDayOfWeek % 7        // 0 = domingo

    readonly property var eventosLocais: Util.ler(Plasmoid.configuration.dados, "eventos", [])     // { id, data, hora, titulo }
    readonly property var ocultos: Util.ler(Plasmoid.configuration.dados, "calendarioOcultos", [])
    readonly property var tipos: [
        { id: "evento", nome: "Eventos", cor: Tema.azul },
        { id: "feriado", nome: "Feriados", cor: Tema.roxo },
        { id: "limite", nome: "Renovação de limite", cor: Tema.ciano }
    ]

    // Dias do mês mostrado, com vazios (0) antes do dia 1 para alinhar na semana.
    readonly property var dias: {
        const total = new Date(mes.getFullYear(), mes.getMonth() + 1, 0).getDate()
        const lista = []
        for (let i = 0; i < (mes.getDay() - primeiroDia + 7) % 7; i++) lista.push(0)
        for (let d = 1; d <= total; d++) lista.push(d)
        return lista
    }
    readonly property var eventosDeHoje: eventosDoDia(agora, versao)
    readonly property var proximo: {
        const hora = Qt.formatTime(agora, "HH:mm")
        return eventosDeHoje.find(e => e.hora !== "" && e.hora >= hora) || null
    }

    largura: 236
    clicavel: true
    onClicado: {
        mes = new Date(agora.getFullYear(), agora.getMonth(), 1)
        escolhido = agora
        balao.alternar()
    }
    onMesChanged: {
        calendario.displayedDate = mes
        recarga.restart()
    }

    function chave(data) { return Qt.formatDate(data, "yyyy-MM-dd") }
    function mesmoDia(a, b) { return chave(a) === chave(b) }
    function cor(tipo) { return tipos.find(t => t.id === tipo).cor }

    // Eventos de um dia, já sem os tipos escondidos: os de dia inteiro primeiro, depois por hora.
    function eventosDoDia(data, versaoAtual) {
        const lista = []
        const dia = chave(data)
        for (const evento of eventosLocais)
            if (evento.data === dia)
                lista.push({ tipo: "evento", hora: evento.hora, titulo: evento.titulo, origem: "Trapiche", id: evento.id })
        const feriados = calendario.daysModel.eventsForDate(new Date(data.getFullYear(), data.getMonth(), data.getDate(), 12))
        for (const feriado of feriados)
            lista.push({ tipo: "feriado", hora: "", titulo: feriado.title, origem: "Feriados" })
        const semana = claude.pronto ? claude.dados.semana : null
        if (semana && semana.renova) {
            const renova = new Date(semana.renova * 1000)
            if (mesmoDia(renova, data))
                lista.push({ tipo: "limite", hora: Qt.formatTime(renova, "HH:mm"), titulo: "Limite semanal renova", origem: "Claude Code" })
        }
        return lista.filter(e => ocultos.indexOf(e.tipo) < 0).sort((a, b) => a.hora < b.hora ? -1 : (a.hora > b.hora ? 1 : 0))
    }
    function salvarEventos(nova) { Plasmoid.configuration.dados = Util.gravar(Plasmoid.configuration.dados, "eventos", nova) }
    function adicionar(titulo, hora) {
        if (titulo.trim() === "") return false
        if (hora !== "" && !/^([01]?\d|2[0-3]):[0-5]\d$/.test(hora)) return false
        const normal = hora === "" ? "" : (hora.length === 4 ? "0" + hora : hora)
        salvarEventos(eventosLocais.concat([{ id: Date.now(), data: chave(escolhido), hora: normal, titulo: titulo.trim() }]))
        return true
    }
    function remover(id) { salvarEventos(eventosLocais.filter(e => e.id !== id)) }
    function alternarTipo(tipo) {
        const nova = ocultos.indexOf(tipo) >= 0 ? ocultos.filter(t => t !== tipo) : ocultos.concat([tipo])
        Plasmoid.configuration.dados = Util.gravar(Plasmoid.configuration.dados, "calendarioOcultos", nova)
    }
    function mudarMes(passo) {
        troca.direcao = passo
        troca.restart()
    }
    function nomeDoDia(data) {
        if (mesmoDia(data, agora)) return "Hoje"
        return data.toLocaleDateString(local, "ddd, d 'de' MMM").replace(/\./g, "")
    }
    function emQuanto(hora) {
        const partes = hora.split(":")
        const minutos = (parseInt(partes[0]) * 60 + parseInt(partes[1])) - (agora.getHours() * 60 + agora.getMinutes())
        return minutos <= 0 ? "agora" : "em " + Util.duracao(minutos * 60)
    }

    Timer { interval: 30000; running: true; repeat: true; onTriggered: raiz.agora = new Date() }
    // Os feriados do mês chegam um pouco depois de trocar o mês mostrado.
    Timer { id: recarga; interval: 400; onTriggered: raiz.versao++ }

    UsoClaude { id: claude }
    PlasmaCalendar.EventPluginsManager { id: fontes; enabledPlugins: ["holidaysevents"] }
    PlasmaCalendar.Calendar {
        id: calendario
        days: 7
        weeks: 6
        firstDayOfWeek: Qt.locale().firstDayOfWeek
        today: raiz.agora
        Component.onCompleted: {
            daysModel.setPluginsManager(fontes)
            recarga.restart()
        }
    }

    component Selo: Rectangle {
        property string tipo
        property real tam: 24
        width: tam; height: tam; radius: tam * 0.28
        color: raiz.cor(tipo)
        Icone {
            anchors.centerIn: parent
            source: parent.tipo === "feriado" ? "view-calendar-holiday" : (parent.tipo === "limite" ? "view-refresh-symbolic" : "view-calendar-day")
            tam: parent.tam * 0.6
            cor: "white"
        }
    }

    Rectangle {
        id: bloco
        anchors { left: parent.left; leftMargin: 11; verticalCenter: parent.verticalCenter }
        width: 55; height: 55; radius: 14
        color: Tema.botao
        Texto {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 7 }
            text: raiz.agora.toLocaleDateString(raiz.local, "ddd").replace(".", "").toUpperCase()
            tam: 10
            forte: true
            color: Tema.vermelho
        }
        Texto {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 }
            text: raiz.agora.getDate()
            tam: 25
            forte: true
        }
    }
    Column {
        anchors { left: bloco.right; leftMargin: 13; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 2
        Texto {
            width: parent.width
            text: raiz.proximo ? raiz.proximo.titulo : raiz.agora.toLocaleDateString(raiz.local, "dddd")
            tam: 15
            forte: true
            font.capitalization: raiz.proximo ? Font.MixedCase : Font.Capitalize
        }
        Texto {
            width: parent.width
            text: {
                if (raiz.proximo) return raiz.proximo.hora + " · " + raiz.emQuanto(raiz.proximo.hora)
                const feriado = raiz.eventosDeHoje.find(e => e.tipo === "feriado")
                return feriado ? feriado.titulo : raiz.agora.toLocaleDateString(raiz.local, "d 'de' MMMM 'de' yyyy")
            }
            tam: 12
            fraco: true
        }
    }

    Balao {
        id: balao
        visualParent: raiz
        larguraConteudo: 836
        alturaConteudo: 96 + 34 + Math.ceil(raiz.dias.length / 7) * 72 + 12
        onAbriu: campo.forceActiveFocus()

        // Cabeçalho: mês, voltar para hoje, trocar de mês, fechar.
        Texto {
            id: titulo
            x: 14; y: 8; height: 40
            text: raiz.mes.toLocaleDateString(raiz.local, "MMMM, yyyy")
            tam: 24
            forte: true
            font.capitalization: Font.Capitalize
            renderType: Text.NativeRendering
        }
        Row {
            anchors { right: parent.right; rightMargin: 10; verticalCenter: titulo.verticalCenter }
            spacing: 6
            Texto {
                anchors.verticalCenter: parent.verticalCenter
                rightPadding: 8
                text: "Hoje"
                tam: 14
                color: Tema.azul
                renderType: Text.NativeRendering
                MouseArea {
                    anchors.fill: parent; anchors.margins: -6
                    onClicked: {
                        raiz.escolhido = raiz.agora
                        raiz.mes = new Date(raiz.agora.getFullYear(), raiz.agora.getMonth(), 1)
                    }
                }
            }
            BotaoRedondo { tam: 30; color: "transparent"; icone: "go-previous-symbolic"; onClicado: raiz.mudarMes(-1) }
            BotaoRedondo { tam: 30; color: "transparent"; icone: "go-next-symbolic"; onClicado: raiz.mudarMes(1) }
            BotaoRedondo { tam: 30; color: "transparent"; icone: "window-close-symbolic"; onClicado: balao.visible = false }
        }

        // Legenda: clicar num tipo esconde ou mostra os eventos dele.
        Row {
            id: legenda
            x: 14; y: 58
            spacing: 16
            Repeater {
                model: raiz.tipos
                Row {
                    id: item
                    required property var modelData
                    readonly property bool oculto: raiz.ocultos.indexOf(modelData.id) >= 0
                    spacing: 6
                    opacity: oculto ? 0.4 : 1
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: item.modelData.cor }
                    Texto {
                        text: item.modelData.nome
                        tam: 13
                        fraco: true
                        font.strikeout: item.oculto
                        renderType: Text.NativeRendering
                        MouseArea { anchors.fill: parent; anchors.margins: -5; onClicked: raiz.alternarTipo(item.modelData.id) }
                    }
                }
            }
        }

        Row {
            id: semana
            x: 14; y: 92
            spacing: 8
            Repeater {
                model: 7
                Rectangle {
                    required property int index
                    readonly property int diaDaSemana: (index + raiz.primeiroDia) % 7
                    readonly property bool hoje: diaDaSemana === raiz.agora.getDay()
                    width: 64; height: 26; radius: 13
                    color: Qt.alpha(Tema.texto, hoje ? 0.12 : 0.06)
                    Texto {
                        anchors.centerIn: parent
                        text: raiz.local.dayName(parent.diaDaSemana, Locale.ShortFormat).replace(".", "").toUpperCase()
                        tam: 11
                        forte: true
                        fraco: !parent.hoje
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        Grid {
            id: grade
            x: 14; y: 126
            columns: 7
            spacing: 8
            property real desloc: 0
            transform: Translate { x: grade.desloc }

            Repeater {
                model: raiz.dias
                Item {
                    id: celula
                    required property int modelData
                    readonly property date quando: new Date(raiz.mes.getFullYear(), raiz.mes.getMonth(), Math.max(1, modelData))
                    readonly property bool hoje: modelData > 0 && raiz.mesmoDia(quando, raiz.agora)
                    readonly property bool marcado: modelData > 0 && raiz.mesmoDia(quando, raiz.escolhido)
                    readonly property bool passado: modelData > 0 && !hoje && quando < raiz.agora
                    readonly property var eventos: modelData > 0 ? raiz.eventosDoDia(quando, raiz.versao) : []
                    width: 64; height: 64

                    Rectangle {
                        anchors.fill: parent
                        visible: celula.modelData > 0
                        radius: 15
                        color: Qt.alpha(Tema.texto, toque.containsMouse ? 0.12 : 0.06)
                        border.width: celula.marcado ? 1.5 : 0
                        border.color: Tema.azul
                        scale: toque.pressed ? 0.94 : 1
                        Behavior on scale { NumberAnimation { duration: Tema.rapido } }
                        Behavior on color { ColorAnimation { duration: Tema.rapido } }

                        Selo {
                            visible: celula.eventos.length > 0
                            x: celula.eventos.length > 1 ? 7 : (parent.width - width) / 2
                            y: 8
                            tipo: celula.eventos.length > 0 ? celula.eventos[0].tipo : "evento"
                        }
                        Rectangle {
                            visible: celula.eventos.length > 1
                            x: 34; y: 10
                            width: 24; height: 20; radius: 10
                            color: Qt.alpha(Tema.texto, 0.14)
                            Texto {
                                anchors.centerIn: parent
                                text: "+" + (celula.eventos.length - 1)
                                tam: 11
                                forte: true
                                fraco: true
                                renderType: Text.NativeRendering
                            }
                        }
                        Texto {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 6 }
                            text: celula.modelData
                            tam: 14
                            forte: !celula.passado
                            color: celula.hoje ? Tema.azul : (celula.passado ? Tema.textoFraco : Tema.texto)
                            renderType: Text.NativeRendering
                        }
                        MouseArea {
                            id: toque
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: raiz.escolhido = celula.quando
                        }
                    }
                }
            }
        }
        SequentialAnimation {
            id: troca
            property int direcao: 1
            ParallelAnimation {
                NumberAnimation { target: grade; property: "desloc"; to: -40 * troca.direcao; duration: 120; easing.type: Easing.InQuad }
                NumberAnimation { target: grade; property: "opacity"; to: 0; duration: 120 }
            }
            ScriptAction { script: raiz.mes = new Date(raiz.mes.getFullYear(), raiz.mes.getMonth() + troca.direcao, 1) }
            PropertyAction { target: grade; property: "desloc"; value: 40 * troca.direcao }
            ParallelAnimation {
                NumberAnimation { target: grade; property: "desloc"; to: 0; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { target: grade; property: "opacity"; to: 1; duration: 220 }
            }
        }

        // Painel do dia escolhido.
        Rectangle {
            id: painel
            readonly property var eventos: raiz.eventosDoDia(raiz.escolhido, raiz.versao)
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom; rightMargin: 6; topMargin: 56; bottomMargin: 6 }
            width: 300
            radius: 18
            color: Qt.alpha(Tema.texto, 0.05)

            Texto {
                x: 18; y: 14
                text: raiz.nomeDoDia(raiz.escolhido)
                tam: 17
                forte: true
                font.capitalization: Font.Capitalize
                renderType: Text.NativeRendering
            }
            Texto {
                anchors { right: parent.right; rightMargin: 18 }
                y: 17
                text: painel.eventos.length === 0 ? "sem eventos" : (painel.eventos.length === 1 ? "1 evento" : painel.eventos.length + " eventos")
                tam: 12
                fraco: true
                renderType: Text.NativeRendering
            }
            ListView {
                id: lista
                anchors { left: parent.left; right: parent.right; top: parent.top; bottom: entrada.top; topMargin: 52; bottomMargin: 8 }
                clip: true
                model: painel.eventos
                delegate: Item {
                    id: linha
                    required property var modelData
                    width: lista.width; height: 50
                    Texto {
                        x: 18; width: 56
                        anchors.verticalCenter: parent.verticalCenter
                        text: linha.modelData.hora === "" ? "dia todo" : linha.modelData.hora
                        tam: 12
                        fraco: true
                        renderType: Text.NativeRendering
                    }
                    Selo { id: selo; x: 80; anchors.verticalCenter: parent.verticalCenter; tipo: linha.modelData.tipo; tam: 28 }
                    Column {
                        anchors { left: selo.right; leftMargin: 11; right: apagar.visible ? apagar.left : parent.right; rightMargin: apagar.visible ? 4 : 16; verticalCenter: parent.verticalCenter }
                        Texto { width: parent.width; text: linha.modelData.titulo; tam: 14; forte: true; renderType: Text.NativeRendering }
                        Texto { width: parent.width; text: linha.modelData.origem; tam: 11; fraco: true; renderType: Text.NativeRendering }
                    }
                    BotaoRedondo {
                        id: apagar
                        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        tam: 24; color: "transparent"
                        visible: linha.modelData.tipo === "evento"
                        icone: "edit-delete-symbolic"
                        corIcone: Tema.textoFraco
                        onClicado: raiz.remover(linha.modelData.id)
                    }
                }
            }
            Row {
                id: entrada
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10 }
                spacing: 6
                PlasmaComponents.TextField {
                    id: hora
                    width: 62
                    placeholderText: "hora"
                    inputMask: ""
                    maximumLength: 5
                    onAccepted: campo.accepted()
                }
                PlasmaComponents.TextField {
                    id: campo
                    width: parent.width - hora.width - mais.width - 12
                    placeholderText: "Novo evento " + (raiz.mesmoDia(raiz.escolhido, raiz.agora) ? "hoje" : "em " + Qt.formatDate(raiz.escolhido, "dd/MM"))
                    onAccepted: {
                        if (raiz.adicionar(text, hora.text.trim())) { text = ""; hora.text = "" }
                        else recusa.restart()
                    }
                }
                BotaoRedondo { id: mais; tam: campo.height; icone: "list-add-symbolic"; onClicado: campo.accepted() }
            }
            SequentialAnimation {
                id: recusa
                loops: 2
                NumberAnimation { target: entrada; property: "anchors.bottomMargin"; to: 14; duration: 60 }
                NumberAnimation { target: entrada; property: "anchors.bottomMargin"; to: 10; duration: 60 }
            }
        }
    }
}
