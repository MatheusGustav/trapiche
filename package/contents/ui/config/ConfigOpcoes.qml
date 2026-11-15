import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../catalogo.js" as Catalogo

KCM.SimpleKCM {
    id: pagina

    property var cfg_widgets: []
    property string cfg_opcoes
    property string cfg_dados
    property string cfg_testeAbrir

    // Grupos de opções dos widgets que estão na dock, sem repetir.
    readonly property var grupos: {
        const lista = []
        for (const id of cfg_widgets) {
            const grupo = Catalogo.grupo(id)
            if (grupo && lista.indexOf(grupo) < 0) lista.push(grupo)
        }
        return lista
    }

    function valor(grupo, opcao) {
        let salvo = {}
        try { salvo = JSON.parse(cfg_opcoes || "{}")[grupo.id] || {} } catch (e) {}
        return salvo[opcao.k] !== undefined ? salvo[opcao.k] : opcao.p
    }
    function gravar(grupo, opcao, novo) {
        let tudo = {}
        try { tudo = JSON.parse(cfg_opcoes || "{}") } catch (e) {}
        if (!tudo[grupo.id]) tudo[grupo.id] = {}
        tudo[grupo.id][opcao.k] = novo
        cfg_opcoes = JSON.stringify(tudo)
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            visible: pagina.grupos.length === 0
            text: "Os widgets que estão na dock não têm opções."
            opacity: 0.7
        }
        Repeater {
            model: pagina.grupos
            ColumnLayout {
                id: bloco
                required property var modelData
                Layout.fillWidth: true
                Kirigami.Heading { level: 3; text: bloco.modelData.nome }
                Repeater {
                    model: bloco.modelData.op
                    ColumnLayout {
                        id: linha
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2
                        QQC2.Label { visible: linha.modelData.t !== "bool"; text: linha.modelData.r; opacity: 0.8 }
                        QQC2.TextField {
                            visible: linha.modelData.t === "texto" || linha.modelData.t === "segredo"
                            Layout.fillWidth: true
                            echoMode: linha.modelData.t === "segredo" ? TextInput.Password : TextInput.Normal
                            text: visible ? pagina.valor(bloco.modelData, linha.modelData) : ""
                            onTextEdited: pagina.gravar(bloco.modelData, linha.modelData, text)
                        }
                        QQC2.TextField {
                            visible: linha.modelData.t === "numero"
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                            validator: DoubleValidator { bottom: 0; locale: "C"; notation: DoubleValidator.StandardNotation }
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            text: visible ? pagina.valor(bloco.modelData, linha.modelData) : ""
                            onTextEdited: if (acceptableInput) pagina.gravar(bloco.modelData, linha.modelData, parseFloat(text))
                        }
                        QQC2.CheckBox {
                            visible: linha.modelData.t === "bool"
                            text: linha.modelData.r
                            checked: visible && pagina.valor(bloco.modelData, linha.modelData) === true
                            onToggled: pagina.gravar(bloco.modelData, linha.modelData, checked)
                        }
                    }
                }
            }
        }
    }
}
