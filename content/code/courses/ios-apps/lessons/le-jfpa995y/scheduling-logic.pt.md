---
title: Decidindo quando pedir
version: 1
---

**O sistema decide quando uma atualização roda; o app decide o que pede, e um bom pedido é metade do
resultado.** Pedir uma atualização a cada quinze minutos o dia inteiro gasta bateria à toa, e o sistema
aprende a dar menos a um app assim. Pedir uma vez por dia na hora errada deixa o plano velho quando
importa. A regra do planner é curta o bastante para caber numa frase e para testar:

- **quando há sessões esperando para ser enviadas**, pedir de novo em quinze minutos, porque o trabalho
  da pessoa ainda não está no servidor;
- **senão**, pedir para as seis da manhã, para o plano estar fresco antes de começar o estudo do dia.

## A regra, no pacote

Salve isto como `Sources/PlannerCore/RefreshPolicy.swift`:

```swift
// Sources/PlannerCore/RefreshPolicy.swift
import Foundation

/// When to ask iOS for the next background refresh: soon when sessions are
/// waiting to be sent, otherwise at six in the morning, before the day's study.
public func nextRefresh(after now: Date, pending: Int, calendar: Calendar) -> Date {
    if pending > 0 {
        return now.addingTimeInterval(15 * 60)
    }
    return calendar.nextDate(after: now, matching: DateComponents(hour: 6, minute: 0),
                             matchingPolicy: .nextTime)!
}
```

**As seis horas são achadas pelo calendário, não somando horas.** O `nextDate(after:matching:)` pede o
próximo momento cuja hora é 6 e o minuto 0 no fuso do próprio calendário. Somar "as horas até as seis"
à hora atual daria certo na maioria das noites e errado nas duas noites do ano em que os relógios
mudam, e um teste consegue mostrar qual.

## Um programa para experimentar

O pacote ganha um quinto programa, `background`, que esta seção começa e a seguinte faz crescer. Troque
o `Package.swift` por este, o da aula 15 com mais uma linha:

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
        .executableTarget(name: "fetch", dependencies: ["PlannerCore"]),
        .executableTarget(name: "repo", dependencies: ["PlannerCore"]),
        .executableTarget(name: "covers", dependencies: ["PlannerCore"]),
        .executableTarget(name: "background", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

Salve isto como `Sources/background/main.swift`. Ele recebe um fuso e um momento, e imprime a
atualização que a regra pediria sem nada esperando e com três sessões esperando:

```swift
// Sources/background/main.swift
import Foundation
import PlannerCore

let args = Array(CommandLine.arguments.dropFirst())
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: args[0])!
let format = ISO8601DateFormatter()
format.timeZone = calendar.timeZone
let now = format.date(from: args[1])!

for pending in [0, 3] {
    let next = nextRefresh(after: now, pending: pending, calendar: calendar)
    let minutes = Int(next.timeIntervalSince(now) / 60)
    print("\(pending) waiting: next refresh \(format.string(from: next)), in \(minutes) min")
}
```

Compile e pergunte por duas noites, uma em São Paulo e uma em Lisboa:

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (6.50 secs)
ana@vm:~/planner$ .build/debug/background America/Sao_Paulo 2026-10-21T22:30:00-03:00
0 waiting: next refresh 2026-10-22T06:00:00-03:00, in 450 min
3 waiting: next refresh 2026-10-21T22:45:00-03:00, in 15 min
ana@vm:~/planner$ .build/debug/background Europe/Lisbon 2026-10-24T22:30:00+01:00
0 waiting: next refresh 2026-10-25T06:00:00Z, in 510 min
3 waiting: next refresh 2026-10-24T22:45:00+01:00, in 15 min
```

**São Paulo às 22h30 de 21 de outubro está a 450 minutos das seis, sete horas e meia.** Lisboa às 22h30
de 24 de outubro está a 510 minutos, oito horas e meia: a noite de 24 para 25 de outubro de 2026 é
quando os relógios de Portugal voltam uma hora, e o calendário contou essa hora. O `Z` no fim do
resultado de Lisboa é o jeito do formatador de escrever um deslocamento zero, que é a hora de inverno
de Lisboa. Uma regra escrita como "agora mais as horas até as seis" teria pedido as cinco.
