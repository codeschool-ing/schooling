---
title: A validação mora no pacote
version: 1
---

**Um formulário são duas coisas que parecem uma: o que a pessoa digitou, e o valor que o app vai
guardar.** A crença a largar é que um campo de texto guarda um número. Ele guarda texto, o tempo todo,
inclusive no momento em que mostra `4` a caminho de `45` e no momento em que está vazio porque alguém
apagou o valor antigo para digitar um novo. Validar é o passo que transforma o primeiro no segundo, ou
diz por que não dá, e é Swift puro. Então ele vai no pacote do planner, onde roda e é testado em
qualquer computador, e o `SessionForm` só mostra o que ele decide.

O pacote desta aula é o da aula 1, num diretório próprio, `~/l10`, com mais um arquivo de código, mais
um arquivo de testes e mais um pequeno programa. Copie para ele os cinco arquivos da aula 1, depois
troque o `Package.swift` por este, que acrescenta o programa `draft`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Planner",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PlannerCore", targets: ["PlannerCore"]),
    ],
    targets: [
        .target(name: "PlannerCore"),
        .executableTarget(name: "week", dependencies: ["PlannerCore"]),
        .executableTarget(name: "draft", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

## O rascunho

Salve isto como `Sources/PlannerCore/SessionDraft.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/SessionDraft.swift", "parts": [{"code": "// Sources/PlannerCore/SessionDraft.swift\nimport Foundation\n\n/// What the session form holds while somebody is typing: text, not yet a session.\npublic struct SessionDraft: Equatable, Sendable {\n    public var courseID: String?\n    public var date: Date\n    public var minutesText: String\n\n    public init(courseID: String? = nil, date: Date, minutesText: String = \"\") {\n        self.courseID = courseID\n        self.date = date\n        self.minutesText = minutesText\n    }\n}\n\n", "note": "O estado do formulário é um **rascunho**: o curso escolhido, o instante que o seletor de data guarda, e os minutos como o texto que alguém digitou. Nada disso é uma `StudySession` ainda, e manter os dois tipos separados é o que impede um formulário digitado pela metade de chegar ao plano."}, {"code": "public enum DraftProblem: Equatable, Sendable {\n    case noCourse\n    case noMinutes\n    case minutesNotWhole(String)\n    case minutesOutOfRange(Int)\n}\n\n", "note": "As quatro coisas que podem estar erradas, como valores. Um formulário pode mostrar uma mensagem para cada uma, e um teste pode dizer exatamente qual espera."}, {"code": "extension SessionDraft {\n    public static let minutesRange = 5...480\n\n    /// Every problem at once, so the form can show them all rather than one per tap.\n    public var problems: [DraftProblem] {\n        var found: [DraftProblem] = []\n        if courseID == nil { found.append(.noCourse) }\n        let text = minutesText.trimmingCharacters(in: .whitespaces)\n        if text.isEmpty {\n            found.append(.noMinutes)\n        } else if let minutes = Int(text) {\n            if !Self.minutesRange.contains(minutes) { found.append(.minutesOutOfRange(minutes)) }\n        } else {\n            found.append(.minutesNotWhole(text))\n        }\n        return found\n    }\n\n", "note": "`problems` junta todos os problemas em vez de parar no primeiro, para o formulário marcar os dois campos de uma vez. Espaços em volta do número são perdoados; o que o `Int` não consegue ler é recusado inteiro, então `1.5` e `forty` são os dois `minutesNotWhole`."}, {"code": "    /// The session this draft describes, or nil while it has a problem.\n    public func session(id: String, calendar: Calendar) -> StudySession? {\n        guard problems.isEmpty, let courseID,\n              let minutes = Int(minutesText.trimmingCharacters(in: .whitespaces))\n        else { return nil }\n        return StudySession(id: id, courseID: courseID, date: day(of: date, in: calendar), minutes: minutes)\n    }\n}\n\n", "note": "A única saída de um rascunho. Enquanto algo estiver errado não há sessão a adicionar, então o botão Add não tem o que enviar."}, {"code": "/// The day a moment falls on, YYYY-MM-DD, in the calendar the person picked it in.\npublic func day(of date: Date, in calendar: Calendar) -> String {\n    let c = calendar.dateComponents([.year, .month, .day], from: date)\n    return String(format: \"%04d-%02d-%02d\", c.year!, c.month!, c.day!)\n}\n", "note": "O seletor de data entrega um instante. Qual dia esse instante é depende do calendário em que ele é lido, então quem chama passa o da própria pessoa; a seção 05 mostra o que dá errado do contrário."}]}
```

**Todo problema é um valor, nunca uma frase.** `DraftProblem.minutesOutOfRange(600)` diz o que está
errado e carrega o número; as palavras que a pessoa lê são assunto do formulário, na língua dela, e a
aula 19 é onde elas também são lidas em voz alta pelo VoiceOver. Um validador que devolvesse
`"Minutes must be between 5 and 480"` amarraria a regra a uma língua e deixaria um teste comparando
frases em inglês.

O intervalo, de 5 a 480 minutos, é uma decisão do próprio planner: menos de cinco é mais vezes um erro
de digitação que uma sessão, e oito horas é um dia. Os planners das outras plataformas usam os mesmos
limites, então os três apps recusam a mesma entrada.

## Os testes

Salve isto como `Tests/PlannerCoreTests/DraftTests.swift`, ao lado do `PlanTests.swift` da aula 1:

```swift
// Tests/PlannerCoreTests/DraftTests.swift
import Foundation
import Testing
@testable import PlannerCore

let picked = ISO8601DateFormatter().date(from: "2026-10-21T23:30:00-03:00")!

@Test func spacesAroundTheNumberAreForgiven() {
    for typed in ["30", " 30", "30 "] {
        #expect(SessionDraft(courseID: "sql", date: picked, minutesText: typed).problems.isEmpty)
    }
}

@Test func everyProblemIsReportedAtOnce() {
    let draft = SessionDraft(courseID: nil, date: picked, minutesText: "lots")
    #expect(draft.problems == [.noCourse, .minutesNotWhole("lots")])
}

@Test func theDayIsTheOneThePersonSaw() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
    let draft = SessionDraft(courseID: "sql", date: picked, minutesText: "45")
    #expect(draft.session(id: "s6", calendar: calendar)?.date == "2026-10-21")
}
```

```
ana@vm:~/l10$ swift test
Building for debugging...
[Provisioning 1 / 7]
[Pre-planning 1 / 182]
[Starting]
[40 / 71] PlannerCore
[48 / 75] draft-product
[51 / 77] week-product
[54 / 78] week-product
[65 / 85] PlannerCoreTests-product
[69 / 85] draft-product
[75 / 86] PlannerCoreTests-product
[78 / 86] PlannerCoreTests-product
[82 / 89] PlannerCoreTests-test-runner
[90 / 90] PlannerCoreTests-test-runner
Build complete! (7.47 secs)
Test Suite 'All tests' started at 2026-10-30 15:22:41.786
Test Suite 'Debug-linux-x86_64.xctest' started at 2026-10-30 15:22:41.788
Test Suite 'Debug-linux-x86_64.xctest' passed at 2026-10-30 15:22:41.788
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.0 (0.0) seconds
Test Suite 'All tests' passed at 2026-10-30 15:22:41.788
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.0 (0.0) seconds
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Test spacesAroundTheNumberAreForgiven() started.
◇ Test mondayIsTheStartOfTheWeek() started.
◇ Test theDayIsTheOneThePersonSaw() started.
◇ Test everyProblemIsReportedAtOnce() started.
◇ Test aSessionForNoCourseIsRefused() started.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.002 seconds.
✔ Test aSessionForNoCourseIsRefused() passed after 0.002 seconds.
✔ Test everyProblemIsReportedAtOnce() passed after 0.003 seconds.
✔ Test spacesAroundTheNumberAreForgiven() passed after 0.004 seconds.
✔ Test theDayIsTheOneThePersonSaw() passed after 0.004 seconds.
✔ Test run with 5 tests in 0 suites passed after 0.004 seconds.
```

Cinco testes: os dois da aula 1 e estes três. O segundo é o que se paga. **Um formulário que mostra um
problema de cada vez faz a pessoa tocar em Add uma vez por erro**, e um teste que compara a lista
inteira é o que impede uma mudança futura de voltar, em silêncio, a parar no primeiro.
