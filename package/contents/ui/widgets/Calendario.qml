import QtQuick
import "../comp"

Tile {
    id: raiz
    property date hoje: new Date()
    property date mes: new Date(hoje.getFullYear(), hoje.getMonth(), 1)
    readonly property var local: Qt.locale("pt_BR")
    readonly property var dias: {
        const primeiro = new Date(mes.getFullYear(), mes.getMonth(), 1)
        const total = new Date(mes.getFullYear(), mes.getMonth() + 1, 0).getDate()
        const lista = []
        for (let i = 0; i < primeiro.getDay(); i++) lista.push(0)
        for (let d = 1; d <= total; d++) lista.push(d)
        return lista
    }

    largura: 236
    clicavel: true
    onClicado: {
        mes = new Date(hoje.getFullYear(), hoje.getMonth(), 1)
        balao.alternar()
    }

    function mudarMes(passo) {
        troca.direcao = passo
        troca.restart()
    }

    Timer { interval: 60000; running: true; repeat: true; onTriggered: raiz.hoje = new Date() }

    Rectangle {
        id: bloco
        anchors { left: parent.left; leftMargin: 11; verticalCenter: parent.verticalCenter }
        width: 55; height: 55; radius: 14
        color: Tema.botao
        Texto {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 7 }
            text: raiz.hoje.toLocaleDateString(raiz.local, "ddd").replace(".", "").toUpperCase()
            tam: 10
            forte: true
            color: Tema.vermelho
        }
        Texto {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 }
            text: raiz.hoje.getDate()
            tam: 25
            forte: true
        }
    }
    Column {
        anchors { left: bloco.right; leftMargin: 13; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 2
        Texto { width: parent.width; text: raiz.hoje.toLocaleDateString(raiz.local, "dddd"); tam: 15; forte: true; font.capitalization: Font.Capitalize }
        Texto { width: parent.width; text: raiz.hoje.toLocaleDateString(raiz.local, "d 'de' MMMM 'de' yyyy"); tam: 12; fraco: true }
    }

    Balao {
        id: balao
        visualParent: raiz
        larguraConteudo: 280
        alturaConteudo: 44 + 22 + Math.ceil(raiz.dias.length / 7) * 34 + 8

        Item {
            id: topo
            width: parent.width; height: 40
            Texto {
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                text: raiz.mes.toLocaleDateString(raiz.local, "MMMM yyyy")
                tam: 15
                forte: true
                font.capitalization: Font.Capitalize
                renderType: Text.NativeRendering
            }
            BotaoRedondo {
                anchors { right: avancar.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                tam: 28; icone: "go-previous-symbolic"
                onClicado: raiz.mudarMes(-1)
            }
            BotaoRedondo {
                id: avancar
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                tam: 28; icone: "go-next-symbolic"
                onClicado: raiz.mudarMes(1)
            }
        }
        Row {
            id: semana
            anchors.top: topo.bottom
            Repeater {
                model: ["D", "S", "T", "Q", "Q", "S", "S"]
                Texto {
                    required property string modelData
                    width: 40; height: 22
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData; tam: 11; forte: true; fraco: true
                    renderType: Text.NativeRendering
                }
            }
        }
        Grid {
            id: grade
            anchors.top: semana.bottom
            columns: 7
            property real desloc: 0
            transform: Translate { x: grade.desloc }
            Repeater {
                model: raiz.dias
                Item {
                    required property int modelData
                    readonly property bool ehHoje: modelData === raiz.hoje.getDate()
                        && raiz.mes.getMonth() === raiz.hoje.getMonth() && raiz.mes.getFullYear() === raiz.hoje.getFullYear()
                    width: 40; height: 34
                    Rectangle {
                        anchors.centerIn: parent
                        width: 28; height: 28; radius: 14
                        color: parent.ehHoje ? Tema.vermelho : "transparent"
                    }
                    Texto {
                        anchors.centerIn: parent
                        visible: modelData > 0
                        text: modelData
                        tam: 13
                        forte: parent.ehHoje
                        color: parent.ehHoje ? "white" : Tema.texto
                        renderType: Text.NativeRendering
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
    }
}
