import QtQuick
import org.kde.kirigami as Kirigami

// Ícone do tema do sistema. Com "cor" definida, é pintado como máscara de uma cor só.
Kirigami.Icon {
    property real tam: 20
    property color cor: "transparent"

    width: tam
    height: tam
    isMask: cor.a > 0
    color: cor.a > 0 ? cor : Kirigami.Theme.textColor
}
