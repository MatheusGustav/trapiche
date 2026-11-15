import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "Widgets"
        icon: "view-list-icons"
        source: "config/ConfigWidgets.qml"
    }
    ConfigCategory {
        name: "Opções"
        icon: "configure"
        source: "config/ConfigOpcoes.qml"
    }
}
