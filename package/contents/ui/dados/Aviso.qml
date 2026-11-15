import QtQuick
import org.kde.notification

// Notificação do sistema.
Notification {
    componentName: "plasma_workspace"
    eventId: "notification"
    iconName: "clock"

    function mostrar(titulo, texto) {
        title = titulo
        text = texto
        sendEvent()
    }
}
