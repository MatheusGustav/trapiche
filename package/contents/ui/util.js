.pragma library
.import "catalogo.js" as Catalogo

// Opções de um widget (ou de uma cópia dele, "base:2"): o que foi salvo, completado com o padrão do catálogo.
function opcoes(json, id) {
    let salvo = {}
    try { salvo = JSON.parse(json || "{}")[id] || {} } catch (e) {}
    const item = Catalogo.achar(id)
    const resultado = {}
    if (item && item.op) {
        for (const o of item.op)
            resultado[o.k] = (salvo[o.k] !== undefined && salvo[o.k] !== "") ? salvo[o.k] : o.p
    }
    return resultado
}

function ler(json, chave, padrao) {
    try {
        const valor = JSON.parse(json || "{}")[chave]
        return valor === undefined ? padrao : valor
    } catch (e) {
        return padrao
    }
}

function gravar(json, chave, valor) {
    let tudo = {}
    try { tudo = JSON.parse(json || "{}") } catch (e) {}
    tudo[chave] = valor
    return JSON.stringify(tudo)
}

// Grava uma opção de um widget, mantendo as outras.
function gravarOpcao(json, id, chave, valor) {
    let tudo = {}
    try { tudo = JSON.parse(json || "{}") } catch (e) {}
    tudo[id] = Object.assign({}, tudo[id], { [chave]: valor })
    return JSON.stringify(tudo)
}

// Hora como o relógio mostra: 0 a 23, ou 1 a 12 no formato de 12 horas.
function horaDoRelogio(data, h24) {
    return h24 ? data.getHours() : (data.getHours() % 12 || 12)
}

function dois(n) {
    return (n < 10 ? "0" : "") + Math.floor(n)
}

// 21700 -> "21,7 mil"; 3100000 -> "3,1 mi"
function compacto(n) {
    if (n === null || n === undefined || isNaN(n)) return "–"
    const abs = Math.abs(n)
    const um = v => (Math.round(v * 10) / 10).toString().replace(".", ",")
    if (abs >= 1e9) return um(n / 1e9) + " bi"
    if (abs >= 1e6) return um(n / 1e6) + " mi"
    if (abs >= 1e4) return um(n / 1e3) + " mil"
    return Math.round(n).toLocaleString(Qt.locale("pt_BR"), "f", 0)
}

// 8040 s -> "2h 14m"
function duracao(segundos) {
    const s = Math.max(0, Math.round(segundos))
    const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60)
    if (h > 0) return h + "h " + dois(m) + "m"
    if (m > 0) return m + "m"
    return s + "s"
}

// 1500 s -> "25:00"; 3723 s -> "1:02:03"
function cronometro(segundos) {
    const s = Math.max(0, Math.floor(segundos))
    const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), r = s % 60
    return h > 0 ? h + ":" + dois(m) + ":" + dois(r) : m + ":" + dois(r)
}

function bytes(b) {
    if (b === null || b === undefined || isNaN(b)) return "–"
    const unidades = ["B", "KB", "MB", "GB", "TB"]
    let i = 0
    let v = b
    while (v >= 1024 && i < unidades.length - 1) { v /= 1024; i++ }
    const casas = v >= 100 || i === 0 ? 0 : 1
    return v.toFixed(casas).replace(".", ",") + " " + unidades[i]
}

