import QtQuick
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami
import "../comp"
import "../util.js" as Util

Tile {
    id: raiz
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "apps")

    largura: Math.max(77, 14 + lista.count * 50)
    semFundo: true

    TaskManager.TasksModel {
        id: tarefas
        groupMode: TaskManager.TasksModel.GroupApplications
        sortMode: TaskManager.TasksModel.SortManual
        launchInPlace: true
        separateLaunchers: false
        filterByVirtualDesktop: false
        filterByActivity: false
        filterByScreen: false
        launcherList: raiz.op.fixados.split(",").map(t => t.trim()).filter(t => t !== "")
    }

    Row {
        anchors.centerIn: parent
        Repeater {
            id: lista
            model: tarefas

            Item {
                id: app
                required property int index
                required property var model
                readonly property bool aberto: model.IsWindow === true || model.IsGroupParent === true
                readonly property bool ativo: model.IsActive === true

                width: 50; height: 77

                Kirigami.Icon {
                    id: icone
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: (toque.containsMouse ? 8 : 14) + salto
                    width: 42; height: 42
                    source: app.model.decoration
                    scale: toque.pressed ? 0.88 : (toque.containsMouse ? 1.18 : 1)
                    property real salto: 0
                    Behavior on scale { SpringAnimation { spring: 5; damping: 0.35; mass: 0.5 } }
                    Behavior on y { enabled: !pulo.running; SpringAnimation { spring: 5; damping: 0.4; mass: 0.5 } }

                    SequentialAnimation {
                        id: pulo
                        loops: 2
                        NumberAnimation { target: icone; property: "salto"; to: -14; duration: 190; easing.type: Easing.OutQuad }
                        NumberAnimation { target: icone; property: "salto"; to: 0; duration: 260; easing.type: Easing.OutBounce }
                    }
                }
                Rectangle {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
                    height: 4; radius: 2
                    width: app.ativo ? 16 : 4
                    color: app.model.IsDemandingAttention === true ? Tema.laranja : Tema.azul
                    opacity: app.aberto ? 1 : 0
                    Behavior on width { NumberAnimation { duration: Tema.normal; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: Tema.normal } }
                }
                MouseArea {
                    id: toque
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: mouse => {
                        const indice = tarefas.makeModelIndex(app.index)
                        if (mouse.button === Qt.MiddleButton || !app.aberto) {
                            pulo.restart()
                            tarefas.requestNewInstance(indice)
                        } else if (app.ativo) {
                            tarefas.requestToggleMinimized(indice)
                        } else {
                            tarefas.requestActivate(indice)
                        }
                    }
                }
            }
        }
    }
}
