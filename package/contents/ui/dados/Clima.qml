import QtQuick
import org.kde.plasma.plasmoid
import "../util.js" as Util

// Tempo e previsão da cidade configurada, vindos do Open-Meteo.
Item {
    id: clima
    readonly property var op: Util.opcoes(Plasmoid.configuration.opcoes, "clima")
    readonly property string cidade: op.cidade.trim()
    property var local: null            // { nome, lat, lon }
    readonly property var dados: previsao.dados
    readonly property bool pronto: dados !== null && dados.current !== undefined
    readonly property string aviso: cidade === "" ? "Defina a cidade"
        : (busca.erro !== "" || previsao.erro !== "") ? "Sem conexão"
        : (busca.dados !== null && local === null) ? "Cidade não encontrada"
        : !pronto ? "Carregando" : ""

    onCidadeChanged: local = null

    Http {
        id: busca
        url: clima.cidade === "" ? "" : "https://geocoding-api.open-meteo.com/v1/search?count=1&language=pt&name=" + encodeURIComponent(clima.cidade)
        intervalo: 86400000
        onRecebido: resposta => {
            const achado = resposta.results && resposta.results[0]
            clima.local = achado ? { nome: achado.name, lat: achado.latitude, lon: achado.longitude } : null
        }
    }
    Http {
        id: previsao
        url: clima.local === null ? "" : "https://api.open-meteo.com/v1/forecast?latitude=" + clima.local.lat + "&longitude=" + clima.local.lon
            + "&current=temperature_2m,weather_code,is_day&hourly=temperature_2m,weather_code,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset&timezone=auto&forecast_days=4&forecast_hours=6"
        intervalo: 900000
    }
}
