---
title: Tipos genéricos
version: 1
---

Funções não são a única coisa com marcador. `Array<Element>`, `Dictionary<Key, Value>` e
`Optional<Wrapped>` são tipos genéricos da biblioteca padrão, e `[Int]` é só um jeito mais curto de
escrever `Array<Int>`. **Um tipo genérico é uma struct, classe ou enum com parâmetros de tipo**, e cada
uso dele escolhe os tipos. Uma lista de desfazer do planner é uma pilha, e uma pilha não tem nada a
ver com o que guarda:

```schooling-example
{"language": "swift", "file": "Stack.swift", "parts": [{"code": "// Stack.swift\nstruct Stack<Element> {\n    private var items: [Element] = []", "note": "`Element` é o parâmetro de tipo da struct inteira. Toda `Stack` tem um, escolhido quando a pilha é criada, e o array de dentro guarda esse tipo."}, {"code": "    mutating func push(_ item: Element) { items.append(item) }\n    mutating func pop() -> Element? { items.popLast() }\n    var top: Element? { items.last }\n    var isEmpty: Bool { items.isEmpty }\n}", "note": "Os métodos usam `Element` como qualquer tipo. `pop()` e `top` devolvem um opcional, porque uma pilha vazia não tem o que dar."}, {"code": "extension Stack where Element: Numeric {\n    var sum: Element { items.reduce(0, +) }\n}", "note": "Uma extensão que só existe quando os elementos são números: `sum` é membro de `Stack<Int>` e não de `Stack<String>`."}, {"code": "var undo = Stack<String>()\nundo.push(\"added Optionals, 45 min\")\nundo.push(\"marked Closures done\")\nprint(undo.pop() ?? \"-\")\nprint(undo.top ?? \"-\")", "note": "Uma pilha de strings, escrita `Stack<String>`: uma lista de desfazer em que a última ação é a primeira a voltar."}, {"code": "var minutes = Stack<Int>()\nminutes.push(45)\nminutes.push(30)\nprint(minutes.sum, minutes.isEmpty)", "note": "A mesma struct guardando inteiros. Aqui `sum` existe, e o compilador deduziu `Element` pelo `<Int>` explícito."}], "output": "marked Closures done\nadded Optionals, 45 min\n75 false"}
```

O `swift Stack.swift` o roda. A lista de desfazer devolveu primeiro a última ação, e o topo passa a
ser a anterior. A pilha de minutos somou 75, e não está vazia.

## Cada uso é um tipo diferente

`Stack<String>` e `Stack<Int>` são dois tipos, como `[String]` e `[Int]` são. Uma função que recebe
um `Stack<Int>` não aceita um `Stack<String>`, e uma atribuição de um para o outro é recusada. O
compilador gera código para cada uso de que precisa, e é por isso que código genérico em Swift não
custa nada na execução quando os tipos são conhecidos: a pilha de inteiros é tão rápida quanto uma
escrita só para `Int`.

## Uma restrição no tipo, ou numa extensão

A struct em si não põe condição nenhuma em `Element`, então qualquer coisa pode ser empilhada. A
condição está na **extensão**: `where Element: Numeric` acrescenta `sum` só às pilhas de números.
Pôr a restrição na struct, `struct Stack<Element: Numeric>`, proibiria de vez uma pilha de strings.
**Restrinja o mais tarde possível**: no membro que precisa, e não no tipo inteiro.
