import QtQuick
import "../comp"
import org.kde.plasma.private.battery as BateriaSistema

// Estado da bateria do aparelho.
Item {
    readonly property bool existe: modelo.hasBatteries
    readonly property int porcento: modelo.percent
    readonly property bool naTomada: modelo.pluggedIn
    readonly property bool carregando: modelo.state === BateriaSistema.BatteryControlModel.Charging
    readonly property bool baixa: existe && porcento <= 20 && !naTomada
    readonly property real restanteMs: modelo.smoothedRemainingMsec
    readonly property color cor: baixa ? Tema.vermelho : (porcento <= 40 && !naTomada ? Tema.laranja : Tema.verde)

    BateriaSistema.BatteryControlModel { id: modelo }
}
