---
title: Protocolos com um tipo em aberto
version: 1
---

Os protocolos da lição 8 nomeavam cada tipo por inteiro: `title` é uma `String`, `summary()` devolve
uma `String`. Alguns protocolos não conseguem. O planner guarda sessões num repositório, guarda
cursos em outro, e um teste da lição 18 vai querer um repositório de números simples; as operações
são as mesmas e o tipo da coisa guardada muda. **Um tipo associado é um parâmetro de tipo que pertence
a um protocolo**, e cada tipo que conforma decide qual é.

```swift
// Store.swift
protocol Store {
    associatedtype Item
    var all: [Item] { get }
    mutating func add(_ item: Item)
}

struct StudySession {
    var course: String
    var minutes: Int
}

struct SessionStore: Store {
    var all: [StudySession] = []
    mutating func add(_ item: StudySession) { all.append(item) }
}

struct CourseList: Store {
    typealias Item = String
    var all: [String] = []
    mutating func add(_ item: String) {
        if !all.contains(item) { all.append(item) }
    }
}

func fill<S: Store>(_ store: inout S, with items: [S.Item]) {
    for item in items { store.add(item) }
}

var sessions = SessionStore()
fill(&sessions, with: [StudySession(course: "Swift", minutes: 45),
                       StudySession(course: "Swift", minutes: 30)])
var courses = CourseList()
fill(&courses, with: ["Swift", "Kotlin", "Swift"])
print(sessions.all.count, courses.all)
```

```
ana@vm:~/sw/l09$ swift Store.swift
2 ["Swift", "Kotlin"]
```

O `associatedtype Item` deixa o tipo guardado em aberto. `SessionStore` nunca diz qual é o seu `Item`:
o compilador o lê de `add(_ item: StudySession)` e de `[StudySession]`, que precisam concordar.
`CourseList` escreve `typealias Item = String` para dizer com todas as letras, o que é permitido e só
necessário quando nada mais o define. Cada tipo que conforma tem **um** `Item`, fixado quando conforma;
uma `CourseList` guarda strings e nada mais.

## Usando um a partir de uma função genérica

O `fill` é genérico sobre qualquer repositório, `S: Store`, e o segundo parâmetro é `[S.Item]`: um
array do que quer que aquele repositório guarde. Leia a assinatura como uma frase, "para qualquer
repositório, um array dos itens dele", e as chamadas se verificam sozinhas. Passar cursos para
`sessions` seria recusado, porque o `SessionStore.Item` é `StudySession`. O `inout` e o `&` da lição
3 deixam o `fill` mudar o repositório que recebeu; o `if !all.contains(item)` é o motivo de a
`CourseList` ter guardado `"Swift"` uma vez só.

## Onde a biblioteca padrão faz isso

`Collection` é um protocolo com tipos associados, `Element` entre eles, e `Sequence`,
`IteratorProtocol` e `Identifiable` são outros. É por isso que o `C.Element == Int` da seção 03 pôde
ser escrito: uma restrição pode nomear um tipo associado e fixá-lo. **Tipos associados são o que deixa
um protocolo descrever "uma coleção de alguma coisa" sem dizer de quê**, e quase todo algoritmo
genérico da biblioteca padrão é escrito contra um deles.

O preço é que um protocolo assim é desajeitado de usar como tipo comum, já que um valor de "algum
repositório" não diz nada sobre o que entra nele. A seção 07 mostra exatamente onde isso pega.
