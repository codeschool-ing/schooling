---
title: Cancelar é um pedido
version: 1
---

Uma estudante abre um curso, e o planner começa a carregar as sessões dele. Antes que cheguem, ela
volta, e a resposta não interessa mais. **Cancelar uma tarefa não a para.** Isso liga uma marca na
tarefa que o próprio código dela deve ler, e as funções do próprio Swift a leem:

```swift
// Cancel.swift
func loadMinutes(for course: String) async throws -> [Int] {
    try await Task.sleep(for: .milliseconds(500))
    return [45, 30, 60]
}

let task = Task {
    do {
        let minutes = try await loadMinutes(for: "Swift")
        print("loaded \(minutes)")
    } catch {
        print("stopped: \(error)")
    }
}

try? await Task.sleep(for: .milliseconds(100))
task.cancel()
await task.value
```

```
ana@vm:~/sw/l14$ swift Cancel.swift
stopped: CancellationError()
```

O `task.cancel()` foi chamado aos 100 milissegundos, enquanto `loadMinutes` dormia. **O `Task.sleep`
confere a marca, e quando ela está ligada ele para de dormir e lança `CancellationError`.** Por isso o
`Task.sleep` é uma função que lança erros, e por isso `loadMinutes` agora é `async throws`: o erro sobe
como qualquer outro erro da lição 12, até o `catch`. "loaded" nunca foi impresso.

## O `try?` que engoliu o cancelamento

Todas as seções anteriores desta lição escreveram `try? await Task.sleep(…)`, e isso era inofensivo
enquanto nada cancelava nada. Quando algo cancela, o `try?` transforma o cancelamento em `nil` e a
função segue em frente. Aqui está um laço que soma cinco cursos, uma espera por curso, escrito dos dois
jeitos:

```swift
// Cooperate.swift
let courses = ["Swift", "Kotlin", "SQL", "Statistics", "Git"]

func totalCarelessly() async -> Int {
    var total = 0
    for course in courses {
        try? await Task.sleep(for: .milliseconds(100))
        print("  added \(course)")
        total += course.count * 10
    }
    return total
}

func totalCarefully() async throws -> Int {
    var total = 0
    for course in courses {
        try await Task.sleep(for: .milliseconds(100))
        print("  added \(course)")
        total += course.count * 10
    }
    return total
}

print("carelessly:")
let careless = Task { await totalCarelessly() }
try? await Task.sleep(for: .milliseconds(250))
careless.cancel()
print("result:", await careless.value)

print("carefully:")
let careful = Task { try await totalCarefully() }
try? await Task.sleep(for: .milliseconds(250))
careful.cancel()
print("result:", await careful.result)
```

```
ana@vm:~/sw/l14$ swift Cooperate.swift
carelessly:
  added Swift
  added Kotlin
  added SQL
  added Statistics
  added Git
result: 270
carefully:
  added Swift
  added Kotlin
result: failure(Swift.CancellationError())
```

**A versão descuidada terminou o trabalho mesmo assim, e mais depressa.** Dois cursos foram somados
nos 250 milissegundos antes do cancelamento. Depois dele, todo `Task.sleep` lançou na hora, o `try?`
descartou cada erro, e o laço correu pelos três últimos e devolveu os 270 completos como se nada
tivesse acontecido. A versão cuidadosa deixou o erro subir: parou depois dos mesmos dois cursos, e o
`result` dela, um `Result` da lição 12, carrega o `CancellationError`.

## Cooperativo, então é trabalho do seu código

O cancelamento no Swift é **cooperativo**: uma tarefa para onde o código dela olha a marca, e em nenhum
outro lugar. As funções de suspensão do próprio Swift olham, e fazer os seus laços olharem é com você.
Dois jeitos:

- `try Task.checkCancellation()` lança `CancellationError` se a tarefa foi cancelada, o que serve a uma
  função que já lança erros;
- `Task.isCancelled` é um `Bool`, para código que prefere parar cedo e devolver o que tem.

Um laço que calcula por muito tempo sem aguardar nada nunca vê a marca, então ponha um dos dois no
começo de cada volta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l14-tree\" aria-label=\"Uma árvore de tarefas. A tarefa que você cancela tem três tarefas filhas, dois async let e um grupo de tarefas com duas tarefas próprias, e setas âmbar levam o cancelamento a todas elas. Ao lado, uma tarefa iniciada com Task dentro dela aparece tracejada: é não estruturada, não é filha, e continua rodando.\"><defs><marker id=\"l14-tree-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-tree-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"250\" y=\"20\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a tarefa que você cancela</text><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">task.cancel()</text><path d=\"M360 60 L110 110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-tree-ah)\"></path><rect x=\"40\" y=\"112\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">async let x</text><path d=\"M360 60 L270 110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-tree-ah)\"></path><rect x=\"200\" y=\"112\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">async let y</text><path d=\"M360 60 L430 110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-tree-ah)\"></path><rect x=\"360\" y=\"112\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">withTaskGroup</text><path d=\"M430 146 L380 196\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-tree-ah)\"></path><rect x=\"330\" y=\"198\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">addTask</text><path d=\"M430 146 L500 196\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-tree-ah)\"></path><rect x=\"450\" y=\"198\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">addTask</text><text x=\"240\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">tarefas filhas: canceladas com a mãe</text><path d=\"M470 40 L560 40 L560 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l14-tree-ah2)\"></path><rect x=\"560\" y=\"112\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"630\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Task { … }</text><text x=\"630\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não estruturada:</text><text x=\"630\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">continua rodando</text></svg>", "caption": "O cancelamento segue a árvore de tarefas filhas, e para numa tarefa que nunca foi filha."}
```

**O cancelamento desce pela árvore.** Cancelar uma tarefa cancela as tarefas filhas dela, os
`async let` e os membros dos seus grupos, e cada uma para onde o próprio código confere. Uma
`Task { … }` não estruturada iniciada dentro dela não é filha, e não é cancelada junto: a palavra da
seção 04, não estruturada, de novo.
