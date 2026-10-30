---
title: Apagar e mover pelo id, com testes
version: 1
---

**Uma lista informa uma edição em posições, e o plano tem de aplicá-la pela identidade.** O
`onDelete` entrega um `IndexSet`; o `onMove` entrega um `IndexSet` e um destino. Os dois contam linhas
da coleção que o `ForEach` recebeu, que na tela de curso são as sessões de um curso filtradas do
plano. Aplique esses números direto em `plan.sessions` e você apaga ou move outra sessão, muitas vezes
uma de um curso que a pessoa nem estava olhando.

O lado do `List` nisto precisa do SwiftUI. A aritmética não, então ela vai para o pacote e é testada
em qualquer computador. Copie o pacote da aula 1 para esta aula, `cp -r ~/planner ~/editing`, e
acrescente `Sources/PlannerCore/PlanEditing.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/PlanEditing.swift", "parts": [{"code": "// Sources/PlannerCore/PlanEditing.swift\nimport Foundation\n\nextension Plan {\n    /// One course's sessions, in the order the course screen shows them.\n    public func sessions(of courseID: String) -> [StudySession] {\n        sessions.filter { $0.courseID == courseID }\n    }\n", "note": "O que a tela de curso mostra. Mantê-lo como uma função do plano faz a tela e os testes abaixo montarem o `shown` do mesmo jeito."}, {"code": "    /// Delete the rows at `offsets` of a screen that showed `shown`.\n    public mutating func delete(at offsets: IndexSet, in shown: [StudySession]) {\n        let ids = Set(offsets.map { shown[$0].id })\n        sessions.removeAll { ids.contains($0.id) }\n    }\n", "note": "A tradução de posições para identidade, feita uma vez, na borda: posições no que foi mostrado viram ids, e o plano apaga pelo id. O `IndexSet` é do Foundation, o tipo que o `onDelete` entrega."}, {"code": "    /// Move rows of a screen that showed `shown`, as a list reports a drag:\n    /// the rows at `offsets` go before the row that was at `destination`.\n    public mutating func move(from offsets: IndexSet, to destination: Int, in shown: [StudySession]) {\n        var order = shown.map(\\.id)\n        let moving = offsets.map { order[$0] }\n        let above = offsets.filter { $0 < destination }.count\n        order.removeAll { moving.contains($0) }\n        order.insert(contentsOf: moving, at: destination - above)\n", "note": "O `onMove` informa um arrasto como as posições movidas e um destino contado na lista *antes* do movimento. Linhas tiradas de cima do destino o deslocam uma posição para cima cada uma, e é isso que o `above` corrige."}, {"code": "        let slots = sessions.indices.filter { i in order.contains(sessions[i].id) }\n        let byID = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })\n        for (slot, id) in zip(slots, order) {\n            sessions[slot] = byID[id]!\n        }\n    }\n}\n", "note": "Escreva a nova ordem de volta nos lugares que as sessões deste curso ocupavam no plano inteiro, para as sessões do outro curso não se mexerem. O force unwrap não tem como falhar: todo id em `order` veio de `sessions`."}]}
```

O `Array.move(fromOffsets:toOffset:)` e o `remove(atOffsets:)` do próprio SwiftUI, que os exemplos da
Apple usam com `onMove` e `onDelete`, são extensões que vêm com o SwiftUI, então não estão no Linux.
As poucas linhas acima fazem o mesmo trabalho e dizem o que estão fazendo.

Depois, três testes. Salve isto como `Tests/PlannerCoreTests/EditingTests.swift`:

```swift
// Tests/PlannerCoreTests/EditingTests.swift
import Foundation
import Testing
@testable import PlannerCore

func fourSessions() -> Plan {
    Plan(
        courses: [Course(id: "sql", title: "SQL Databases"), Course(id: "mobile", title: "Mobile Fundamentals")],
        sessions: [
            StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50),
            StudySession(id: "s2", courseID: "mobile", date: "2026-10-20", minutes: 40),
            StudySession(id: "s3", courseID: "sql", date: "2026-10-23", minutes: 60),
            StudySession(id: "s4", courseID: "sql", date: "2026-10-24", minutes: 30),
        ]
    )
}

@Test func aScreenOffsetIsNotAPlanIndex() {
    var plan = fourSessions()
    plan.sessions.remove(at: 1)                  // the SQL screen's row 1 is s3...
    #expect(plan.sessions.map(\.id) == ["s1", "s3", "s4"])
}

@Test func deletingFromTheCourseScreenDeletesWhatWasShown() {
    var plan = fourSessions()
    let shown = plan.sessions(of: "sql")         // s1, s3, s4
    plan.delete(at: [1], in: shown)
    #expect(plan.sessions.map(\.id) == ["s1", "s2", "s4"])
}

@Test func movingWithinACourseLeavesTheOtherCourseInPlace() {
    var plan = fourSessions()
    let shown = plan.sessions(of: "sql")         // s1, s3, s4
    plan.move(from: [2], to: 0, in: shown)       // drag s4 to the top
    #expect(plan.sessions(of: "sql").map(\.id) == ["s4", "s1", "s3"])
    #expect(plan.sessions.map(\.id) == ["s4", "s2", "s1", "s3"])
}
```

```
ana@vm:~/editing$ swift test --filter Editing
Building for debugging...
[Pre-planning 1 / 153]
[Starting]
Build complete! (0.68 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Test aScreenOffsetIsNotAPlanIndex() started.
◇ Test movingWithinACourseLeavesTheOtherCourseInPlace() started.
◇ Test deletingFromTheCourseScreenDeletesWhatWasShown() started.
✔ Test aScreenOffsetIsNotAPlanIndex() passed after 0.001 seconds.
✔ Test movingWithinACourseLeavesTheOtherCourseInPlace() passed after 0.001 seconds.
✔ Test deletingFromTheCourseScreenDeletesWhatWasShown() passed after 0.001 seconds.
✔ Test run with 3 tests in 0 suites passed after 0.001 seconds.
```

**O primeiro teste passa, e o que ele fixa é o bug.** A linha 1 da tela de SQL é `s3`; a posição 1 do
plano inteiro é `s2`, a sessão de mobile, e foi ela que o `remove(at: 1)` levou. O segundo apaga `s3`
como a pessoa queria. O terceiro arrasta `s4` para o topo da tela de SQL e confere duas coisas: as
sessões de SQL saem na ordem arrastada, e `s2`, que é do outro curso, continua em segundo no plano. O
`--filter Editing` rodou estes três e deixou os da aula 1 de lado.

Na tela as chamadas são uma linha cada, dentro do `onDelete` e do `onMove` no `ForEach`, passando o
mesmo `shown` que o `ForEach` recebeu. Não executado aqui: elas precisam do SwiftUI.
