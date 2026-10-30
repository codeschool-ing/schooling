---
title: Propriedades do próprio tipo
version: 1
---

Toda propriedade até aqui pertencia a uma instância: cada sessão tem os seus minutos. Alguns fatos
pertencem ao tipo, um valor compartilhado por todas as instâncias: a meta semanal do planner, o número
de sessões criadas até agora. **Uma propriedade `static` pertence ao tipo**, é lida pelo nome do tipo
e existe uma vez, quantas instâncias houver, inclusive nenhuma:

```swift
// Static.swift
struct StudySession {
    static let weeklyGoal = 300
    static var created = 0
    var minutes: Int
    init(minutes: Int) {
        self.minutes = minutes
        StudySession.created += 1
    }
    func share() -> Double {
        Double(minutes) / Double(StudySession.weeklyGoal)
    }
}
print(StudySession.weeklyGoal, StudySession.created)
let monday = StudySession(minutes: 45)
let tuesday = StudySession(minutes: 60)
print(StudySession.created, monday.share(), tuesday.share())
```

```
ana@vm:~/sw/l06$ swift Static.swift
300 0
2 0.15 0.2
```

`StudySession.weeklyGoal` pôde ser lido antes de existir qualquer sessão, e `created` contou duas
instâncias. Escrever o inicializador à mão, como aqui, remove o memberwise, e a seção 07 diz como
manter os dois. Dentro do tipo, `Self.weeklyGoal` também funciona: `Self` com S maiúsculo nomeia o
tipo em que o código está.

Uma propriedade estática não é alcançável por uma instância, e o compilador diz isso:

```swift
// StaticSelf.swift
struct StudySession {
    static let weeklyGoal = 300
    var minutes: Int
    func share() -> Double {
        Double(minutes) / Double(weeklyGoal)
    }
}
```

```
ana@vm:~/sw/l06$ swiftc StaticSelf.swift -o staticself
StaticSelf.swift:6:34: error: static member 'weeklyGoal' cannot be used on instance of type 'StudySession'
4 |     var minutes: Int
5 |     func share() -> Double {
6 |         Double(minutes) / Double(weeklyGoal)
  |                                  `- error: static member 'weeklyGoal' cannot be used on instance of type 'StudySession'
7 |     }
8 | }
```

**Propriedades estáticas são lazy por natureza**: cada uma é inicializada na primeira vez que algo a
lê, e o Swift garante que isso acontece uma vez só mesmo quando duas threads a leem ao mesmo tempo.
Isso faz de um `static let` o lugar natural para uma constante compartilhada pelo programa inteiro, e
é o motivo de um `static var` pedir cuidado. Um `static var` é uma variável global com o nome de um
tipo, e a aula 15 mostra o compilador do Swift 6 recusando exatamente esse tipo de estado
compartilhado e mutável.
