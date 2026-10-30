---
title: Atores, que atendem uma chamada por vez
version: 1
---

**Um ator é um tipo cujo estado só o próprio código dele pode tocar, uma chamada por vez.** Ele é
declarado como uma classe, com a palavra `actor` no lugar, e é um tipo de referência como uma classe:
todos que seguram um seguram o mesmo. O que ele acrescenta é a regra. Aqui está o `WeekTotal` de novo,
com uma palavra trocada e um `await` acrescentado:

```schooling-example
{"language": "swift", "file": "Actor.swift", "parts": [{"code": "// Actor.swift\nactor WeekTotal {\n    var minutes = 0\n    func add(_ m: Int) { minutes += m }\n}", "note": "**`actor` no lugar de `final class`**, e nada mais muda no tipo. `minutes` agora está **isolado** no ator: só código rodando no ator pode tocá-lo."}, {"code": "func countWeek() async -> Int {\n    let week = WeekTotal()\n    await withTaskGroup(of: Void.self) { group in\n        for _ in 1...8 {\n            group.addTask {\n                for _ in 1...100_000 {\n                    await week.add(1)\n                }\n            }\n        }\n    }\n    return await week.minutes", "note": "As mesmas oito tarefas. Cada chamada a `add` agora tem um **`await`**, porque uma chamada a um ator vinda de fora pode ter de esperar as chamadas à frente dela. Ler `minutes` no fim também é uma travessia, e também leva um."}, {"code": "}\n\nfor _ in 1...3 {\n    print(\"expected 800000, got \\(await countWeek())\")\n}", "note": "Três execuções, como antes, compiladas desta vez com `-swift-version 6`, que não acusou erro nenhum."}]}
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Actor.swift -o actor && ./actor
expected 800000, got 800000
expected 800000, got 800000
expected 800000, got 800000
```

**Certo três vezes, no modo Swift 6, sem nenhum lock escrito.** Cada `await week.add(1)` é um pedido
ao ator; o ator roda os pedidos que recebe um depois do outro, então dois `+=` em `minutes` nunca se
sobrepõem. As oito tarefas continuam rodando lado a lado. O que elas não fazem mais é tocar em
`minutes` por conta própria.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l15-actor\" aria-label=\"Quatro tarefas à esquerda mandam await week.add(1) a um ator. Dentro do ator, as chamadas esperam numa fila, um add roda por vez, e só a chamada que roda muda minutes.\"><defs><marker id=\"l15-actor-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l15-actor-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tarefa 1</text><path d=\"M140 56 L250 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-actor-ah2)\"></path><rect x=\"20\" y=\"88\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tarefa 2</text><path d=\"M140 104 L250 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-actor-ah2)\"></path><rect x=\"20\" y=\"136\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tarefa 3</text><path d=\"M140 152 L250 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-actor-ah2)\"></path><rect x=\"20\" y=\"184\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tarefa 4</text><path d=\"M140 200 L250 152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-actor-ah2)\"></path><text x=\"195\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">await week.add(1)</text><rect x=\"255\" y=\"60\" width=\"420\" height=\"170\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"465\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">actor WeekTotal</text><text x=\"330\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na fila</text><rect x=\"275\" y=\"110\" width=\"110\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"330\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">add(1)</text><rect x=\"275\" y=\"140\" width=\"110\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"330\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">add(1)</text><rect x=\"275\" y=\"170\" width=\"110\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"330\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">add(1)</text><path d=\"M385 150 L450 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-actor-ah)\"></path><rect x=\"455\" y=\"128\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">add(1)</text><text x=\"500\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">rodando</text><path d=\"M545 150 L580 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-actor-ah)\"></path><rect x=\"585\" y=\"128\" width=\"75\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"622\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">minutes</text><text x=\"622\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">+= 1</text><text x=\"465\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper)\">uma chamada por vez toca o estado</text><text x=\"465\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as tarefas rodam lado a lado; só o ator toca em minutes</text></svg>", "caption": "Um ator enfileira as chamadas que recebe: as tarefas continuam rodando em paralelo, e o estado é tocado por uma chamada de cada vez."}
```

## Atravessar a fronteira pede um await

De fora do ator, toda chamada de método e toda leitura de propriedade é um pedido que pode ter de
esperar a vez, e o compilador exige `await` para ela. Uma escrita de fora não é pedido nenhum, e é
recusada seja o que for que você escreva:

```swift
// Outside.swift
actor WeekTotal {
    var minutes = 0
    func add(_ m: Int) { minutes += m }
}

let week = WeekTotal()
week.add(45)
week.minutes = 0
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Outside.swift -o outside
Outside.swift:8:6: error: call to actor-isolated instance method 'add' in a synchronous main actor-isolated context [#ActorIsolatedCall]
 2 | actor WeekTotal {
 3 |     var minutes = 0
 4 |     func add(_ m: Int) { minutes += m }
   |          `- note: calls to instance method 'add' from outside of its actor context are implicitly asynchronous
 5 | }
 6 | 
 7 | let week = WeekTotal()
 8 | week.add(45)
   |      `- error: call to actor-isolated instance method 'add' in a synchronous main actor-isolated context [#ActorIsolatedCall]
 9 | week.minutes = 0
10 | 

Outside.swift:9:6: error: actor-isolated property 'minutes' can not be mutated from the main actor
 1 | // Outside.swift
 2 | actor WeekTotal {
 3 |     var minutes = 0
   |         `- note: mutation of this property is only permitted within the actor
 4 |     func add(_ m: Int) { minutes += m }
 5 | }
   :
 7 | let week = WeekTotal()
 8 | week.add(45)
 9 | week.minutes = 0
   |      `- error: actor-isolated property 'minutes' can not be mutated from the main actor
10 | 

[#ActorIsolatedCall]: <https://docs.swift.org/compiler/documentation/diagnostics/actor-isolated-call>
```

O primeiro erro é a regra das chamadas: **uma chamada a um método do ator vinda de fora é
implicitamente assíncrona**, como diz a nota, e um contexto síncrono não consegue fazê-la.
`await week.add(45)` num contexto `async` resolve. O segundo não tem conserto com `await`: **só o
código do próprio ator pode mudar as propriedades dele.** Quem quer `minutes` zerado pede ao ator que
o faça, chamando um método como `reset()` que o ator oferece.

Dentro do ator nada muda: `add` lê e escreve `minutes` sem `await`, porque código que já está rodando
no ator tem o ator só para si. **A fronteira é a borda do ator, e o `await` marca cada travessia
dela.** Os dois erros mencionam o ator principal, porque o nível de cima de um programa roda nele; a
seção 06 trata do que isso significa.

## Quanto custa

Cada `await` a um ator é uma suspensão possível, e o `Actor.swift` fez 800.000 delas por execução. É
o preço da proteção, e é por isso que um contador é um mau uso de um ator. Um ator vale a pena quando
protege estado que várias partes do programa dividem, como o cache de cursos de um planner ou a
conexão com um servidor, e cada chamada faz uma quantidade de trabalho que conta.
