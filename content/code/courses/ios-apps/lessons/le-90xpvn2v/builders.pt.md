---
title: Result builders: como um body guarda várias views
version: 1
---

**Um body que lista três views uma embaixo da outra não são três instruções; é uma expressão só,
montada por um result builder.** Em Swift comum, o corpo de uma função com três expressões soltas
calcularia três valores e os jogaria fora. Num body, essas linhas viram um valor que guarda as três,
porque o SwiftUI marca o `body` com o seu builder, e o builder é um tipo com funções estáticas que o
compilador chama em cada linha.

Builders são um recurso do Swift, não do SwiftUI: o curso `swift` os encontra na aula 16, e eles
compilam no Linux como qualquer outra coisa. Aqui está um pequeno que monta as linhas de um cartão de
curso em vez de views. Salve isto como `builder.swift` em `~/l03`:

```schooling-example
{"language": "swift", "file": "builder.swift", "parts": [{"code": "// builder.swift: a result builder like SwiftUI's, building lines of text\n@resultBuilder\nenum LinesBuilder {\n    static func buildExpression(_ line: String) -> [String] { [line] }\n    static func buildBlock(_ parts: [String]...) -> [String] { parts.flatMap { $0 } }\n", "note": "O `@resultBuilder` marca o tipo. O `buildExpression` transforma cada linha numa parte, aqui um array de um elemento; o `buildBlock` recebe todas as partes de um bloco e as junta num valor só."}, {"code": "    static func buildOptional(_ part: [String]?) -> [String] { part ?? [] }\n    static func buildEither(first part: [String]) -> [String] { part }\n    static func buildEither(second part: [String]) -> [String] { part }\n}\n", "note": "Mais três funções tornam o `if` válido dentro de um builder. O `buildOptional` é um `if` sem `else`: nada quando a condição é falsa. Os dois `buildEither` são os dois ramos de um `if`/`else`."}, {"code": "@LinesBuilder\nfunc card(title: String, minutes: Int, done: Bool) -> [String] {\n    title\n    \"\\(minutes) min\"\n    if done {\n        \"done\"\n    }\n}\n\nprint(card(title: \"SQL Databases\", minutes: 50, done: true))\nprint(card(title: \"Mobile Fundamentals\", minutes: 40, done: false))\n", "note": "O corpo da função parece um body SwiftUI: linhas sem `return`, e um `if`. O compilador o reescreve em chamadas às funções do builder, e o resultado é um array só."}]}
```

```
ana@vm:~/l03$ swift builder.swift
["SQL Databases", "50 min", "done"]
["Mobile Fundamentals", "40 min"]
```

**O segundo cartão tem duas linhas, porque o `if` era falso e o `buildOptional` recebeu `nil`.** Nada
de especial aconteceu em tempo de execução: o compilador reescreveu a função antes de ela rodar. O que
ele escreveu é mais ou menos isto, e ver uma vez tira a mágica:

```swift
let a = LinesBuilder.buildExpression(title)
let b = LinesBuilder.buildExpression("\(minutes) min")
let c = LinesBuilder.buildOptional(done ? LinesBuilder.buildBlock(LinesBuilder.buildExpression("done")) : nil)
return LinesBuilder.buildBlock(a, b, c)
```

Essa expansão foi escrita à mão para mostrar o formato, a partir das regras da referência da
linguagem Swift para result builders; ela não foi impressa pelo compilador.

## O builder do SwiftUI

O builder do SwiftUI é o `ViewBuilder`, e o `body` o carrega. Ele tem a mesma família de funções e, em
vez de juntar strings, combina views num valor cujo **tipo** registra cada view e cada ramo. É o "um
tipo só" que a seção 03 disse que um body precisa devolver: quantas views um body listar, o builder as
transforma num único tipo.

A documentação da Apple para o `ViewBuilder`, lida em 30 de outubro de 2026, acrescenta que a partir
do Xcode 27 o builder constrói o que ela chama de conteúdo agnóstico de tipo, e cita o
`ContentBuilder` como o apelido a escrever onde o código espera isso. A regra de que esta aula trata
não muda com isso: um body é uma expressão, e o builder decide como as linhas dele viram um valor.
