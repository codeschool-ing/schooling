---
title: Um protocolo diz o quê, nunca o como
version: 1
---

Um planner mostra cursos e sessões de estudo na mesma lista, e cada um precisa de uma linha de texto
para isso. Os dois tipos não têm mais nada em comum: um curso tem lições, uma sessão tem minutos.
**Um protocolo nomeia o que um conjunto de tipos promete oferecer, e não diz nada sobre como cada um
oferece.** É uma lista de requisitos, e um tipo que os cumpre **conforma** ao protocolo.

```swift
// Describable.swift
protocol Describable {
    var title: String { get }
    func summary() -> String
}

struct Course: Describable {
    var title: String
    var lessons: Int
    func summary() -> String { "\(title): \(lessons) lessons" }
}

struct StudySession: Describable {
    var title: String
    var minutes: Int
    func summary() -> String { "\(title), \(minutes) min" }
}

func printAll(_ items: [any Describable]) {
    for item in items {
        print("-", item.summary())
    }
}

printAll([
    Course(title: "Swift", lessons: 20),
    StudySession(title: "Optionals", minutes: 45),
    StudySession(title: "Closures", minutes: 30),
])
```

```
ana@vm:~/sw/l08$ swift Describable.swift
- Swift: 20 lessons
- Optionals, 45 min
- Closures, 30 min
```

Leia o protocolo de cima para baixo. `var title: String { get }` exige uma propriedade chamada
`title`, do tipo `String`, que possa ser **lida**. Não diz que a propriedade é armazenada: um tipo pode
calculá-la. `{ get set }` exigiria uma que também pudesse ser escrita. `func summary() -> String`
exige um método exatamente com esse nome e esse tipo, e o protocolo não tem corpo para ele, só a
assinatura.

`Course: Describable` depois do nome do tipo declara a conformidade, no mesmo lugar em que uma classe
nomearia a superclasse. O compilador então confere a promessa, e a seção 03 mostra isso falhando.

## Um protocolo também é um tipo

`printAll` recebe `[any Describable]`: um array cujos elementos podem ser de qualquer tipo, desde que
cada um conforme. Dentro do laço o código só sabe o que o protocolo promete, então `item.summary()`
compila e `item.lessons` não compilaria, porque nem toda coisa descritível tem lições. A palavra
`any` marca um valor cujo tipo concreto só é conhecido enquanto o programa roda; a lição 9 diz quanto
isso custa e quando escrever `some` no lugar.

## O que um protocolo não é

Um protocolo **não tem armazenamento** próprio e não pode ser criado: `Describable()` não significa
nada, porque não há nada para criar. Essa é a primeira diferença em relação a uma superclasse, que é
um tipo com campos e corpo. Structs e enums não herdam de jeito nenhum, então para eles um protocolo
é o único jeito de ser tratado como parte de uma família, e é por isso que a biblioteca padrão do
Swift é construída com protocolos e não com hierarquias de classes. A lição 10 transforma essa
observação num jeito de projetar.
