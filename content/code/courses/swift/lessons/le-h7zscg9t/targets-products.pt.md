---
title: Targets, e os produtos que outras pessoas usam
version: 1
---

Um **target** é um módulo que o pacote compila. Um **produto** é o que o pacote oferece para fora: um
executável que alguém pode rodar, ou uma biblioteca de que outro pacote pode depender, cada um feito
de um ou mais targets. **Targets são como você organiza o seu código; produtos são o que você promete
aos outros**, e o pacote `report` da aula 17 só conseguiu importar o `PlannerCore` porque o planner
o declarou como produto.

O planner ganha um manifesto escrito à mão, com os dois tipos:

```swift
// swift-tools-version: 6.2
// Package.swift
import PackageDescription

let package = Package(
    name: "planner",
    products: [
        .library(name: "PlannerCore", targets: ["PlannerCore"]),
        .executable(name: "plan", targets: ["plan"]),
    ],
    targets: [
        .target(name: "PlannerCore"),
        .executableTarget(name: "plan", dependencies: ["PlannerCore"]),
    ]
)
```

A versão de ferramentas é 6.2 e não a 6.4 que o `init` escreveu, o que deixa qualquer pessoa com um
toolchain Swift 6.2 ou mais novo compilar o pacote; nada nele precisa de 6.4. A biblioteca é a
semana da aula 17, e o executável lê minutos da linha de comando:

```swift
// Sources/PlannerCore/Week.swift
public struct Week {
    public private(set) var minutes: [Int] = []
    public let goal: Int

    public init(goal: Int = 300) {
        self.goal = goal
    }

    public mutating func add(_ session: Int) {
        minutes.append(session)
    }

    public var total: Int { minutes.reduce(0, +) }
}
```

```swift
// Sources/plan/main.swift
import PlannerCore

var week = Week()
for argument in CommandLine.arguments.dropFirst() {
    if let session = Int(argument) {
        week.add(session)
    }
}
print("\(week.total) of \(week.goal) minutes")
```

O `CommandLine.arguments` é a lista de palavras com que o programa foi iniciado, primeiro o nome do
próprio programa, e é por isso que o `dropFirst()` pula uma. O `swift package describe` imprime o
que o SwiftPM entendeu do manifesto, e é a primeira coisa a olhar quando um build faz algo que você
não esperava:

```
ana@vm:~/sw/l19/planner$ swift package describe
Name: planner
Manifest display name: planner
Path: /home/ana/sw/l19/planner
Tools version: 6.2
Dependencies:
Platforms:
Products:
    Name: PlannerCore
    Type:
        Library:
            automatic
    Targets:
        PlannerCore

    Name: plan
    Type:
        Executable: nil
    Targets:
        plan

Targets:
    Name: plan
    Type: executable
    C99name: plan
    Module type: SwiftTarget
    Path: Sources/plan
    Sources:
        main.swift
    Target dependencies:
        PlannerCore
    Product memberships:
        plan

    Name: PlannerCore
    Type: library
    C99name: PlannerCore
    Module type: SwiftTarget
    Path: Sources/PlannerCore
    Sources:
        Week.swift
    Product memberships:
        PlannerCore
        plan
```

Leia as duas listas uma contra a outra. Os **produtos** são os dois que o manifesto declarou. Os
**targets** têm cada um um caminho, os fontes encontrados lá e as **participações em produtos**: o
`PlannerCore` participa dos dois produtos, porque o executável depende dele e é ligado com ele. Nada
no manifesto citou um arquivo-fonte. **O SwiftPM encontra os fontes por convenção**, todo arquivo
`.swift` debaixo de `Sources/<nome do target>`, e um arquivo posto em outro lugar não faz parte do
build.

```
ana@vm:~/sw/l19/planner$ swift build 2>&1 | tail -1
Build complete! (3.84 secs)
ana@vm:~/sw/l19/planner$ ls .build/debug
PackageFrameworks
PlannerCore.o
PlannerCore.swiftmodule
libPlannerCore.a
plan
ana@vm:~/sw/l19/planner$ .build/debug/plan 45 30 60
135 of 300 minutes
```

O `.build/debug/` guarda os resultados: `plan`, o programa, e `libPlannerCore.a`, a biblioteca como
arquivo estático que foi ligado a ele. Um produto de biblioteca não é um programa, e nada o roda
sozinho; ele existe para outros targets e outros pacotes ligarem.

## Quando dividir um target

Um target é o tamanho certo para a maioria dos programas pequenos. Divida quando duas partes têm
públicos diferentes: o modelo que o app de iOS e a ferramenta de linha de comando vão usar é um
target, e cada programa em cima dele é outro. **A divisão também é uma fronteira**, e a aula 17
mostrou quanto custa: tudo o que o segundo target usa precisa ser `public` ou `package` no primeiro.
Uma divisão que obriga metade de um target a virar pública estava no lugar errado.
