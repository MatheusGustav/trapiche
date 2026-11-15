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

    readonly property var categorias: {
        const nomes = []
        for (const item of Catalogo.itens)
            if (nomes.indexOf(item.cat) < 0) nomes.push(item.cat)
        return nomes
    }

    function mover(indice, passo) {
        const destino = indice + passo
        if (destino < 0 || destino >= cfg_widgets.length) return
        const nova = cfg_widgets.slice()
        const item = nova.splice(indice, 1)[0]
        nova.splice(destino, 0, item)
        cfg_widgets = nova
    }
    function remover(indice) { cfg_widgets = cfg_widgets.filter((id, n) => n !== indice) }
    function adicionar(id) { cfg_widgets = cfg_widgets.concat([id]) }

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading { level: 3; text: "Na dock (da esquerda para a direita)" }
        QQC2.Label {
            visible: pagina.cfg_widgets.length === 0
            text: "Nenhum widget. Adicione na lista abaixo."
            opacity: 0.7
        }
        Repeater {
            model: pagina.cfg_widgets
            RowLayout {
                id: ativo
                required property string modelData
                required property int index
                readonly property var registro: Catalogo.achar(modelData)
                Layout.fillWidth: true
                QQC2.Label {
                    Layout.fillWidth: true
                    text: ativo.registro ? ativo.registro.nome : ativo.modelData + " (não existe mais)"
                    elide: Text.ElideRight
                }
                QQC2.ToolButton { icon.name: "go-up"; enabled: ativo.index > 0; onClicked: pagina.mover(ativo.index, -1) }
                QQC2.ToolButton { icon.name: "go-down"; enabled: ativo.index < pagina.cfg_widgets.length - 1; onClicked: pagina.mover(ativo.index, 1) }
                QQC2.ToolButton { icon.name: "list-remove"; onClicked: pagina.remover(ativo.index) }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.largeSpacing }
        Kirigami.Heading { level: 3; text: "Disponíveis" }

        Repeater {
            model: pagina.categorias
            ColumnLayout {
                id: bloco
                required property string modelData
                Layout.fillWidth: true
                spacing: 0
                QQC2.Label {
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    text: bloco.modelData
                    font.bold: true
                    opacity: 0.7
                }
                Repeater {
                    model: Catalogo.itens.filter(item => item.cat === bloco.modelData)
                    RowLayout {
                        id: opcao
                        required property var modelData
                        readonly property bool usado: pagina.cfg_widgets.indexOf(modelData.id) >= 0
                        Layout.fillWidth: true
                        QQC2.Label { Layout.fillWidth: true; text: opcao.modelData.nome; elide: Text.ElideRight; opacity: opcao.usado ? 0.5 : 1 }
                        QQC2.ToolButton {
                            icon.name: "list-add"
                            enabled: !opcao.usado
                            onClicked: pagina.adicionar(opcao.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
