---
title: O núcleo do planner, como um pacote Swift
version: 1
---

**Toda aula deste curso trabalha num app só: um planner de estudos.** Um estudante lista os cursos que
está fazendo, abre um, adiciona sessões de estudo com uma data e uma duração em minutos, marca as
sessões como feitas e vê quanto do plano da semana já terminou. É o app que a trilha `frontend`
constrói num navegador, e `android-apps` e `react-native` constroem o mesmo, com as mesmas telas e os
mesmos dados, para que a última aula de cada um compare coisas comparáveis.

O app tem duas metades, e elas moram em dois lugares. **As telas são SwiftUI, e só o Xcode as
compila.** Os dados e as contas que toda tela mostra são Swift puro, e vão num **pacote Swift**: um
diretório com um manifesto, `Package.swift`, que o comando `swift` compila e testa no Linux e que o
Xcode abre num Mac sem mudar nada. Esta seção constrói o pacote. A seção 06 mostra como o target do
app o usa.

## A estrutura

Um pacote é uma convenção sobre diretórios. `Sources/<target>/` guarda o código de um target e
`Tests/<target>/` os testes dele, e o manifesto dá nome aos targets. Crie os diretórios:

```
ana@vm:~$ mkdir -p planner/Sources/PlannerCore planner/Sources/week planner/Tests/PlannerCoreTests
ana@vm:~$ cd planner
```

Salve isto como `Package.swift` em `~/planner`:

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
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

**A primeira linha não é um comentário, por mais que pareça.** `swift-tools-version: 6.0` diz ao
toolchain em que versão do formato de manifesto este arquivo está escrito, e com ela o modo de
linguagem Swift 6, em que o compilador recusa uma condição de corrida em vez de só avisar. O
`platforms` só é lido quando o pacote é compilado para um sistema da Apple: o iOS 17 é a primeira
versão com a macro `@Observable` que a aula 7 usa e com o SwiftData, de que a aula 13 precisa. No
Linux ele é ignorado.

Três targets. `PlannerCore` é a biblioteca que o app vai importar. `week` é um pequeno programa de
linha de comando que imprime o total de uma semana, para você ver a biblioteca funcionando.
`PlannerCoreTests` são os testes dela.

## O núcleo

Salve isto como `Sources/PlannerCore/Plan.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/Plan.swift", "parts": [{"code": "// Sources/PlannerCore/Plan.swift\nimport Foundation\n\npublic struct Course: Identifiable, Hashable, Sendable {\n    public let id: String\n    public var title: String\n\n    public init(id: String, title: String) {\n        self.id = id\n        self.title = title\n    }\n}\n", "note": "Um curso é um valor com um `id` que nunca muda e um `title` que pode mudar. Todo o resto do planner aponta para um curso pelo `id`, então renomear um curso não perde nada. É o `public` que deixa o app, que é outro módulo, enxergá-lo."}, {"code": "public struct StudySession: Identifiable, Hashable, Sendable {\n    public let id: String\n    public let courseID: String\n    public var date: String  // YYYY-MM-DD\n    public var minutes: Int\n    public var done: Bool\n\n    public init(id: String, courseID: String, date: String, minutes: Int, done: Bool = false) {\n        self.id = id\n        self.courseID = courseID\n        self.date = date\n        self.minutes = minutes\n        self.done = done\n    }\n}\n", "note": "`StudySession` e não `Session`, porque a aula 12 traz o `URLSession` para os mesmos arquivos e duas coisas chamadas sessão é uma a mais. A data é um dia escrito como texto, do jeito que o planner a guarda em toda plataforma; mais abaixo, esta seção diz por que um `Date` seria o tipo errado aqui."}, {"code": "public enum PlanError: Error, Equatable {\n    case unknownCourse(String)\n    case unknownSession(String)\n}\n\npublic struct WeekTotal: Equatable, Sendable {\n    public let monday: String\n    public let planned: Int\n    public let done: Int\n}\n", "note": "As duas formas de uma mudança citar algo que não existe, como um erro que quem chama tem de tratar. Um `WeekTotal` é a soma que toda tela mostra: minutos planejados e minutos feitos numa semana."}, {"code": "public struct Plan: Sendable {\n    public var courses: [Course]\n    public var sessions: [StudySession]\n\n    public init(courses: [Course] = [], sessions: [StudySession] = []) {\n        self.courses = courses\n        self.sessions = sessions\n    }\n\n    public mutating func add(_ session: StudySession) throws(PlanError) {\n        guard courses.contains(where: { $0.id == session.courseID }) else {\n            throw .unknownCourse(session.courseID)\n        }\n        sessions.append(session)\n    }\n\n    public mutating func markDone(_ id: String) throws(PlanError) {\n        guard let i = sessions.firstIndex(where: { $0.id == id }) else {\n            throw .unknownSession(id)\n        }\n        sessions[i].done = true\n    }\n", "note": "Uma sessão de um curso que não existe é recusada, e marcar uma que não existe também. `throws(PlanError)` é um throw tipado: quem chama sabe o único erro que pode receber. `mutating` é como um método de uma struct diz que muda o valor em que foi chamado."}, {"code": "    public func weekTotal(today: String) -> WeekTotal {\n        let monday = mondayOf(today)\n        let week = sessions.filter { mondayOf($0.date) == monday }\n        let planned = week.reduce(0) { $0 + $1.minutes }\n        let done = week.filter(\\.done).reduce(0) { $0 + $1.minutes }\n        return WeekTotal(monday: monday, planned: planned, done: done)\n    }\n}\n", "note": "`today` é um argumento e não o relógio, então o mesmo plano sempre dá a mesma resposta e um teste consegue fixá-la. `\\.done` é um key path usado como função: fique com as sessões cujo `done` é verdadeiro."}]}
```

