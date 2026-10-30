---
title: O compilador confere a promessa
version: 1
---

Declarar `: Describable` é uma afirmação, e o compilador a confere antes de qualquer coisa rodar.
**Um tipo que deixa de cumprir um requisito não conforma, e nada é gerado.** Aqui uma sessão esquece
o resumo:

```swift
// Missing.swift
protocol Describable {
    var title: String { get }
    func summary() -> String
}

struct StudySession: Describable {
    var title: String
    var minutes: Int
}
```

```
ana@vm:~/sw/l08$ swiftc Missing.swift -o missing
Missing.swift:7:8: error: type 'StudySession' does not conform to protocol 'Describable'
 2 | protocol Describable {
 3 |     var title: String { get }
 4 |     func summary() -> String
   |          `- note: protocol requires function 'summary()' with type '() -> String'
 5 | }
 6 | 
 7 | struct StudySession: Describable {
   |        |- error: type 'StudySession' does not conform to protocol 'Describable'
   |        `- note: add stubs for conformance
 8 |     var title: String
 9 |     var minutes: Int
```

A mensagem vem em duas metades, como a aula 1 mostrou que a maioria vem. O `error` está na struct:
ela não conforma. A `note` acima dele aponta para dentro do protocolo, para o requisito que ninguém
cumpriu, com o tipo completo, `() -> String`. A segunda nota, "add stubs for conformance", é o que um
editor oferece como correção de um clique que escreve métodos vazios para você; o compilador
sozinho só os nomeia.

Um requisito é casado por **nome e tipo juntos**. Um `func summary() -> Substring`, ou um
`summary(short: Bool)`, é outro método e deixa o requisito sem cumprir, com o mesmo erro.

## Structs, classes e enums conformam

Qualquer tipo nomeado pode conformar, e cada um cumpre um requisito do seu jeito:

```swift
// Conform.swift
protocol Describable {
    var title: String { get }
    func summary() -> String
}

enum Level: Describable {
    case beginner, advanced
    var title: String { self == .beginner ? "Beginner" : "Advanced" }
    func summary() -> String { "level: \(title)" }
}

final class Planner: Describable {
    let owner: String
    init(owner: String) { self.owner = owner }
    var title: String { "\(owner)'s planner" }
    func summary() -> String { title }
}

let things: [any Describable] = [Level.beginner, Planner(owner: "Ana")]
for thing in things { print(thing.summary()) }
```

```
ana@vm:~/sw/l08$ swift Conform.swift
level: Beginner
Ana's planner
```

`Level` cumpre o requisito `title`, `{ get }`, com uma propriedade **calculada**, o que é permitido
porque o requisito só pedia para lê-la. `Planner` é uma classe, e uma classe cumpre os requisitos do
mesmo jeito; o `final` diz que nada herda dela, ponto a que a aula 10 volta. O array guarda um caso
de enum e uma instância de classe lado a lado, porque o que eles compartilham é o protocolo.

## Vários protocolos de uma vez

Um tipo pode conformar a quantos protocolos precisar, separados por vírgulas:
`struct StudySession: Describable, Equatable`. Uma classe que também tem superclasse a nomeia
primeiro. Não há limite, e na prática a maioria dos tipos de um app conforma a três ou quatro, quase
todos da biblioteca padrão, que é o assunto da seção 06.
