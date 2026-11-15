import QtQuick
import org.kde.plasma.plasma5support as P5Support

// Roda um comando de terminal e devolve a saída em retorno(stdout, codigo, stderr).
P5Support.DataSource {
    id: fonte
    property var pendentes: ({})
    property int sequencia: 0

    engine: "executable"
    connectedSources: []

    function rodar(comando, retorno) {
        const chave = comando + " #" + (++sequencia)
        pendentes[chave] = retorno
        connectSource(chave)
    }

    onNewData: (origem, dados) => {
        const retorno = pendentes[origem]
        delete pendentes[origem]
        disconnectSource(origem)
        if (retorno)
            retorno(dados["stdout"] || "", dados["exit code"], dados["stderr"] || "")
    }
}
