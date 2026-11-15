.pragma library

// Cada widget: id, nome, categoria, arquivo em widgets/ e opções (k chave, r rótulo, t tipo, p padrão).
// Com "multi", o widget pode entrar mais de uma vez na dock; as cópias têm id "base:2", "base:3"...
var itens = [
    { id: "apps", nome: "Aplicativos", cat: "Aplicativos e pastas", arq: "Apps.qml",
      op: [{ k: "fixados", r: "Fixados (separados por vírgula)", t: "texto", p: "preferred://filemanager,preferred://browser" }] },
    { id: "grupo-apps", nome: "Pasta de aplicativos", cat: "Aplicativos e pastas", arq: "GrupoApps.qml", multi: true,
      op: [{ k: "nome", r: "Nome da pasta", t: "texto", p: "Aplicativos" },
           { k: "apps", r: "Aplicativos", t: "apps", p: [] }] },
    { id: "pasta", nome: "Pasta", cat: "Aplicativos e pastas", arq: "Pasta.qml",
      op: [{ k: "caminho", r: "Caminho da pasta (vazio = Downloads)", t: "texto", p: "" }] },
    { id: "recentes", nome: "Abertos recentemente", cat: "Aplicativos e pastas", arq: "Recentes.qml" },
    { id: "lixeira", nome: "Lixeira", cat: "Aplicativos e pastas", arq: "Lixeira.qml" },
    { id: "comandos", nome: "Comandos", cat: "Aplicativos e pastas", arq: "Comandos.qml" },
    { id: "cpu", nome: "CPU", cat: "Sistema", arq: "Cpu.qml" },
    { id: "ram", nome: "Memória", cat: "Sistema", arq: "Ram.qml" },
    { id: "top-cpu", nome: "Maiores usos de CPU", cat: "Sistema", arq: "TopCpu.qml" },
    { id: "top-ram", nome: "Maiores usos de memória", cat: "Sistema", arq: "TopRam.qml" },
    { id: "temperatura", nome: "Temperatura", cat: "Sistema", arq: "Temperatura.qml" },
    { id: "rede", nome: "Rede", cat: "Sistema", arq: "Rede.qml" },
    { id: "armazenamento", nome: "Armazenamento", cat: "Sistema", arq: "Armazenamento.qml" },
    { id: "bateria-anel", nome: "Bateria (anel)", cat: "Sistema", arq: "BateriaAnel.qml" },
    { id: "bateria-nucleo", nome: "Bateria (núcleo)", cat: "Sistema", arq: "BateriaNucleo.qml" },
    { id: "bateria-medidor", nome: "Bateria (medidor)", cat: "Sistema", arq: "BateriaMedidor.qml" },
    { id: "bateria-pontos", nome: "Bateria (pontos)", cat: "Sistema", arq: "BateriaPontos.qml" },
    { id: "brilho", nome: "Brilho", cat: "Sistema", arq: "Brilho.qml" },
    { id: "saida-audio", nome: "Saída de áudio", cat: "Sistema", arq: "SaidaAudio.qml" },
    { id: "microfone", nome: "Microfone", cat: "Sistema", arq: "Microfone.qml" },
    { id: "alternadores", nome: "Wi-Fi, Bluetooth e modo avião", cat: "Sistema", arq: "Alternadores.qml" },
    { id: "nao-perturbe", nome: "Não perturbe", cat: "Sistema", arq: "NaoPerturbe.qml" },
    { id: "tocando", nome: "Tocando agora", cat: "Mídia", arq: "Tocando.qml" },
    { id: "tocando-barra", nome: "Tocando agora (com progresso)", cat: "Mídia", arq: "TocandoBarra.qml" },
    { id: "tempo-de-tela", nome: "Tempo de tela", cat: "Produtividade", arq: "TempoDeTela.qml" },
    { id: "linha-do-dia", nome: "Linha do dia", cat: "Produtividade", arq: "LinhaDoDia.qml" },
    { id: "calendario", nome: "Calendário", cat: "Data e hora", arq: "Calendario.qml" },
    { id: "tarefas", nome: "Tarefas", cat: "Produtividade", arq: "Tarefas.qml" },
    { id: "notas", nome: "Notas", cat: "Produtividade", arq: "Notas.qml" },
    { id: "pomodoro", nome: "Pomodoro", cat: "Produtividade", arq: "Pomodoro.qml",
      op: [{ k: "foco", r: "Minutos de foco", t: "numero", p: 25 },
           { k: "pausa", r: "Minutos de pausa", t: "numero", p: 5 },
           { k: "pausaLonga", r: "Minutos da pausa longa", t: "numero", p: 15 }] },
    { id: "timer", nome: "Timer", cat: "Produtividade", arq: "Timer.qml",
      op: [{ k: "minutos", r: "Minutos", t: "numero", p: 1 }] },
    { id: "cronometro", nome: "Cronômetro", cat: "Produtividade", arq: "Cronometro.qml" },
    { id: "relogio-flip", nome: "Relógio de fichas", cat: "Data e hora", arq: "RelogioFlip.qml",
      op: [{ k: "h24", r: "Formato 24 horas", t: "bool", p: true }] },
    { id: "relogio-analogico", nome: "Relógio analógico", cat: "Data e hora", arq: "RelogioAnalogico.qml" },
    { id: "relogios-mundo", nome: "Relógios do mundo", cat: "Data e hora", arq: "RelogiosMundo.qml",
      op: [{ k: "cidades", r: "Cidades (SIGLA:Fuso, separadas por vírgula)", t: "texto",
             p: "NYC:America/New_York,LON:Europe/London,TYO:Asia/Tokyo" }] },
    { id: "nascer-por-do-sol", nome: "Nascer e pôr do sol", cat: "Clima", arq: "NascerPorDoSol.qml", opDe: "clima" },
    { id: "clima", nome: "Clima", cat: "Clima", arq: "Clima.qml",
      op: [{ k: "cidade", r: "Cidade", t: "texto", p: "" }] },
    { id: "clima-status", nome: "Clima (cartão)", cat: "Clima", arq: "ClimaStatus.qml", opDe: "clima" },
    { id: "clima-hoje-previsao", nome: "Hoje e previsão", cat: "Clima", arq: "ClimaHojePrevisao.qml", opDe: "clima" },
    { id: "clima-horas", nome: "Previsão por hora", cat: "Clima", arq: "ClimaHoras.qml", opDe: "clima" },
    { id: "cripto", nome: "Criptomoeda", cat: "Mercado", arq: "Cripto.qml",
      op: [{ k: "par", r: "Par na Binance (ex.: BTCUSDT)", t: "texto", p: "BTCUSDT" }] },
    { id: "moeda", nome: "Câmbio", cat: "Mercado", arq: "Moeda.qml",
      op: [{ k: "valor", r: "Valor", t: "numero", p: 1 },
           { k: "de", r: "De (código da moeda)", t: "texto", p: "USD" },
           { k: "para", r: "Para (código da moeda)", t: "texto", p: "BRL" }] },
    { id: "acoes", nome: "Ações", cat: "Mercado", arq: "Acoes.qml",
      op: [{ k: "simbolos", r: "Símbolos do Yahoo Finance (até 3, separados por vírgula)", t: "texto", p: "AAPL,PETR4.SA,^BVSP" }] },
    { id: "claude-plano", nome: "Claude Code (plano)", cat: "IA", arq: "ClaudePlano.qml" },
    { id: "claude-uso", nome: "Claude Code (sessão)", cat: "IA", arq: "ClaudeUso.qml" },
    { id: "github-atividade", nome: "GitHub (atividade)", cat: "Desenvolvimento", arq: "GitHubAtividade.qml" },
    { id: "github-visao", nome: "GitHub (visão geral)", cat: "Desenvolvimento", arq: "GitHubVisao.qml" },
    { id: "github", nome: "GitHub (não lidas)", cat: "Desenvolvimento", arq: "GitHubNaoLidas.qml" }
]

