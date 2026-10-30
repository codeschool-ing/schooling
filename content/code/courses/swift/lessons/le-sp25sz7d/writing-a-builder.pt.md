---
title: Escrevendo um result builder
version: 1
---

O planner imprime um relatório da semana: um título, uma linha por curso, e uma linha de parabéns
quando a meta é atingida. Escrito com os arrays da lição 4, é um `var lines` e um `append` em cada
linha. **Um result builder deixa o relatório ser escrito como o que ele diz**, uma linha de texto por
linha de código.

Um builder é um tipo marcado com `@resultBuilder` com pelo menos uma função estática, `buildBlock`,
que combina os pedaços de um bloco num valor só. Este começa só com ela:

```swift
// Report.swift
@resultBuilder
enum ReportBuilder {
    static func buildBlock(_ lines: [String]...) -> [String] {
        lines.flatMap { $0 }
    }
    static func buildExpression(_ line: String) -> [String] {
        [line]
    }
}

func report(@ReportBuilder _ content: () -> [String]) -> String {
    content().joined(separator: "\n")
}

let courses = ["Swift": 135, "SQL": 90]
let goal = 300

print(report {
    "Week of 2 November"
    "Swift: \(courses["Swift"] ?? 0) minutes"
    "SQL: \(courses["SQL"] ?? 0) minutes"
})
```

```
ana@vm:~/sw/l16$ swift Report.swift
Week of 2 November
Swift: 135 minutes
SQL: 90 minutes
```

O `@ReportBuilder` na frente do parâmetro closure é o que faz do bloco na chamada um bloco de builder.
**O `buildExpression` transforma cada linha no tipo com que o builder trabalha**, aqui um array de um
elemento só, e o `buildBlock` recebe um desses por linha e os achata numa lista. O enum não tem casos e
nunca é criado: é só um lugar para guardar as funções estáticas, o jeito costumeiro de escrever um
builder.

## Controle de fluxo é opcional

Cursos são uma lista, então o relatório natural tem um laço `for`, e os parabéns são um `if`. Ponha os
dois no bloco e o compilador para:

```swift
// ReportLoop.swift
@resultBuilder
enum ReportBuilder {
    static func buildBlock(_ lines: [String]...) -> [String] {
        lines.flatMap { $0 }
    }
    static func buildExpression(_ line: String) -> [String] {
        [line]
    }
}

func report(@ReportBuilder _ content: () -> [String]) -> String {
    content().joined(separator: "\n")
}

let courses = ["SQL": 90, "Swift": 135]
let goal = 300

print(report {
    "Week of 2 November"
    for (course, minutes) in courses.sorted(by: { $0.key < $1.key }) {
        "\(course): \(minutes) minutes"
    }
})
```

