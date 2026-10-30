---
title: Sendable, o que pode atravessar
version: 1
---

Um ator protege o que está dentro dele. O que viaja entre tarefas e atores ainda precisa de uma regra,
porque um valor passado para uma tarefa fica alcançável de dois lugares. **`Sendable` é o protocolo de
um tipo cujos valores podem ser divididos com segurança entre código concorrente**, e o compilador
decide a maior parte disso por você a partir do que o tipo é feito.

**Um tipo de valor feito de partes `Sendable` já é `Sendable`.** Um `struct` de `String`s e `Int`s é
copiado quando é passado, como a lição 5 mostrou, então a tarefa recebe uma cópia que ninguém mais
alcança. Uma classe com um `var` é o contrário: passá-la entrega uma referência ao mesmo objeto, e os
dois lados podem escrever. Este programa manda um de cada para uma tarefa destacada:

```swift
// Sendables.swift
struct StudySession {
    let course: String
    var minutes: Int
}

final class Draft {
    var note = ""
}

func save(_ session: StudySession) async {
    print("saved \(session.course), \(session.minutes) minutes")
}

func keep(_ draft: Draft) async {
    print("kept \"\(draft.note)\"")
}

func start() async {
    let session = StudySession(course: "Swift", minutes: 45)
    let draft = Draft()
    let saving = Task.detached { await save(session) }
    let keeping = Task.detached { await keep(draft) }
    draft.note = "chapter 3"
    await saving.value
    await keeping.value
}

await start()
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Sendables.swift -o sendables && ./sendables
Sendables.swift:23:24: error: sending value of non-Sendable type '() async -> ()' risks causing data races [#RegionIsolation::SendingRisksDataRace]
21 |     let draft = Draft()
22 |     let saving = Task.detached { await save(session) }
23 |     let keeping = Task.detached { await keep(draft) }
   |                        |- error: sending value of non-Sendable type '() async -> ()' risks causing data races [#RegionIsolation::SendingRisksDataRace]
   |                        `- note: Passing value of non-Sendable type '() async -> ()' as a 'sending' argument to static method 'detached(name:priority:operation:)' risks causing races in between local and caller code
24 |     draft.note = "chapter 3"
   |                `- note: access can happen concurrently
25 |     await saving.value
26 |     await keeping.value

[#RegionIsolation]: <https://docs.swift.org/compiler/documentation/diagnostics/region-isolation>
[#SendingRisksDataRace]: <https://docs.swift.org/compiler/documentation/diagnostics/sending-risks-data-race>
```

**Um erro, e é sobre o rascunho, não sobre a sessão.** O `StudySession` atravessou sem comentário. O
problema é a closure que segura `draft`, e a segunda nota diz exatamente por quê: `draft.note =
"chapter 3"` na linha 24 roda enquanto a tarefa destacada pode estar lendo o mesmo objeto. O
compilador não recusou classes como tal. Recusou uma classe **usada dos dois lados** da fronteira.

## Entregar um valor

Esse último ponto é o **isolamento por regiões** do compilador do Swift 6 trabalhando: ele acompanha
quais valores são alcançáveis de qual contexto, e deixa um valor que não é `Sendable` atravessar quando
o código que o enviou nunca mais o toca. Escreva a nota antes e pare de usar `draft` depois da
entrega, e os mesmos tipos compilam:

```swift
// Handover.swift
struct StudySession {
    let course: String
    var minutes: Int
}

final class Draft {
    var note = ""
}

func save(_ session: StudySession) async {
    print("saved \(session.course), \(session.minutes) minutes")
}

func keep(_ draft: Draft) async {
    print("kept \"\(draft.note)\"")
}

func start() async {
    let session = StudySession(course: "Swift", minutes: 45)
    let draft = Draft()
    draft.note = "chapter 3"
    let saving = Task.detached { await save(session) }
    let keeping = Task.detached { await keep(draft) }
    await saving.value
    await keeping.value
}

await start()
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Handover.swift -o handover && ./handover
saved Swift, 45 minutes
kept "chapter 3"
```

**Enviar é uma entrega, e o compilador confere que a entrega é de verdade.** O rascunho agora tem um
dono por vez: `start` até a tarefa ser criada, a tarefa depois.

## Declarar, e a classe que pode

Um tipo dividido de verdade, seguro por várias tarefas ao mesmo tempo, tem de ser ele mesmo
`Sendable`. Para um `struct` ou um `enum` o compilador infere isso dentro de um módulo; um tipo tornado
`public` para outros módulos, que é o assunto da lição 17, escreve `: Sendable` para que a promessa
faça parte da interface dele. Uma classe só pode declará-lo quando é `final` e toda propriedade
armazenada é um `let` de um tipo `Sendable`, para que nada nela possa mudar depois de criada:

```swift
// Course.swift
final class Course: Sendable {
    let name: String
    var goal: Int
    init(name: String, goal: Int) {
        self.name = name
        self.goal = goal
    }
}
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Course.swift -o course
Course.swift:4:9: error: stored property 'goal' of 'Sendable'-conforming class 'Course' is mutable
 2 | final class Course: Sendable {
 3 |     let name: String
 4 |     var goal: Int
   |         `- error: stored property 'goal' of 'Sendable'-conforming class 'Course' is mutable
 5 |     init(name: String, goal: Int) {
 6 |         self.name = name
```

Troque `var goal` por `let goal` e compila. Uma classe cujo estado precisa mesmo mudar e ser dividido
é o caso para um ator.

**`@unchecked Sendable` existe**, e desliga a verificação: é uma promessa, escrita por você, de que a
classe protege o próprio estado, com um lock por exemplo, e o compilador acredita. Bibliotecas
anteriores ao Swift 6 o usam em tipos que tornaram seguros à mão. No seu código, todo `@unchecked` é
um lugar em que o compilador parou de olhar e uma corrida pode voltar, então trate-o como trata o `!`
da lição 2.