// Coloca um texto entre aspas simples para uso em comando de terminal.
function aspas(texto) {
    return "'" + String(texto).replace(/'/g, "'\\''") + "'"
}

function iconeArquivo(nome, pasta) {
    if (pasta) return "folder"
    const ponto = nome.lastIndexOf(".")
    const ext = ponto > 0 ? nome.slice(ponto + 1).toLowerCase() : ""
    const mapa = {
        pdf: "application-pdf",
        zip: "application-zip", rar: "application-zip", "7z": "application-zip", gz: "application-zip", xz: "application-zip", tar: "application-zip",
        png: "image-x-generic", jpg: "image-x-generic", jpeg: "image-x-generic", gif: "image-x-generic", webp: "image-x-generic", svg: "image-x-generic",
        mp4: "video-x-generic", mkv: "video-x-generic", webm: "video-x-generic", mov: "video-x-generic", avi: "video-x-generic",
        mp3: "audio-x-generic", ogg: "audio-x-generic", opus: "audio-x-generic", wav: "audio-x-generic", flac: "audio-x-generic", m4a: "audio-x-generic",
        doc: "x-office-document", docx: "x-office-document", odt: "x-office-document",
        xls: "x-office-spreadsheet", xlsx: "x-office-spreadsheet", ods: "x-office-spreadsheet", csv: "text-csv",
        ppt: "x-office-presentation", pptx: "x-office-presentation", odp: "x-office-presentation",
        html: "text-html", json: "application-json", md: "text-markdown", py: "text-x-python", sh: "application-x-shellscript",
        js: "text-x-script", ts: "text-x-script", php: "text-x-script", qml: "text-x-script",
        rpm: "application-x-rpm", iso: "application-x-cd-image", appimage: "application-x-executable",
        txt: "text-x-generic", log: "text-x-generic"
    }
    return mapa[ext] || "unknown"
}

function ehImagem(nome) {
    return /\.(png|jpe?g|gif|webp)$/i.test(nome)
}

// Códigos de tempo da OMM (usados pelo Open-Meteo).
function climaDescricao(codigo) {
    if (codigo === 0) return "Céu limpo"
    if (codigo === 1) return "Quase limpo"
    if (codigo === 2) return "Parcialmente nublado"
    if (codigo === 3) return "Nublado"
    if (codigo === 45 || codigo === 48) return "Neblina"
    if (codigo >= 51 && codigo <= 57) return "Garoa"
    if (codigo >= 61 && codigo <= 67) return "Chuva"
    if (codigo >= 71 && codigo <= 77) return "Neve"
    if (codigo >= 80 && codigo <= 82) return "Pancadas de chuva"
    if (codigo === 85 || codigo === 86) return "Pancadas de neve"
    if (codigo >= 95) return "Trovoada"
    return "–"
}

function climaIcone(codigo, dia) {
    if (codigo === 0 || codigo === 1) return dia ? "weather-clear" : "weather-clear-night"
    if (codigo === 2) return dia ? "weather-few-clouds" : "weather-few-clouds-night"
    if (codigo === 3) return "weather-overcast"
    if (codigo === 45 || codigo === 48) return "weather-fog"
    if (codigo >= 51 && codigo <= 57) return "weather-showers-scattered"
    if (codigo >= 61 && codigo <= 67) return "weather-showers"
    if ((codigo >= 71 && codigo <= 77) || codigo === 85 || codigo === 86) return "weather-snow"
    if (codigo >= 80 && codigo <= 82) return "weather-showers"
    if (codigo >= 95) return "weather-storm"
    return "weather-none-available"
}

// 1234.5 -> "1.234,50"
function numero(valor, casas) {
    if (valor === null || valor === undefined || isNaN(valor)) return "–"
    return Number(valor).toLocaleString(Qt.locale("pt_BR"), "f", casas === undefined ? 2 : casas)
}

// 2.41 -> "▲ 2,41%"
function variacao(porcento) {
    if (porcento === null || porcento === undefined || isNaN(porcento)) return ""
    return (porcento >= 0 ? "▲ " : "▼ ") + Math.abs(porcento).toFixed(2).replace(".", ",") + "%"
}

// "claude-opus-5-5" -> "Opus 5.5"; "deepseek-v4-pro" -> "Deepseek v4 pro"
function nomeModelo(id) {
    if (!id) return "–"
    let nome = id.replace(/^claude-/, "").replace(/-\d{8}$/, "")
    nome = nome.replace(/(\d)-(\d)/g, "$1.$2").replace(/-/g, " ")
    return nome.charAt(0).toUpperCase() + nome.slice(1)
}

// Caminho de um script do pacote, pronto para o terminal. "base" é Qt.resolvedUrl(".") de um arquivo em ui/<pasta>/.
function script(base, nome) {
    return aspas(decodeURIComponent(String(base).replace(/^file:\/\//, "")) + "../../code/" + nome)
}