**Um `Plan` é um valor.** Ele é uma `struct`, então atribuí-lo o copia, e os métodos `mutating` mudam
só a cópia em que foram chamados. A aula 6 se apoia nisso: uma tela guarda um plano, e uma mudança
feita numa cópia em outro lugar não chega nele por acidente.

A semana começa na segunda-feira, e achar a segunda-feira de um dia é a única conta de calendário que
o planner faz. Salve isto como `Sources/PlannerCore/Days.swift`:

```swift
// Sources/PlannerCore/Days.swift
import Foundation

private let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

/// The Monday of the week `day` falls in. Both are YYYY-MM-DD.
public func mondayOf(_ day: String) -> String {
    let parts = day.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3,
          let date = utc.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    else { preconditionFailure("not a day: \(day)") }
    let weekday = utc.component(.weekday, from: date)  // Sunday 1 ... Saturday 7
    let back = (weekday + 5) % 7                         // Monday 0 ... Sunday 6
    let monday = utc.date(byAdding: .day, value: -back, to: date)!
    let c = utc.dateComponents([.year, .month, .day], from: monday)
    return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
}
```

**O calendário fica fixo em UTC de propósito.** Um dia como `2026-10-19` não tem hora nem fuso. Se o
código o lesse no fuso do próprio telefone, o mesmo plano poderia pôr uma sessão numa semana em São
Paulo e na seguinte em Tóquio. Fixar um calendário só faz da resposta uma propriedade do texto.

O `preconditionFailure` para o programa diante de um dia que não é um dia. Isso é um bug de quem
chama, e é na aula 10 que um texto digitado por uma pessoa é conferido antes de chegar até aqui.

## Algo para rodar

Salve isto como `Sources/week/main.swift`. Ele monta o plano da semana de segunda-feira, 19 de outubro
de 2026, muda o plano duas vezes e imprime o total da semana. Ele recebe o "hoje" em vez de ler o
relógio, então imprime os mesmos números toda vez que você o roda:

```swift
// Sources/week/main.swift
import PlannerCore

var plan = Plan(
    courses: [
        Course(id: "sql", title: "SQL Databases"),
        Course(id: "mobile", title: "Mobile Fundamentals"),
    ],
    sessions: [
        StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50, done: true),
        StudySession(id: "s2", courseID: "mobile", date: "2026-10-20", minutes: 40, done: true),
        StudySession(id: "s3", courseID: "sql", date: "2026-10-23", minutes: 60),
        StudySession(id: "s4", courseID: "mobile", date: "2026-10-27", minutes: 45),
    ]
)

try plan.add(StudySession(id: "s5", courseID: "mobile", date: "2026-10-22", minutes: 30))
try plan.markDone("s5")
print(plan.weekTotal(today: "2026-10-21"))
```

