import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../dados"
import "../util.js" as Util

// Escolha dos aplicativos de uma pasta: os escolhidos (com ordem) e uma busca entre os instalados.
ColumnLayout {
    id: escolha
    property var ids: []            // ids escolhidos, na ordem
    property var instalados: []     // { id, nome, icone }
    signal mudou(var ids)

    readonly property var resultados: {
        const termo = busca.text.trim().toLowerCase()
        return instalados.filter(app => ids.indexOf(app.id) < 0 && (termo === "" || app.nome.toLowerCase().indexOf(termo) >= 0)).slice(0, 8)
    }

    function app(id) { return instalados.find(a => a.id === id) || { id: id, nome: id, icone: "unknown" } }
    function mover(indice, passo) {
        const destino = indice + passo
        if (destino < 0 || destino >= ids.length) return
        const nova = ids.slice()
        nova.splice(destino, 0, nova.splice(indice, 1)[0])
        mudou(nova)
    }

    spacing: 2

    Comando { id: executor }
    Component.onCompleted: executor.rodar("python3 " + Util.script(Qt.resolvedUrl("."), "apps.py") + " " + Util.aspas('{"acao":"listar"}'), saida => {
        try { escolha.instalados = JSON.parse(saida) } catch (e) { escolha.instalados = [] }
    })

    Repeater {
        model: escolha.ids
        RowLayout {
            id: escolhido
            required property string modelData
            required property int index
            readonly property var dados: escolha.app(modelData)
            Layout.fillWidth: true
            Kirigami.Icon { source: escolhido.dados.icone; implicitWidth: Kirigami.Units.iconSizes.smallMedium; implicitHeight: Kirigami.Units.iconSizes.smallMedium }
            QQC2.Label { Layout.fillWidth: true; text: escolhido.dados.nome; elide: Text.ElideRight }
            QQC2.ToolButton { icon.name: "go-up"; enabled: escolhido.index > 0; onClicked: escolha.mover(escolhido.index, -1) }
            QQC2.ToolButton { icon.name: "go-down"; enabled: escolhido.index < escolha.ids.length - 1; onClicked: escolha.mover(escolhido.index, 1) }
            QQC2.ToolButton { icon.name: "list-remove"; onClicked: escolha.mudou(escolha.ids.filter((id, n) => n !== escolhido.index)) }
        }
    }
    QQC2.TextField {
        id: busca
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        placeholderText: "Buscar aplicativo para adicionar"
    }
    Repeater {
        model: escolha.resultados
        RowLayout {
            id: resultado
            required property var modelData
            Layout.fillWidth: true
            Kirigami.Icon { source: resultado.modelData.icone; implicitWidth: Kirigami.Units.iconSizes.smallMedium; implicitHeight: Kirigami.Units.iconSizes.smallMedium }
            QQC2.Label { Layout.fillWidth: true; text: resultado.modelData.nome; elide: Text.ElideRight; opacity: 0.8 }
            QQC2.ToolButton { icon.name: "list-add"; onClicked: escolha.mudou(escolha.ids.concat([resultado.modelData.id])) }
        }
    }
}