// Categorias na ordem padrão da dock, da esquerda para a direita: aplicativos primeiro, data e hora no fim.
var categorias = ["Aplicativos e pastas", "Mídia", "Clima", "Mercado", "IA", "Desenvolvimento", "Produtividade", "Sistema", "Data e hora"]

function achar(id) {
    const base = String(id).split(":")[0]
    for (const item of itens)
        if (item.id === base) return item
    return null
}

// Seção da dock em que a entrada fica: 1 no canto direito (data e hora), 0 no esquerdo (todo o resto).
function secao(id) {
    const item = achar(id)
    return item && item.cat === "Data e hora" ? 1 : 0
}

// A lista com as entradas de cada seção juntas, sem mudar a ordem dentro da seção.
function porSecao(lista) {
    return lista.filter(id => secao(id) === 0).concat(lista.filter(id => secao(id) === 1))
}

// Nome de uma entrada da dock: o do widget, com o número da cópia quando houver.
function nome(id) {
    const item = achar(id)
    if (!item) return id + " (não existe mais)"
    const copia = String(id).split(":")[1]
    return copia ? item.nome + " " + copia : item.nome
}

// Chave em que as opções de uma entrada são guardadas: a do grupo compartilhado (opDe) ou a da própria entrada.
function chaveOpcoes(id) {
    const item = achar(id)
    return item && item.opDe ? item.opDe : id
}

// Grupo de opções de um widget: o próprio ou o de quem ele compartilha (opDe).
function grupo(id) {
    const item = achar(id)
    if (!item) return null
    const dono = item.opDe ? achar(item.opDe) : item
    return dono && dono.op ? dono : null
}


// Lugar de uma entrada na ordem padrão: pela categoria, depois pela ordem do catálogo, depois pelo número da cópia.
function posicao(id) {
    const item = achar(id)
    if (!item) return Infinity
    const copia = parseInt(String(id).split(":")[1]) || 1
    return categorias.indexOf(item.cat) * 1e6 + itens.indexOf(item) * 1e3 + copia
}

function ordenar(lista) {
    return lista.slice().sort((a, b) => posicao(a) - posicao(b))
}

// Põe uma entrada nova antes da primeira que vem depois dela na ordem padrão.
function inserir(lista, id) {
    const nova = lista.slice()
    let lugar = nova.findIndex(outra => posicao(outra) > posicao(id))
    if (lugar < 0) lugar = nova.length
    nova.splice(lugar, 0, id)
    return nova
}
