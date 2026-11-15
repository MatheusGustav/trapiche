import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kquickcontrols as KQC
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import "comp"
import "catalogo.js" as Catalogo
import "util.js" as Util

// Opções da dock e dos widgets que estão nela. Cada mudança vale na hora.
Flickable {
    id: opcoes

    property var naBarra: []
    // Grupos de opções dos widgets que estão na dock, sem repetir: { chave, nome, op }.
    readonly property var grupos: {
        const lista = []
        for (const id of naBarra) {
            const dono = Catalogo.grupo(id)
            const chave = Catalogo.chaveOpcoes(id)
            if (dono && !lista.some(g => g.chave === chave))
                lista.push({ chave: chave, nome: chave === id ? Catalogo.nome(id) : dono.nome, op: dono.op })
        }
        return lista
    }

    function valor(grupo, opcao) { return Util.opcoes(Plasmoid.configuration.opcoes, grupo.chave)[opcao.k] }
    function gravar(grupo, opcao, novo) {
        Plasmoid.configuration.opcoes = Util.gravarOpcao(Plasmoid.configuration.opcoes, grupo.chave, opcao.k, novo)
    }

    contentHeight: coluna.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

    component Titulo: Texto {
        height: 26
        tam: 15
        forte: true
        renderType: Text.NativeRendering
    }
    component Rotulo: Texto {
        tam: 12
        fraco: true
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        renderType: Text.NativeRendering
    }

    Column {
        id: coluna
        width: Math.min(opcoes.width - 14, 480)
        spacing: 18
        bottomPadding: 12

        Column {
            width: parent.width
            spacing: 4

            Titulo { text: "Dock" }
            Rotulo { width: parent.width; text: "Tecla que mostra a dock quando o painel está escondido" }
            KQC.KeySequenceItem {
                keySequence: Plasmoid.globalShortcut
                patterns: KQC.ShortcutPattern.Modifier | KQC.ShortcutPattern.ModifierAndKey
                onCaptureFinished: Plasmoid.globalShortcut = keySequence
            }
        }
        Repeater {
            model: opcoes.grupos

            Column {
                id: bloco
                required property var modelData
                width: coluna.width
                spacing: 8

                Titulo { text: bloco.modelData.nome }
                Repeater {
                    model: bloco.modelData.op

                    Column {
                        id: linha
                        required property var modelData
                        readonly property string tipo: modelData.t
                        readonly property bool numero: tipo === "numero"
                        readonly property bool escrito: tipo === "texto" || tipo === "segredo" || numero
                        width: bloco.width
                        spacing: 3

                        Rotulo { visible: linha.tipo !== "bool"; width: parent.width; text: linha.modelData.r }
                        // O valor entra uma vez, ao abrir; é gravado pouco depois de parar de digitar ou ao sair do campo.
                        PlasmaComponents.TextField {
                            id: campo
                            visible: linha.escrito
                            width: linha.numero ? 120 : parent.width
                            echoMode: linha.tipo === "segredo" ? TextInput.Password : TextInput.Normal
                            validator: linha.numero ? numeros : null
                            inputMethodHints: linha.numero ? Qt.ImhFormattedNumbersOnly : Qt.ImhNone
                            Component.onCompleted: if (linha.escrito) text = opcoes.valor(bloco.modelData, linha.modelData)
                            function guardar() {
                                espera.stop()
                                if (!linha.numero) opcoes.gravar(bloco.modelData, linha.modelData, text)
                                else if (acceptableInput) opcoes.gravar(bloco.modelData, linha.modelData, parseFloat(text))
                            }
                            onTextEdited: espera.restart()
                            onEditingFinished: if (espera.running) guardar()
                        }
                        Timer { id: espera; interval: 600; onTriggered: campo.guardar() }
                        DoubleValidator { id: numeros; bottom: 0; locale: "C"; notation: DoubleValidator.StandardNotation }
                        Loader {
                            width: parent.width
                            active: linha.tipo === "apps"
                            visible: active
                            sourceComponent: EscolhaApps {
                                ids: opcoes.valor(bloco.modelData, linha.modelData)
                                onMudou: novos => opcoes.gravar(bloco.modelData, linha.modelData, novos)
                            }
                        }
                        PlasmaComponents.CheckBox {
                            visible: linha.tipo === "bool"
                            text: linha.modelData.r
                            Component.onCompleted: if (linha.tipo === "bool") checked = opcoes.valor(bloco.modelData, linha.modelData) === true
                            onToggled: opcoes.gravar(bloco.modelData, linha.modelData, checked)
                        }
                    }
                }
            }
        }
    }
}
