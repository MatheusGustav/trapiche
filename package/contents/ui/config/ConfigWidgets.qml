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

    function mover(indice, passo) {
        const destino = indice + passo
        if (destino < 0 || destino >= cfg_widgets.length) return
        const nova = cfg_widgets.slice()
        const item = nova.splice(indice, 1)[0]
        nova.splice(destino, 0, item)
        cfg_widgets = nova
    }
    // Cada widget fica na seção dele; a ordem só muda entre vizinhos da mesma seção.
    function mesmaSecao(indice, passo) {
        const destino = indice + passo
        return destino >= 0 && destino < cfg_widgets.length && Catalogo.secao(cfg_widgets[indice]) === Catalogo.secao(cfg_widgets[destino])
    }
    function remover(indice) { cfg_widgets = cfg_widgets.filter((id, n) => n !== indice) }
    // Um widget que aceita cópias entra como "id", depois "id:2", "id:3"...
    function adicionar(id) {
        let novo = id
        for (let n = 2; cfg_widgets.indexOf(novo) >= 0; n++) novo = id + ":" + n
        cfg_widgets = Catalogo.inserir(cfg_widgets, novo)
    }

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            Kirigami.Heading { Layout.fillWidth: true; level: 3; text: "Na dock (da esquerda para a direita)" }
            QQC2.Button {
                text: "Ordem padrão"
                icon.name: "view-sort"
                onClicked: pagina.cfg_widgets = Catalogo.ordenar(pagina.cfg_widgets)
            }
        }
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
                Layout.fillWidth: true
                QQC2.Label {
                    Layout.fillWidth: true
                    text: Catalogo.nome(ativo.modelData)
                    elide: Text.ElideRight
                }
                QQC2.ToolButton { icon.name: "go-up"; enabled: pagina.mesmaSecao(ativo.index, -1); onClicked: pagina.mover(ativo.index, -1) }
                QQC2.ToolButton { icon.name: "go-down"; enabled: pagina.mesmaSecao(ativo.index, 1); onClicked: pagina.mover(ativo.index, 1) }
                QQC2.ToolButton { icon.name: "list-remove"; onClicked: pagina.remover(ativo.index) }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.largeSpacing }
        Kirigami.Heading { level: 3; text: "Disponíveis" }

        Repeater {
            model: Catalogo.categorias
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
                        readonly property bool usado: !modelData.multi && pagina.cfg_widgets.indexOf(modelData.id) >= 0
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
