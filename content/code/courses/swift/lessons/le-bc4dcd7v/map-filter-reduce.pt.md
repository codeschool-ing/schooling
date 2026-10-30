---
title: map, filter e reduce
version: 1
---

A maioria dos laços sobre uma coleção faz um de três trabalhos: transformar cada item em outra coisa,
guardar os itens que passam num teste, ou combinar todos os itens num valor só. **O Swift tem um
método para cada um: `map`, `filter` e `reduce`**, e cada um recebe uma closure, escrita como as
trailing closures da lição 3.

Uma semana de sessões, cada uma uma tupla com um curso, uma duração e se foi feita:

```schooling-example
{"language": "swift", "file": "Transform.swift", "parts": [{"code": "// Transform.swift\nlet week: [(course: String, minutes: Int, done: Bool)] = [\n    (\"Swift\", 45, true),\n    (\"Kotlin\", 30, false),\n    (\"Swift\", 60, true),\n    (\"SQL\", 20, true),\n]", "note": "Quatro sessões, cada uma uma tupla com partes nomeadas. A lição 5 troca a tupla por um tipo próprio; para estes três métodos a tupla basta."}, {"code": "let hours = week.map { Double($0.minutes) / 60 }\nprint(hours)", "note": "`map`: um resultado por item, na mesma ordem. A closure transforma uma sessão na duração dela em horas."}, {"code": "let pending = week.filter { !$0.done }\nprint(pending.map { $0.course })", "note": "`filter`: os itens para os quais a closure diz `true`. O `!` se lê \"não\", então isto guarda as sessões ainda não feitas."}, {"code": "let planned = week.reduce(0) { $0 + $1.minutes }\nprint(planned)", "note": "`reduce`: um valor a partir de todos. Começa em 0 e soma os minutos de cada sessão; a parte abaixo da saída o mostra devagar."}, {"code": "let studied = week.filter { $0.done }.map { $0.minutes }.reduce(0, +)\nprint(studied)", "note": "Os três numa cadeia, lidos da esquerda para a direita: as sessões feitas, os minutos delas, a soma."}]}
```

```
ana@vm:~/sw/l04$ swift Transform.swift
[0.75, 0.5, 1.0, 0.3333333333333333]
["Kotlin"]
155
125
```

**Cada método devolve uma coleção nova e deixa `week` em paz**, e é por isso que `week` pode ser um
`let`. O `map` produziu um array do mesmo tamanho com conteúdo diferente; o `filter`, um com o mesmo
tipo de conteúdo e menos itens; o `reduce`, um valor só. A cadeia da última parte se lê na ordem em
que roda: guarde as sessões feitas, pegue os minutos delas, some. O laço que faz o mesmo trabalho
precisa de um `var` e de quatro linhas, e quem lê precisa rodá-lo de cabeça para ver qual dos três
trabalhos ele faz.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l04-pipeline\" aria-label=\"Quatro sessões numa coluna: Swift 45 feita, Kotlin 30 não feita, Swift 60 feita, SQL 20 feita. O filter done guarda três delas, deixando o Kotlin de fora. O map minutes transforma as três nos números 45, 60 e 20. O reduce com mais os soma num número só, 125.\"><defs><marker id=\"l04-pipeline-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Swift 45</text><text x=\"80\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">feita</text><rect x=\"20\" y=\"78\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Kotlin 30</text><text x=\"80\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não feita</text><rect x=\"20\" y=\"126\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Swift 60</text><text x=\"80\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">feita</text><rect x=\"20\" y=\"174\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SQL 20</text><text x=\"80\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">feita</text><line x1=\"145\" y1=\"120\" x2=\"335\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l04-pipeline-ah-phosphor)\"></line><text x=\"240\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">filter { $0.done }</text><text x=\"240\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 guardadas</text><rect x=\"340\" y=\"60\" width=\"60\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"370\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">45</text><rect x=\"340\" y=\"104\" width=\"60\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"370\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">60</text><rect x=\"340\" y=\"148\" width=\"60\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"370\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20</text><text x=\"370\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 números</text><text x=\"370\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">map { $0.minutes }</text><line x1=\"405\" y1=\"120\" x2=\"615\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l04-pipeline-ah-phosphor)\"></line><text x=\"510\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">reduce(0, +)</text><rect x=\"620\" y=\"100\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"660\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--amber)\">125</text><text x=\"660\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 valor</text></svg>", "caption": "A cadeia do Transform.swift: cada passo entrega uma coleção nova ao seguinte, e o último devolve um valor."}
```

## reduce, devagar

`reduce(0, +)` é o jeito mais curto de somar um array, e vale ver uma vez o que ele faz:

```swift
// Reduce.swift
let minutes = [45, 30, 60]
let total = minutes.reduce(0) { sum, next in
    print("\(sum) + \(next)")
    return sum + next
}
print(total)
```

```
ana@vm:~/sw/l04$ swift Reduce.swift
0 + 45
45 + 30
75 + 60
135
```

O `reduce` começa do valor que você dá, 0, e chama a closure uma vez por item com **o resultado até
agora e o próximo item**. O que a closure devolve vira o resultado até agora da chamada seguinte. O `+`
pode ser passado no lugar de uma closure porque o operador é ele mesmo uma função do tipo `(Int, Int)
-> Int`, o formato que o `reduce` pede.

## compactMap, de novo

A lição 2 encontrou o `compactMap`: um `map` cuja closure devolve um opcional, guardando só os valores
que existem. Com `map` e `filter` nomeados, ele se lê como o que é, **map e depois filtrar fora os
`nil`**, numa passada só.