## E um teste que segura isso no lugar

Um programa cuja saída você lê é uma conferência que você tem de repetir no olho. Um teste repete por
você. Salve isto como `Tests/PlannerCoreTests/PlanTests.swift`, o último dos cinco arquivos:

```swift
// Tests/PlannerCoreTests/PlanTests.swift
import Testing
@testable import PlannerCore

@Test func mondayIsTheStartOfTheWeek() {
    #expect(mondayOf("2026-10-21") == "2026-10-19")
    #expect(mondayOf("2026-10-19") == "2026-10-19")
    #expect(mondayOf("2026-10-25") == "2026-10-19")  // a Sunday
}

@Test func aSessionForNoCourseIsRefused() {
    var plan = Plan(courses: [Course(id: "sql", title: "SQL Databases")])
    #expect(throws: PlanError.unknownCourse("art")) {
        try plan.add(StudySession(id: "s1", courseID: "art", date: "2026-10-19", minutes: 30))
    }
    #expect(plan.sessions.isEmpty)
}
```

`import Testing` é o **Swift Testing**, o framework que o toolchain do Swift 6 traz em toda
plataforma. A aula 20 o compara com o XCTest, que os projetos Xcode usam desde antes de ele existir.
A linha do domingo é a que vale a pena: `(weekday + 5) % 7` é fácil de errar por um, e um domingo é
onde errar por um aparece.

## Compilar, rodar, testar

```
ana@vm:~/planner$ find Sources Tests -type f | sort
Sources/PlannerCore/Days.swift
Sources/PlannerCore/Plan.swift
Sources/week/main.swift
Tests/PlannerCoreTests/PlanTests.swift
ana@vm:~/planner$ swift build
Building for debugging...
[Pre-planning 1 / 95]
[Describing: 12 / 192]
[26 / 38] PlannerCore
[35 / 41] week-product
[38 / 42] PlannerCore
[43 / 43] week-product
Build complete! (5.34 secs)
ana@vm:~/planner$ .build/debug/week
WeekTotal(monday: "2026-10-19", planned: 180, done: 120)
```

O `swift build` compila o pacote em `.build/debug/`, e `week` é o programa que ele fez ali. A
primeira compilação compila tudo; as seguintes compilam só o que mudou. (O `swift run week` faz os
dois passos num comando só.) **A quarta-feira, dia 21, está na semana que começa na segunda, dia
19**, então as quatro sessões do dia 19 ao dia 23 contam e a `s4`, do dia 27, não: 50 + 40 + 60 + 30
dá 180 minutos planejados, e as três feitas dão 120.

```
ana@vm:~/planner$ swift test
Building for debugging...
[Constructing description]
[Planning deferred tasks]
[13 / 28] PlannerCoreTests-product
[17 / 28] PlannerCoreTests-product
[21 / 29] PlannerCoreTests-product
[25 / 32] PlannerCoreTests-test-runner
[29 / 32] PlannerCoreTests-test-runner
[33 / 33] PlannerCoreTests-test-runner
Build complete! (2.96 secs)
Test Suite 'All tests' started at 2026-10-30 15:05:17.548
Test Suite 'Debug-linux-x86_64.xctest' started at 2026-10-30 15:05:17.549
Test Suite 'Debug-linux-x86_64.xctest' passed at 2026-10-30 15:05:17.549
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.0 (0.0) seconds
Test Suite 'All tests' passed at 2026-10-30 15:05:17.549
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.0 (0.0) seconds
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Test aSessionForNoCourseIsRefused() started.
◇ Test mondayIsTheStartOfTheWeek() started.
✔ Test aSessionForNoCourseIsRefused() passed after 0.001 seconds.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.001 seconds.
✔ Test run with 2 tests in 0 suites passed after 0.002 seconds.
```

A execução dos testes imprime dois relatórios. O primeiro é do XCTest, que não achou nenhum teste
XCTest neste pacote e diz isso; o segundo é do Swift Testing, que achou dois e passou os dois. Eles
começaram numa ordem e terminaram em outra porque o Swift Testing roda os testes em paralelo, a não
ser que alguém mande o contrário, e um teste que depende de outro ter rodado antes é um teste que
falha em alguns dias.