```
ana@vm:~/sw/l16$ swiftc ReportLoop.swift -o reportloop
ReportLoop.swift:21:5: error: closure containing control flow statement cannot be used with result builder 'ReportBuilder'
 1 | // ReportLoop.swift
 2 | @resultBuilder
 3 | enum ReportBuilder {
   |      |- note: add 'buildArray(_:)' to the result builder 'ReportBuilder' to add support for 'for'..'in' loops
   |      `- note: enum 'ReportBuilder' declared here
 4 |     static func buildBlock(_ lines: [String]...) -> [String] {
 5 |         lines.flatMap { $0 }
   :
19 | print(report {
20 |     "Week of 2 November"
21 |     for (course, minutes) in courses.sorted(by: { $0.key < $1.key }) {
   |     `- error: closure containing control flow statement cannot be used with result builder 'ReportBuilder'
22 |         "\(course): \(minutes) minutes"
23 |     }
```

**O builder não tem `buildArray`, então um `for` é recusado**, com o builder nomeado na mensagem e uma
nota dizendo que função acrescentaria o suporte. Isso é um recurso: um builder decide quais instruções
fazem sentido dentro dele, e um que não tem significado para um laço simplesmente não o oferece. O
nosso tem significado para os dois, então ganha mais duas funções estáticas:

```schooling-example
{"language": "swift", "file": "ReportFull.swift", "parts": [{"code": "@resultBuilder\nenum ReportBuilder {\n    static func buildBlock(_ lines: [String]...) -> [String] {\n        lines.flatMap { $0 }\n    }\n    static func buildExpression(_ line: String) -> [String] {\n        [line]\n    }", "note": "As duas funções do `Report.swift`, sem mudança: uma transforma uma linha numa lista, a outra junta as listas de um bloco."}, {"code": "    static func buildArray(_ passes: [[String]]) -> [String] {\n        passes.flatMap { $0 }\n    }", "note": "**O `buildArray` dá significado ao `for`.** O compilador roda o laço, monta o corpo uma vez por volta, e entrega a esta função uma lista por volta para juntar."}, {"code": "    static func buildOptional(_ lines: [String]?) -> [String] {\n        lines ?? []\n    }\n}", "note": "**O `buildOptional` dá significado a um `if` sem `else`.** Ele recebe as linhas do corpo quando a condição valeu, e `nil` quando não valeu, que vira nenhuma linha."}, {"code": "func report(goal: Int, _ courses: [String: Int]) -> String {\n    let total = courses.values.reduce(0, +)\n    return build(goal: goal, total: total, courses).joined(separator: \"\\n\")\n}", "note": "A função de relatório agora recebe a meta e os cursos como parâmetros, soma o total e junta o que o `build` devolver."}, {"code": "@ReportBuilder\nfunc build(goal: Int, total: Int, _ courses: [String: Int]) -> [String] {\n    \"Week of 2 November: \\(total) of \\(goal) minutes\"\n    for (course, minutes) in courses.sorted(by: { $0.key < $1.key }) {\n        \"  \\(course): \\(minutes)\"\n    }\n    if total >= goal {\n        \"Goal reached\"\n    }\n}", "note": "**Um atributo de builder funciona numa função também**: o corpo de `build` é um bloco de builder, sem `return`. O `for` e o `if` são as instruções pelas quais o `ReportLoop.swift` foi recusado."}, {"code": "let courses = [\"SQL\": 90, \"Swift\": 135]\nprint(report(goal: 300, courses))\nprint(report(goal: 200, courses))"}]}
```

```
ana@vm:~/sw/l16$ swift ReportFull.swift
Week of 2 November: 225 of 300 minutes
  SQL: 90
  Swift: 135
Week of 2 November: 225 of 200 minutes
  SQL: 90
  Swift: 135
Goal reached
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l16-builder\" aria-label=\"Três instruções do bloco do relatório à esquerda, uma linha de texto, um laço for e um if, cada uma com uma seta para a função do builder que a trata: buildExpression, buildArray e buildOptional. As três setas se encontram no buildBlock, que produz um único array de strings.\"><defs><marker id=\"l16-build-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o bloco</text><rect x=\"20\" y=\"40\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"Week of 2 November: …\"</text><path d=\"M270 58 L338 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-build-ah)\"></path><rect x=\"340\" y=\"40\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"415\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">buildExpression</text><path d=\"M490 58 L568 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-build-ah)\"></path><rect x=\"20\" y=\"100\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">for (course, minutes) in …</text><path d=\"M270 118 L338 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-build-ah)\"></path><rect x=\"340\" y=\"100\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"415\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">buildArray</text><path d=\"M490 118 L568 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-build-ah)\"></path><rect x=\"20\" y=\"160\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">if total &gt;= goal { … }</text><path d=\"M270 178 L338 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-build-ah)\"></path><rect x=\"340\" y=\"160\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"415\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">buildOptional</text><path d=\"M490 178 L568 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-build-ah)\"></path><rect x=\"570\" y=\"108\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">buildBlock</text><path d=\"M635 148 L635 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-build-ah)\"></path><text x=\"635\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">[String]</text><text x=\"350\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper)\">cada instrução vai para a função que o compilador escolhe para ela</text></svg>", "caption": "O que o ReportBuilder faz com o corpo de build: uma função estática por tipo de instrução, e o buildBlock para juntar os resultados."}
```

Dois relatórios a partir de um bloco. O laço produziu uma linha por curso nos dois. O `if` não
produziu nada no primeiro, em que 225 minutos ficaram abaixo de 300, e produziu "Goal reached" no
segundo, cuja meta era 200. Cada instrução dentro do bloco foi para a função que o compilador escolheu
para ela, o `buildArray` para o `for` e o `buildOptional` para o `if`, e o `buildBlock` combinou o que
elas devolveram. **O relatório na chamada se lê como o relatório na tela**, que é todo o sentido de um
builder e o motivo de o SwiftUI ser escrito com um.
