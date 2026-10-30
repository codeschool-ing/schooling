---
title: Extensões acrescentam a um tipo que você não escreveu
version: 1
---

Uma **extensão** acrescenta métodos, propriedades calculadas e conformidades a um tipo que já existe,
inclusive um da biblioteca padrão. Ela é escrita separada do tipo, muitas vezes em outro arquivo, e
depois de compilada os membros novos parecem exatamente os originais:

```swift
// Hours.swift
extension Int {
    var asHours: String {
        let h = self / 60, m = self % 60
        return m == 0 ? "\(h)h" : "\(h)h\(m)"
    }
}

let week = [45, 30, 60, 90]
let total = week.reduce(0, +)
print(total.asHours)
print(300.asHours, 45.asHours)
```

```
ana@vm:~/sw/l08$ swift Hours.swift
3h45
5h 0h45
```

`Int` pertence à biblioteca padrão, e o planner acabou de lhe dar uma propriedade. Dentro da
extensão, `self` é o inteiro a que a propriedade foi pedida, então `300.asHours` se lê como uma frase
e não precisa de uma função auxiliar com um nome para lembrar. O `reduce(0, +)` da lição 3 soma a
semana.

## O que uma extensão não pode acrescentar

**Uma extensão acrescenta comportamento e nunca armazenamento.** Uma propriedade armazenada mudaria o
tamanho de todo `Int` já na memória, e o compilador a recusa:

```swift
// Stored.swift
extension Int {
    var label: String = ""
}
```

```
ana@vm:~/sw/l08$ swiftc Stored.swift -o stored
Stored.swift:3:9: error: extensions must not contain stored properties
1 | // Stored.swift
2 | extension Int {
3 |     var label: String = ""
  |         `- error: extensions must not contain stored properties
4 | }
5 | 
```

Propriedades calculadas, métodos, inicializadores, tipos aninhados e subscripts são todos
permitidos, porque nenhum deles precisa de um byte a mais em cada valor.

## Conformar numa extensão

Uma extensão também pode acrescentar uma **conformidade**. É o jeito comum de manter os campos do
tipo num bloco e cada protocolo que ele cumpre num bloco próprio:

```swift
// Retro.swift
protocol Describable {
    var title: String { get }
    func summary() -> String
}

struct Course {
    var title: String
    var lessons: Int
}

extension Course: Describable {
    func summary() -> String { "\(title): \(lessons) lessons" }
}

let swift: any Describable = Course(title: "Swift", lessons: 20)
print(swift.summary())
```

```
ana@vm:~/sw/l08$ swift Retro.swift
Swift: 20 lessons
```

`Course` foi escrito sem protocolo nenhum. A extensão declara a conformidade e fornece o único método
que faltava; `title` já estava lá, e o compilador o conta. **Isso funciona também para tipos que não
são seus**, e é assim que o tipo de uma biblioteca passa a servir ao seu protocolo sem que a
biblioteca mude.
