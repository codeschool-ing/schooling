---
title: Funções, e o que elas devolvem
version: 1
---

A lição 2 já chamou funções com nomes como `minutes(from:)`. Uma **função** é um trecho de código com
nome, com parâmetros que entram e, se ela disser, um valor que sai. O tipo dela está escrito na
primeira linha, e o compilador cobra esse tipo de toda chamada e de todo `return`.

O planner precisa de três cálculos pequenos sobre uma semana de estudo:

```schooling-example
{"language": "swift", "file": "Functions.swift", "parts": [{"code": "// Functions.swift\nfunc weekTotal(_ sessions: [Int]) -> Int {\n    var total = 0\n    for minutes in sessions {\n        total += minutes\n    }\n    return total\n}", "note": "`func`, um nome, os parâmetros entre parênteses e `-> Int` para o tipo do resultado. O `return` devolve o resultado. O `_` antes de `sessions` é o assunto da seção 03; por enquanto, quer dizer que a chamada não escreve rótulo."}, {"code": "func hours(_ minutes: Int) -> Double {\n    Double(minutes) / 60\n}", "note": "Um corpo que é uma única expressão não precisa de `return`: o valor dela é o resultado. É a forma que a maioria das funções curtas do Swift tem."}, {"code": "func progress(_ minutes: Int, goal: Int) -> (done: Int, left: Int) {\n    (minutes, max(goal - minutes, 0))\n}", "note": "Dois resultados de uma vez, como uma **tupla** com partes nomeadas. O `max` impede que os minutos restantes fiquem abaixo de zero depois que a meta passa."}, {"code": "let total = weekTotal([45, 30, 60])\nprint(total, hours(total))\nlet week = progress(total, goal: 300)\nprint(week.done, week.left)", "note": "As chamadas. As partes de uma tupla são lidas pelo nome, `week.done` e `week.left`, então ninguém precisa lembrar qual número veio primeiro."}]}
```

```
ana@vm:~/sw/l03$ swift Functions.swift
135 2.25
135 165
```

O total é 135 minutos, ou 2,25 horas, e contra uma meta de 300 sobram 165. Três coisas do exemplo
valem guardar. **O tipo do resultado faz parte da promessa**: `weekTotal` diz `-> Int`, então todo
caminho por dentro dela precisa terminar num `Int`. **Um corpo de uma expressão só devolve o valor
dela**, e é por isso que `hours` não tem `return`. E **uma tupla é como uma função devolve duas
coisas** sem um tipo inventado para isso; a lição 5 mostra quando é hora de inventar um.

## O compilador confere as duas pontas

Tire o `return` e chame a função sem usar o que ela devolve:

```swift
// Unused.swift
func weekTotal(_ sessions: [Int]) -> Int {
    var total = 0
    for minutes in sessions {
        total += minutes
    }
}
weekTotal([45])
```

```
ana@vm:~/sw/l03$ swiftc Unused.swift -o unused
Unused.swift:8:1: warning: result of call to 'weekTotal' is unused [#NoUsage]
6 |     }
7 | }
8 | weekTotal([45])
  | `- warning: result of call to 'weekTotal' is unused [#NoUsage]
9 | 

Unused.swift:7:1: error: missing return in global function expected to return 'Int'
5 |         total += minutes
6 |     }
7 | }
  | `- error: missing return in global function expected to return 'Int'
8 | weekTotal([45])
9 | 

[#NoUsage]: <https://docs.swift.org/compiler/documentation/diagnostics/no-usage>
```

**Um erro e um aviso, sobre as duas pontas de uma função.** O erro é a promessa quebrada: o corpo
pode chegar à chave que fecha sem produzir o `Int` que a primeira linha declarou, então nenhum
programa é gerado. O aviso é sobre quem chama: `weekTotal([45])` calcula um número e o joga fora, o
que quase sempre é engano, porque uma função que devolve algo em geral foi chamada para obtê-lo.
Quando descartar é mesmo a intenção, `_ = weekTotal([45])` diz isso e cala o aviso.

## Uma função sem nada para devolver

O `print` não devolve nada, nem uma função que só relata. Deixe de fora a parte `->` e o tipo do
resultado da função é `Void`, uma tupla vazia, `()`. Você verá `Void` escrito por extenso em tipos de
função na seção 06. Uma função assim ainda pode usar `return` para sair antes, sem nada depois da
palavra, que é como o `guard` da lição 2 saiu de uma função que não tinha valor a dar.
