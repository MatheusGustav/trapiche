.pragma library

// Posição livre dos blocos na dock. O que se grava de cada bloco é { lado, d }: a distância "d", na medida do
// desenho (altura 77), até a borda esquerda ("e") ou direita ("d") da barra.

// Espaços vazios da barra, da esquerda para a direita, entre os ocupados [{ x, larg }].
function livres(ocupados, inicio, fim, vao) {
    const vaos = []
    let a = inicio
    for (const o of ocupados.slice().sort((p, q) => p.x - q.x)) {
        vaos.push([a, o.x - vao])
        a = Math.max(a, o.x + o.larg + vao)
    }
    vaos.push([a, fim])
    return vaos
}

// Lugar vazio mais perto de x em que cabe um bloco de largura "larg". Sem lugar nenhum, o próprio x.
function encaixar(x, larg, ocupados, inicio, fim, vao) {
    let melhor = null
    for (const [a, b] of livres(ocupados, inicio, fim, vao)) {
        if (b - a < larg) continue
        const lugar = Math.max(a, Math.min(x, b - larg))
        if (melhor === null || Math.abs(lugar - x) < Math.abs(melhor - x)) melhor = lugar
    }
    return melhor === null ? x : melhor
}

// Primeiro lugar vazio em que o bloco cabe, a partir da esquerda ou da direita.
function primeiraVaga(larg, ocupados, inicio, fim, vao, daDireita) {
    const vaos = livres(ocupados, inicio, fim, vao)
    if (daDireita) vaos.reverse()
    for (const [a, b] of vaos)
        if (b - a >= larg) return daDireita ? b - larg : a
    return daDireita ? fim - larg : inicio
}

function gravar(x, larg, inicio, fim, u) {
    return x + larg / 2 < (inicio + fim) / 2
        ? { lado: "e", d: Math.round((x - inicio) / u) }
        : { lado: "d", d: Math.round((fim - x - larg) / u) }
}

// O x de cada bloco. blocos: [{ larg, secao, pos }] na ordem da lista da dock; "pos" é o que foi gravado.
// Bloco sem posição gravada vai para a primeira vaga do lado da seção dele: 0 na esquerda, 1 na direita.
// Depois, quem ficou por cima de outro ou para fora da barra é empurrado; os presos à borda esquerda ficam
// sempre antes dos presos à direita.
function arrumar(blocos, inicio, fim, vao, u) {
    const x = blocos.map(b => !b.pos ? null : (b.pos.lado === "d" ? fim - b.pos.d * u - b.larg : inicio + b.pos.d * u))
    const ocupados = []
    blocos.forEach((b, i) => { if (x[i] !== null) ocupados.push({ x: x[i], larg: b.larg }) })
    const semLugar = blocos.map((b, i) => i).filter(i => x[i] === null)
    const fila = semLugar.filter(i => blocos[i].secao === 0).concat(semLugar.filter(i => blocos[i].secao === 1).reverse())
    for (const i of fila) {
        x[i] = primeiraVaga(blocos[i].larg, ocupados, inicio, fim, vao, blocos[i].secao === 1)
        ocupados.push({ x: x[i], larg: blocos[i].larg })
    }

    const direita = blocos.map((b, i) => (b.pos ? b.pos : gravar(x[i], b.larg, inicio, fim, u)).lado === "d" ? 1 : 0)
    const ordem = blocos.map((b, i) => i).sort((p, q) => direita[p] - direita[q] || x[p] - x[q] || p - q)
    const paraDireita = () => {
        let limite = inicio
        for (const i of ordem) {
            x[i] = Math.max(x[i], limite)
            limite = x[i] + blocos[i].larg + vao
        }
    }
    paraDireita()
    let limite = fim
    for (const i of ordem.slice().reverse()) {
        x[i] = Math.min(x[i], limite - blocos[i].larg)
        limite = x[i] - vao
    }
    paraDireita()
    return x.map(Math.round)
}
