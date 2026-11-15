import QtQuick
import org.kde.plasma.private.mpris as Mpris

// Player de mídia ativo no sistema.
Item {
    id: tocador
    readonly property var player: modelo.currentPlayer
    readonly property bool existe: player !== null && player !== undefined
    readonly property string titulo: existe ? (player.track || player.identity || "") : ""
    readonly property string artista: existe ? (player.artist || "") : ""
    readonly property string capa: existe ? (player.artUrl || "") : ""
    readonly property bool tocando: existe && player.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property real progresso: existe && player.length > 0 ? Math.max(0, Math.min(1, player.position / player.length)) : 0

    function alternar() { if (existe) player.PlayPause() }
    function proxima() { if (existe) player.Next() }

    Mpris.Mpris2Model { id: modelo }
    Timer {
        interval: 1000
        running: tocador.tocando
        repeat: true
        onTriggered: tocador.player.updatePosition()
    }
}
