---
title: Propriedades armazenadas
version: 1
---

Os tipos da aula 5 guardavam os dados em **propriedades armazenadas**: um nome e um tipo dentro das
chaves do tipo, com espaço reservado para elas em toda instância. Esta aula é sobre as quatro outras
coisas que uma propriedade pode ser, e começa fixando a comum, porque dois detalhes dela decidem para
que servem as outras.

```swift
// Stored.swift
struct StudySession {
    let course: String
    var minutes: Int
    var done = false
}
var monday = StudySession(course: "Swift", minutes: 45)
monday.done = true
monday.minutes += 15
print(monday)
let tuesday = StudySession(course: "Swift", minutes: 30, done: true)
print(tuesday.done)
```

```
ana@vm:~/sw/l06$ swift Stored.swift
StudySession(course: "Swift", minutes: 60, done: true)
true
```

`monday` é uma variável, e o `done` e o `minutes` dela mudaram. O curso não pode:

```swift
// Course.swift
struct StudySession {
    let course: String
    var minutes: Int
}
var monday = StudySession(course: "Swift", minutes: 45)
monday.course = "Kotlin"
```

```
ana@vm:~/sw/l06$ swiftc Course.swift -o course
Course.swift:7:8: error: cannot assign to property: 'course' is a 'let' constant
1 | // Course.swift
2 | struct StudySession {
3 |     let course: String
  |     `- note: change 'let' to 'var' to make it mutable
4 |     var minutes: Int
5 | }
6 | var monday = StudySession(course: "Swift", minutes: 45)
7 | monday.course = "Kotlin"
  |        `- error: cannot assign to property: 'course' is a 'let' constant
8 | 
```

**Uma propriedade `let` é definida uma vez, quando a instância é criada, e nunca mais**, mesmo numa
instância `var`. É o formato certo para uma sessão: os minutos são corrigidos depois, e uma sessão
que mudou de curso é outra sessão.

**Um valor padrão torna o argumento opcional.** `var done = false` dá ao inicializador memberwise um
argumento `done:` com esse padrão, então `monday` foi criado sem ele e `tuesday` com ele. Um `let`
com valor padrão não ganha argumento nenhum, já que nada poderia lhe dar outro valor.

## Onde mora o armazenamento

Uma propriedade armazenada de uma struct faz parte do valor: copie a struct e você copia a
propriedade, como a aula 5 mediu. Uma propriedade armazenada de uma classe mora na única instância
no heap. Nada mais na declaração muda, e **todo tipo de propriedade desta aula existe nas duas**,
com uma exceção nomeada na seção 05.
