import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../comp"
import "../dados"

Tile {
    id: raiz
    property string resposta: ""
    property int estado: 0          // 0 parado, 1 rodando, 2 deu certo, 3 falhou

    largura: 290
    clicavel: !campo.activeFocus
    onClicado: campo.forceActiveFocus()

    function executar() {
        const texto = campo.text.trim()
        if (texto === "") return
        estado = 1
        executor.rodar(texto, (saida, codigo, erro) => {
            raiz.estado = codigo === 0 ? 2 : 3
            raiz.resposta = ((codigo === 0 ? saida : (erro || saida)).trim().split("\n")[0] || (codigo === 0 ? "feito" : "erro " + codigo))
            campo.text = ""
        })
    }

    Comando { id: executor }

    // O painel só recebe teclado enquanto o plasmoide pede.
    Binding {
        target: Plasmoid
        property: "status"
        value: PlasmaCore.Types.AcceptingInputStatus
        when: campo.activeFocus
        restoreMode: Binding.RestoreBindingOrValue
    }

    Texto {
        id: seta
        anchors { left: parent.left; leftMargin: 17; verticalCenter: parent.verticalCenter }
        text: "›"
        tam: 20
        forte: true
        color: raiz.estado === 3 ? Tema.vermelho : Tema.verde
        SequentialAnimation on opacity {
            running: raiz.estado === 1
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { to: 0.2; duration: 350 }
            NumberAnimation { to: 1; duration: 350 }
        }
    }
    TextInput {
        id: campo
        anchors { left: seta.right; leftMargin: 10; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        color: Tema.texto
        selectionColor: Tema.azul
        font.family: "monospace"
        font.pixelSize: 13
        renderType: Text.QtRendering
        clip: true
        selectByMouse: true
        onAccepted: raiz.executar()
        Keys.onEscapePressed: { text = ""; focus = false }
        onTextEdited: raiz.estado = 0
    }
    Texto {
        anchors.fill: campo
        visible: campo.text === "" && !campo.activeFocus
        text: raiz.estado >= 2 ? raiz.resposta : "comando"
        font.family: "monospace"
        tam: 13
        fraco: true
    }
}
