import QtQuick

// Busca JSON por HTTP de tempos em tempos.
Item {
    id: http
    property string url
    property var cabecalhos: ({})
    property int intervalo: 600000
    property bool ativo: true
    property var dados: null
    property string erro: ""
    property bool carregando: false
    property bool pronto: false
    signal recebido(var dados)

    function buscar() {
        if (url === "") return
        const pedido = new XMLHttpRequest()
        const alvo = url
        carregando = true
        pedido.onreadystatechange = () => {
            if (!http || pedido.readyState !== XMLHttpRequest.DONE || alvo !== http.url) return
            carregando = false
            if (pedido.status >= 200 && pedido.status < 300) {
                try {
                    http.dados = JSON.parse(pedido.responseText)
                    http.erro = ""
                    http.recebido(http.dados)
                } catch (e) {
                    http.erro = "resposta inválida"
                }
            } else {
                http.erro = pedido.status ? "erro " + pedido.status : "sem conexão"
            }
        }
        pedido.open("GET", url)
        for (const nome in cabecalhos)
            pedido.setRequestHeader(nome, cabecalhos[nome])
        pedido.send()
    }

    onUrlChanged: if (pronto) relogio.restart()
    Component.onCompleted: pronto = true

    Timer {
        id: relogio
        interval: http.intervalo
        running: http.ativo && http.url !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: http.buscar()
    }
}
