---
title: async let, duas coisas ao mesmo tempo
version: 1
---

Cada `await` da seção 03 esperou a chamada anterior, porque as sessões de um curso precisam do curso.
**Trabalho que não depende de outro trabalho não deveria esperar por ele.** O planner carrega os
minutos de três cursos para o resumo da semana, e nenhum dos três precisa da resposta do outro:

```swift
// Week.swift
func loadMinutes(for course: String) async -> Int {
    try? await Task.sleep(for: .milliseconds(300))
    return course.count * 10
}

func milliseconds(_ d: Duration) -> Int64 {
    d.components.seconds * 1000 + d.components.attoseconds / 1_000_000_000_000_000
}

let clock = ContinuousClock()

var start = clock.now
let a = await loadMinutes(for: "Swift")
let b = await loadMinutes(for: "Kotlin")
let c = await loadMinutes(for: "SQL")
print("one after another:", a + b + c, "minutes in", milliseconds(clock.now - start), "ms")

start = clock.now
async let x = loadMinutes(for: "Swift")
async let y = loadMinutes(for: "Kotlin")
async let z = loadMinutes(for: "SQL")
let total = await x + y + z
print("all three at once:", total, "minutes in", milliseconds(clock.now - start), "ms")
```

```
ana@vm:~/sw/l14$ swift Week.swift
one after another: 140 minutes in 901 ms
all three at once: 140 minutes in 300 ms
```

As mesmas três chamadas, o mesmo total e um terço do tempo. **O `async let` inicia a chamada e não a
espera**; a linha termina na hora e `x` é um valor que vai existir depois. O programa só espera em
`await x + y + z`, onde precisa dos três. Até ali as três cargas já vinham rodando lado a lado havia
300 milissegundos e terminaram juntas.

O `ContinuousClock` mede tempo decorrido, e `clock.now - start` é uma `Duration`. A pequena função
`milliseconds` a transforma num número inteiro de milissegundos, porque uma `Duration` impressa
diretamente mostra nove casas decimais de segundo. Os poucos milissegundos acima de 900 e 300 são o
custo de iniciar e trocar tarefas, e mudam de uma execução para outra; a proporção não muda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 285\" role=\"img\" data-fig=\"l14-async-let\" aria-label=\"Duas linhas do tempo num eixo de 0 a 900 milissegundos. Em cima, três cargas aguardadas de 300 milissegundos cada rodam uma depois da outra e terminam em 901 milissegundos. Embaixo, três cargas com async let começam juntas e todas terminam em 300 milissegundos, onde um único await as recolhe.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">um depois do outro</text><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">os três de uma vez</text><rect x=\"170.0\" y=\"50\" width=\"161.0\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"250.5\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loadMinutes(\"Swift\")</text><rect x=\"335.0\" y=\"50\" width=\"161.0\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"415.5\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loadMinutes(\"Kotlin\")</text><rect x=\"500.0\" y=\"50\" width=\"161.0\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"580.5\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loadMinutes(\"SQL\")</text><text x=\"158\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">await ×3</text><rect x=\"170\" y=\"145\" width=\"161.0\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250.5\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loadMinutes(\"Swift\")</text><text x=\"158\" y=\"157\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">async let x</text><rect x=\"170\" y=\"175\" width=\"161.0\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250.5\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loadMinutes(\"Kotlin\")</text><text x=\"158\" y=\"187\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">async let y</text><rect x=\"170\" y=\"205\" width=\"161.0\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250.5\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loadMinutes(\"SQL\")</text><text x=\"158\" y=\"217\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">async let z</text><path d=\"M335.0 138 L335.0 234\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"343.0\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">await x + y + z</text><text x=\"343.0\" y=\"203\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper)\">espera uma vez, pelos três</text><path d=\"M170 262 L665.0 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M170.0 258 L170.0 266\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"170.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 ms</text><path d=\"M335.0 258 L335.0 266\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"335.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300 ms</text><path d=\"M500.0 258 L500.0 266\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"500.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">600 ms</text><path d=\"M665.0 258 L665.0 266\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"665.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">900 ms</text><text x=\"665.0\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">901 ms medidos</text><text x=\"665.0\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">300 ms medidos</text></svg>", "caption": "As mesmas três cargas da seção 05: aguardadas uma de cada vez elas se somam; iniciadas com async let elas se sobrepõem."}
```

## Tarefas filhas, e o que o escopo promete

Cada `async let` cria uma **tarefa filha** do código em que está escrito. Uma tarefa filha não pode
viver mais que o seu escopo: se o escopo termina sem aguardar uma delas, o Swift a cancela e a espera
ali. Então o `Forgotten.swift` da seção 04 não pode acontecer com `async let`. Toda tarefa filha ou
entregou o seu valor, ou foi cancelada e aguardada antes que a linha depois do seu escopo rodasse.

É isso que quer dizer **concorrência estruturada**: as tarefas formam uma árvore que segue a forma do
código, e as filhas de uma função terminaram quando a função retorna. A seção 07 usa a mesma árvore
para cancelar trabalho, de cima para baixo.

## Quando o async let é a ferramenta errada

O `async let` precisa saber o número de tarefas quando você escreve o código: três nomes, três
tarefas. Uma lista de cursos cujo tamanho você só descobre com o programa rodando precisa de outra
construção, um **grupo de tarefas**, que é a seção 06.
