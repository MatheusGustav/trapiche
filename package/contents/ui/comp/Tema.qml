pragma Singleton
import QtQuick
import org.kde.kirigami as Kirigami

QtObject {
    readonly property bool escuro: Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Dark

    readonly property color tile: escuro ? "#d01d1d21" : "#d9ffffff"
    readonly property color borda: escuro ? "#22ffffff" : "#1a000000"
    readonly property color brilho: escuro ? "#14ffffff" : "#66ffffff"
    readonly property color texto: escuro ? "#f5f5f7" : "#1c1c1e"
    readonly property color textoFraco: escuro ? "#9c9ca6" : "#6b6b74"
    readonly property color trilho: escuro ? "#30ffffff" : "#1f000000"
    readonly property color botao: escuro ? "#26ffffff" : "#14000000"

    readonly property color azul: Kirigami.Theme.highlightColor
    readonly property color verde: "#2fd46b"
    readonly property color vermelho: "#ff5247"
    readonly property color laranja: "#ff9d2e"
    readonly property color amarelo: "#ffd23f"
    readonly property color roxo: "#a56bff"
    readonly property color ciano: "#35c8e0"

    readonly property int rapido: 160
    readonly property int normal: 320
    readonly property int lento: 700
}
