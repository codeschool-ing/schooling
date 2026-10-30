---
title: open, para as classes que outros podem estender
version: 1
---

`public` deixa outro módulo **usar** uma classe. Não deixa esse módulo **herdar** dela, nem
sobrescrever os métodos dela, e isso surpreende quem vem de uma linguagem em que qualquer classe
visível pode ser estendida. **No Swift, estender uma classe de fora do módulo dela é uma permissão
separada, e ela se chama `open`.**

A biblioteca do planner ganha um lembrete, uma classe porque a aula 10 guardou a herança para
exatamente este tipo de coisa, um comportamento padrão que outro código pode refinar:

```swift
// Sources/PlannerCore/Reminder.swift
public class Reminder {
    public init() {}
    public func text() -> String { "study today" }
}
```

e o executável tenta fazer um mais barulhento:

```swift
// Sources/plan/main.swift
import PlannerCore

final class Loud: Reminder {
    override func text() -> String { "STUDY TODAY" }
}

let reminders: [Reminder] = [Reminder(), Loud()]
for reminder in reminders {
    print(reminder.text())
}
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Provisioning 1 / 4]
[Planning deferred tasks]
[6 / 10] PlannerCore
error: SwiftCompile normal x86_64 /home/ana/sw/l17/planner/Sources/plan/main.swift failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    builtin-SwiftPerFileCompile main.swift
/home/ana/sw/l17/planner/Sources/plan/main.swift:5:19: error: overriding non-open instance method outside of its defining module
 3 | 
 4 | final class Loud: Reminder {
 5 |     override func text() -> String { "STUDY TODAY" }
   |                   `- error: overriding non-open instance method outside of its defining module
 6 | }
 7 | 

/home/ana/sw/l17/planner/Sources/plan/main.swift:4:13: error: cannot inherit from non-open class 'Reminder' outside of its defining module
 2 | import PlannerCore
 3 | 
 4 | final class Loud: Reminder {
   |             `- error: cannot inherit from non-open class 'Reminder' outside of its defining module
 5 |     override func text() -> String { "STUDY TODAY" }
 6 | }
error: SwiftCompile normal x86_64 failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    
/home/ana/sw/l17/planner/Sources/plan/main.swift:5:19: error: overriding non-open instance method outside of its defining module
 3 | 
 4 | final class Loud: Reminder {
 5 |     override func text() -> String { "STUDY TODAY" }
   |                   `- error: overriding non-open instance method outside of its defining module
 6 | }
 7 | 

/home/ana/sw/l17/planner/Sources/plan/main.swift:4:13: error: cannot inherit from non-open class 'Reminder' outside of its defining module
 2 | import PlannerCore
 3 | 
 4 | final class Loud: Reminder {
   |             `- error: cannot inherit from non-open class 'Reminder' outside of its defining module
 5 |     override func text() -> String { "STUDY TODAY" }
 6 | }
error: Build failed
```

Duas recusas, cada uma impressa duas vezes pelo motivo que a seção 04 deu, e são duas decisões. A
classe não pode ser herdada fora do `PlannerCore`, porque é `public` e não `open`; e mesmo que
pudesse, `text()` não pode ser sobrescrito, porque o método também é só `public`. **Uma classe
`open` ainda mantém fechado todo método que não for `open` também.** Abra os dois:

```swift
// Sources/PlannerCore/Reminder.swift
open class Reminder {
    public init() {}
    open func text() -> String { "study today" }
}
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Using on-disk description]
[4 / 7] PlannerCore
[13 / 17] plan-product
[18 / 18] plan-product
Build complete! (1.00 secs)
ana@vm:~/sw/l17/planner$ .build/debug/plan
study today
STUDY TODAY
```

O array guarda dois valores `Reminder`, e o laço chama `text()` em cada um: o segundo roda a
sobrescrita do `plan`, um módulo do qual o `PlannerCore` não sabe nada.

## Por que o padrão é fechado

Uma classe que pode ser herdada de fora tem dois públicos: o código que a chama e o código que
substitui partes dela. O segundo é a promessa mais difícil de cumprir. Se `Reminder` passar a chamar
`text()` de um método novo, toda subclasse em qualquer lugar agora roda dentro desse método, e um
autor de biblioteca que não planejou isso mudou programas de outras pessoas sem tocar neles. **Por
isso o Swift pede ao autor que diga, por classe e por método, que partes foram projetadas para ser
substituídas.**

Dentro de um módulo nada muda: uma classe `internal` ou `public` pode ser herdada e ter os métodos
sobrescritos por qualquer código do mesmo módulo, e `open` não acrescentaria nada. Para proibir isso
também, marque a classe como `final`, como `Loud` está: uma classe `final` não pode ser herdada em
lugar nenhum, nem no próprio módulo, e o compilador pode chamar os métodos dela diretamente em vez de
procurá-los.

`open` vale só para classes e seus membros. Structs, enums e protocolos não têm subclasses, então
para eles `public` é o nível mais largo que existe.
