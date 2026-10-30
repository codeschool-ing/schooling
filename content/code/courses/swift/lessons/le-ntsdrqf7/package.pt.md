---
title: package, entre internal e public
version: 1
---

O pacote do planner tem dois módulos, e parte do código de um é feito para o outro e para mais
ninguém: um resumo de depuração que o `plan` imprime e de que nenhum usuário de fora da biblioteca
deveria passar a depender. `internal` é estreito demais, porque o `plan` é outro módulo. `public` é
largo demais, porque todo pacote que importa o `PlannerCore` o receberia. **`package`, que chegou no
Swift 5.9, é o nível do meio: visível para todo módulo do mesmo pacote, e para nada fora dele.**

```swift
// Sources/PlannerCore/Week.swift
public struct Week {
    public private(set) var minutes: [Int] = []
    public var total: Int { minutes.reduce(0, +) }

    public init() {}

    public mutating func add(_ session: Int) {
        guard session > 0 else { return }
        minutes.append(session)
    }

    package func summary() -> String {
        "\(minutes.count) sessions, \(total) minutes"
    }
}
```

O `plan`, no mesmo pacote, o usa:

```swift
// Sources/plan/main.swift
import PlannerCore

var week = Week()
week.add(45)
week.add(60)
print(week.summary())
```

```
ana@vm:~/sw/l17/planner$ swift build 2>&1 | grep -v frontend
Building for debugging...
[3 / 6] PlannerCore
[7 / 8] PlannerCore
[14 / 17] plan-product
[18 / 18] plan-product
Build complete! (1.06 secs)
ana@vm:~/sw/l17/planner$ .build/debug/plan
2 sessions, 105 minutes
```

## De outro pacote

Um segundo pacote, `report`, fica ao lado do `planner` no mesmo diretório e depende dele pelo
caminho, como um pacote usa uma biblioteca que está no mesmo disco:

```swift
// swift-tools-version: 6.2
// Package.swift
import PackageDescription

let package = Package(
    name: "report",
    dependencies: [
        .package(path: "../planner"),
    ],
    targets: [
        .executableTarget(
            name: "report",
            dependencies: [.product(name: "PlannerCore", package: "planner")]
        ),
    ]
)
```

```swift
// Sources/report/main.swift
import PlannerCore

var week = Week()
week.add(45)
print(week.summary())
```

```
ana@vm:~/sw/l17/report$ swift build 2>&1 | grep -v frontend
Building for debugging...
[Constructing description]
[Planning deferred tasks]
[25 / 36] PlannerCore
error: SwiftCompile normal x86_64 failed with a nonzero exit code. Command line:     cd /home/ana/sw/l17
    
/home/ana/sw/l17/report/Sources/report/main.swift:6:12: error: 'summary' is inaccessible due to 'package' protection level
4 | var week = Week()
5 | week.add(45)
6 | print(week.summary())
  |            `- error: 'summary' is inaccessible due to 'package' protection level
7 | 

/home/ana/sw/l17/planner/Sources/PlannerCore/Week.swift:13:18: note: 'summary()' declared here
11 |     }
12 | 
13 |     package func summary() -> String {
   |                  `- note: 'summary()' declared here
14 |         "\(minutes.count) sessions, \(total) minutes"
15 |     }
error: Build failed
```

Mesma chamada, mesma biblioteca, e desta vez é recusada: `'summary' is inaccessible due to 'package'
protection level`. **A fronteira é o pacote**, o diretório com um `Package.swift`, e o `report` tem o
dele. Tudo o que era público na seção 04 ainda funciona a partir do `report`; só o nome feito para
os módulos do próprio planner fica retido.

## Onde package vale a pena

Antes do Swift 5.9 o único jeito de compartilhar código entre dois módulos de um pacote era
`public`, e um pacote grande publicava dezenas de nomes que os usuários nunca deveriam chamar,
muitas vezes com um comentário pedindo que não chamassem. **`package` transforma esse comentário numa
regra que o compilador faz cumprir.** Serve para ajudantes de teste compartilhados entre targets, um
logger comum e o encanamento entre uma biblioteca e a ferramenta de linha de comando ao lado dela,
que é exatamente o formato que o pacote da aula 19 toma.

Isso completa os seis níveis, e uma regra os mantém juntos: **nada pode ser usado de mais longe do
que as coisas que ele menciona**. Um membro de um tipo `internal` nunca é usável fora do módulo,
diga o que disser a palavra-chave dele, e uma função `public` não pode receber nem devolver um tipo
`internal`, porque um chamador fora do módulo não conseguiria nomeá-lo. O compilador recusa essa
declaração em vez de publicar metade dela.
