import QtQuick

// Roda um comando de tempos em tempos e guarda a última saída.
Item {
    id: periodico
    property string comando
    property int intervalo: 5000
    property bool ativo: true
    property string saida: ""
    signal atualizado(string saida)

    function agora() {
        if (comando === "") return
        executor.rodar(comando, (texto, codigo) => {
            periodico.saida = texto
            periodico.atualizado(texto)
        })
    }

    Comando { id: executor }
    Timer {
        interval: periodico.intervalo
        running: periodico.ativo && periodico.comando !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: periodico.agora()
    }
}
