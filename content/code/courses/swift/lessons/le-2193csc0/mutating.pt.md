---
title: mutating, e o let que vale de verdade
version: 1
---

Os métodos de uma struct podem ler as propriedades dela à vontade. **Um método que as muda precisa
dizer isso, com `mutating`**, e essa palavra deixa o compilador aplicar o `let` às structs até o fim.
O registro de minutos de uma semana, com um método para acrescentar uma sessão, escrito sem ela:

```swift
// Mutating.swift
struct Week {
    var minutes: [Int] = []
    func add(_ session: Int) {
        minutes.append(session)
    }
}
```

```
ana@vm:~/sw/l05$ swiftc Mutating.swift -o mutating
Mutating.swift:5:17: error: cannot use mutating member on immutable value: 'self' is immutable
2 | struct Week {
3 |     var minutes: [Int] = []
4 |     func add(_ session: Int) {
  |     `- note: mark method 'mutating' to make 'self' mutable
5 |         minutes.append(session)
  |                 `- error: cannot use mutating member on immutable value: 'self' is immutable
6 |     }
7 | }
```

Dentro de um método comum, `self`, o valor em que o método foi chamado, é uma constante, exatamente
como um parâmetro. `minutes.append` muda o `self`, então o compilador recusa, e a nota dele dá a
correção. O `= []` depois da propriedade é um valor padrão; o inicializador memberwise então deixa
você omitir esse argumento, e `Week()` é uma semana sem sessões.

Com o `mutating` no lugar, o método compila e funciona num `var`:

```swift
// WeekLog.swift
struct Week {
    var minutes: [Int] = []
    mutating func add(_ session: Int) {
        minutes.append(session)
    }
    func total() -> Int {
        minutes.reduce(0, +)
    }
}
var week = Week()
week.add(45)
week.add(30)
print(week.minutes, week.total())
```

```
ana@vm:~/sw/l05$ swiftc WeekLog.swift -o weeklog && ./weeklog
[45, 30] 75
```

Agora o mesmo tipo, guardado num `let`:

```swift
// Frozen.swift
struct Week {
    var minutes: [Int] = []
    mutating func add(_ session: Int) {
        minutes.append(session)
    }
    func total() -> Int {
        minutes.reduce(0, +)
    }
}
let frozen = Week(minutes: [45, 30])
print(frozen.total())
frozen.add(60)
```

```
ana@vm:~/sw/l05$ swiftc Frozen.swift -o frozen
Frozen.swift:13:8: error: cannot use mutating member on immutable value: 'frozen' is a 'let' constant
 9 |     }
10 | }
11 | let frozen = Week(minutes: [45, 30])
   | `- note: change 'let' to 'var' to make it mutable
12 | print(frozen.total())
13 | frozen.add(60)
   |        `- error: cannot use mutating member on immutable value: 'frozen' is a 'let' constant
14 | 
```

**Esta recusa é a útil.** `frozen` é um `let`, e `add` é `mutating`, então o compilador não o chama:
uma struct `let` não muda de jeito nenhum, nem por uma propriedade nem por um método. É a garantia
que a seção 05 disse que uma classe não consegue dar, e o `mutating` é o que a torna verificável. O
`total` não é mutating e funciona num `let` como num `var`. O `reduce(0, +)` soma os minutos, e a
lição 4 o explicou.

Uma classe não tem `mutating`. Os métodos dela sempre podem mudar suas propriedades, e é por isso que
`let` numa classe só prende a referência. A palavra é o sinal visível da diferença: **ler
`mutating` diz que um método de struct muda o valor em que foi chamado**, e a ausência dela diz que
não muda.
