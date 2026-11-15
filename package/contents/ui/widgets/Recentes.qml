import QtQuick
import "../comp"
import "../dados"

Tile {
    id: raiz
    property var arquivos: []

    clicavel: true
    onClicado: {
        if (!balao.visible) listar()
        balao.alternar()
    }

    function listar() {
        executor.rodar("grep -o '<bookmark href=\"file://[^\"]*\"' \"${XDG_DATA_HOME:-$HOME/.local/share}/recently-used.xbel\" | tail -n 40 | tac", saida => {
            const vistos = {}
            const lista = []
            for (const linha of saida.split("\n")) {
                const achado = /href="([^"]+)"/.exec(linha)
                if (!achado || vistos[achado[1]]) continue
                vistos[achado[1]] = true
                let nome = achado[1].replace(/\/+$/, "").split("/").pop()
                try { nome = decodeURIComponent(nome) } catch (e) {}
                lista.push({ nome: nome, url: achado[1], pasta: false })
                if (lista.length === 8) break
            }
            raiz.arquivos = lista
        })
    }

    Comando { id: executor }

    Rectangle {
        anchors.centerIn: parent
        width: 52; height: 52; radius: 26
        color: Tema.botao
        Icone {
            anchors.centerIn: parent
            source: "document-open-recent-symbolic"
            tam: 24
            cor: Tema.texto
            rotation: balao.visible ? -360 : 0
            Behavior on rotation { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        }
    }

    Balao {
        id: balao
        visualParent: raiz
        larguraConteudo: 380
        alturaConteudo: grade.implicitHeight + 46

        Texto {
            id: titulo
            x: 10; height: 38
            text: "Abertos recentemente"
            tam: 15
            forte: true
            renderType: Text.NativeRendering
        }
        GradeArquivos {
            id: grade
            anchors { left: parent.left; right: parent.right; top: titulo.bottom }
            itens: raiz.arquivos
            mostrar: balao.visible && raiz.arquivos.length > 0
            vazio: "Nenhum arquivo recente"
            onAberto: balao.visible = false
        }
    }
}
