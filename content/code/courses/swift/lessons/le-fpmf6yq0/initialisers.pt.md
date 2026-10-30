---
title: Inicializadores
version: 1
---

Um inicializador tem um trabalho: **toda propriedade armazenada tem um valor antes de a instância ser
usada.** O compilador verifica essa regra em todo caminho de todo `init`, e o resto desta seção é o
que decorre dela. Uma classe que esquece uma propriedade:

```swift
// Unset.swift
final class Planner {
    let owner: String
    var goal: Int
    init(owner: String) {
        self.owner = owner
    }
}
```

```
ana@vm:~/sw/l06$ swiftc Unset.swift -o unset
Unset.swift:7:5: error: return from initializer without initializing all stored properties
2 | final class Planner {
3 |     let owner: String
4 |     var goal: Int
  |         `- note: 'self.goal' not initialized
5 |     init(owner: String) {
6 |         self.owner = owner
7 |     }
  |     `- error: return from initializer without initializing all stored properties
8 | }
9 | 
```

A nota aponta para `goal`, que nenhuma linha do inicializador definiu. Um valor padrão na
propriedade, ou uma linha no `init`, a satisfaria. Uma propriedade `let` pode ser definida no
inicializador e em nenhum outro lugar: o `init` é o único lugar em que uma constante ainda não está
fixada.

## Mantendo o inicializador memberwise

A seção 06 descobriu que escrever um `init` dentro de uma struct remove o que o compilador escreve.
**Um inicializador escrito numa extensão o mantém.** Uma extensão acrescenta a um tipo de fora das
chaves principais dele, e a lição 8 é sobre elas; aqui ela é só um lugar para pôr uma segunda
entrada:

```swift
// Extra.swift
struct StudySession {
    var course: String
    var minutes: Int
}
extension StudySession {
    init(hours: Double, course: String) {
        self.init(course: course, minutes: Int(hours * 60))
    }
}
let a = StudySession(course: "Swift", minutes: 45)
let b = StudySession(hours: 1.5, course: "Swift")
print(a.minutes, b.minutes)
```

```
ana@vm:~/sw/l06$ swift Extra.swift
45 90
```

`self.init(course:minutes:)` passa o trabalho ao inicializador memberwise, então a regra é verificada
num lugar só. Um inicializador que chama outro do mesmo tipo se chama **delegante**.

## Um inicializador que pode falhar

Uma sessão construída a partir do texto que uma estudante digitou pode não ter minutos válidos.
**`init?` é um inicializador que pode devolver `nil`**, e o que ele cria é um opcional, exatamente
como `Int("45")` deu um `Int?` na lição 1:

```swift
// Failable.swift
struct StudySession {
    var course: String
    var minutes: Int
}
extension StudySession {
    init?(course: String, typed: String) {
        guard let minutes = Int(typed), minutes > 0, minutes <= 600 else { return nil }
        self.init(course: course, minutes: minutes)
    }
}
let good = StudySession(course: "Swift", typed: "45")
let bad = StudySession(course: "Swift", typed: "forty")
let silly = StudySession(course: "Swift", typed: "9000")
print(good?.minutes ?? -1, bad?.minutes ?? -1, silly?.minutes ?? -1)
```

```
ana@vm:~/sw/l06$ swift Failable.swift
45 -1 -1
```

`guard … else { return nil }` é a saída antecipada da lição 2, e o `return nil` é a falha. A
verificação que o observador da seção 04 não conseguia fazer na inicialização é feita aqui, antes de
o valor existir. **Um inicializador que falha é como um tipo se recusa a existir num estado
inválido**: o código que recebe uma `StudySession` sabe que os minutos dela estão entre 1 e 600,
porque nenhum outro jeito de criar uma é oferecido.
