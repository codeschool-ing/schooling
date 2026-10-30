---
title: Gatilhos, e a hora que se mexe
version: 1
---

**Uma notificação local é agendada com um gatilho, e o gatilho é onde fusos horários e mudanças de
relógio decidem se o lembrete chega quando o estudante espera.** O framework User Notifications oferece
três: depois de um intervalo (`UNTimeIntervalNotificationTrigger`), numa data e hora
(`UNCalendarNotificationTrigger`), e ao entrar ou sair de um lugar (`UNLocationNotificationTrigger`). O
planner lembra o estudante de uma sessão na noite anterior, então usa o gatilho de calendário. O
framework em si não roda no Linux. **A aritmética que decide quando roda**, e esta seção a executa.

## O lembrete, como componentes de data

A documentação da Apple para o `UNCalendarNotificationTrigger` diz que ele recebe `DateComponents` que
especificam "só os valores de tempo que você quer que o sistema use" para achar a data e a hora
correspondentes. Então o planner calcula componentes e o sistema faz o resto. O pacote desta aula é o da
aula 1 em `~/l17`, com mais um arquivo de código e mais um programa. Copie os cinco arquivos da aula 1, e
troque o `Package.swift` por este:

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
        .executableTarget(name: "remind", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

Salve isto como `Sources/PlannerCore/Reminders.swift`:

```swift
// Sources/PlannerCore/Reminders.swift
import Foundation

private let days: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

/// When to remind the student of a session planned for `day`: the evening before, at `hour`.
/// The components carry no time zone, so they mean that hour wherever the phone is.
public func reminder(forDay day: String, at hour: Int) -> DateComponents {
    let p = day.split(separator: "-").compactMap { Int($0) }
    let date = days.date(from: DateComponents(year: p[0], month: p[1], day: p[2]))!
    let before = days.dateComponents([.year, .month, .day], from: days.date(byAdding: .day, value: -1, to: date)!)
    return DateComponents(year: before.year, month: before.month, day: before.day, hour: hour, minute: 0)
}
```

**Os componentes não carregam fuso horário, de propósito.** Uma sessão é planejada para um dia, o
`2026-10-23` da aula 1, e "na noite anterior às sete" quer dizer sete horas onde quer que o estudante
esteja nessa noite. A aritmética de dias usa um calendário UTC, pelo motivo da aula 1, e só com dias
inteiros; a hora fica para o calendário do próprio telefone posicionar.

Depois, um programa que imprime os lembretes das duas sessões da aula 1 ainda por fazer, e então um
lembrete diário às oito da manhã, em Lisboa, ao longo da noite de 25 de outubro de 2026, quando os
relógios de Portugal voltam uma hora. Salve-o como `Sources/remind/main.swift`:

```swift
// Sources/remind/main.swift
import Foundation
import PlannerCore

// The two sessions of lesson 1's plan that are not done yet
for (id, day) in [("s3", "2026-10-23"), ("s4", "2026-10-27")] {
    let c = reminder(forDay: day, at: 19)
    print(id, day, "-> remind on", c.year!, c.month!, c.day!, "at", c.hour!)
}

// A daily 08:00 reminder in Lisbon, across the night the clocks go back (25 October 2026)
var lisbon = Calendar(identifier: .gregorian)
lisbon.timeZone = TimeZone(identifier: "Europe/Lisbon")!
let show = DateFormatter()
show.dateFormat = "EEE dd MMM HH:mm zzz"
show.locale = Locale(identifier: "en_GB")
show.timeZone = lisbon.timeZone

let first = lisbon.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 8))!
var byComponents = first
var byInterval = first
print("components hour 8".padding(toLength: 26, withPad: " ", startingAt: 0) + "every 86400 seconds")
for _ in 0..<5 {
    print(show.string(from: byComponents).padding(toLength: 26, withPad: " ", startingAt: 0) + show.string(from: byInterval))
    byComponents = lisbon.nextDate(after: byComponents, matching: DateComponents(hour: 8, minute: 0),
                                   matchingPolicy: .nextTime)!
    byInterval = byInterval.addingTimeInterval(86_400)
}
```

E dois testes ao lado dos da aula 1, como `Tests/PlannerCoreTests/ReminderTests.swift`:

```swift
// Tests/PlannerCoreTests/ReminderTests.swift
import Foundation
import Testing
@testable import PlannerCore

@Test func theReminderIsTheEveningBefore() {
    let c = reminder(forDay: "2026-10-23", at: 19)
    #expect([c.year, c.month, c.day, c.hour] == [2026, 10, 22, 19])
}

@Test func theEveningBeforeTheFirstIsInTheMonthBefore() {
    let c = reminder(forDay: "2026-11-01", at: 19)
    #expect([c.year, c.month, c.day] == [2026, 10, 31])
    #expect(c.timeZone == nil)
}
```

```
ana@vm:~/l17$ swift build
Building for debugging...
[Pre-planning 1 / 124]
[Planning deferred tasks]
[31 / 47] PlannerCore
[38 / 50] week-product
[39 / 50] week-product
[40 / 50] week-product
[46 / 54] remind-product
[46 / 54] PlannerCore
[51 / 56] PlannerCore
[56 / 56] remind-product
Build complete! (6.49 secs)
ana@vm:~/l17$ .build/debug/remind
s3 2026-10-23 -> remind on 2026 10 22 at 19
s4 2026-10-27 -> remind on 2026 10 26 at 19
components hour 8         every 86400 seconds
Fri 23 Oct 08:00 WEST     Fri 23 Oct 08:00 WEST
Sat 24 Oct 08:00 WEST     Sat 24 Oct 08:00 WEST
Sun 25 Oct 08:00 WET      Sun 25 Oct 07:00 WET
Mon 26 Oct 08:00 WET      Mon 26 Oct 07:00 WET
Tue 27 Oct 08:00 WET      Tue 27 Oct 07:00 WET
ana@vm:~/l17$ swift test 2>&1 | grep "✔"
✔ Test theEveningBeforeTheFirstIsInTheMonthBefore() passed after 0.003 seconds.
✔ Test aSessionForNoCourseIsRefused() passed after 0.003 seconds.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.003 seconds.
✔ Test theReminderIsTheEveningBefore() passed after 0.003 seconds.
✔ Test run with 4 tests in 0 suites passed after 0.004 seconds.
```

**A coluna da esquerda é o que componentes de data dão; a da direita, o que um intervalo fixo dá.** As
duas começam às 08:00 de sexta-feira, horário de verão da Europa Ocidental. No domingo os relógios
voltam, e um lembrete que soma 86.400 segundos por dia passa a chegar às 07:00, uma hora cedo, todo dia
até os relógios mudarem de novo. Os componentes pedem "hora 8" e a recebem dos dois lados da mudança. O
`nextDate(after:matching:)` é o calendário respondendo à mesma pergunta que o gatilho faz aos seus
componentes; o agendamento do próprio gatilho no telefone não foi executado.

Esse é o argumento contra o `UNTimeIntervalNotificationTrigger` para tudo o que uma pessoa espera numa
hora do dia. A documentação dele diz que um intervalo repetido tem de ter pelo menos 60 segundos, e nada
sobre relógios: um intervalo é uma duração, e um dia nem sempre tem 86.400 segundos. O segundo teste fixa
a outra borda, a noite antes de 1º de novembro, que fica em outubro.
