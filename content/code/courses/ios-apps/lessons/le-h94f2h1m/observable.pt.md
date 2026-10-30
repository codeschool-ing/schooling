---
title: '@Observable: uma classe que o SwiftUI consegue observar'
version: 1
---

**Quando várias telas precisam do mesmo estado, o estado sai de qualquer view e vai para um objeto que
todas compartilham.** A aula 6 guardou o plano no `@State` da `CourseListView` e passou bindings para
baixo. Isso funciona para uma tela e as filhas dela. O planner tem quatro telas, e a tela da semana
fica ao lado da lista de cursos, não embaixo dela; passar `$plan` por todas as views entre elas faria
cada uma carregar um valor que nunca usa.

A ferramenta é a macro `@Observable`, do framework **Observation**. Ela chegou com o iOS 17, e faz
parte do toolchain do Swift e não do SwiftUI, o que quer dizer que **ela roda no Linux**. Então o
modelo do planner pode ser escrito, compilado e observado em qualquer computador, e só as views que o
leem precisam de um Mac.

A aula 6 seção 07 mostrou o que dá errado com uma classe comum em `@State`: uma mudança dentro dela
não chega a ninguém. O `@Observable` é a cura. Ele reescreve cada propriedade armazenada da classe
para que lê-la registre quem leu, e escrevê-la avise esses leitores.

## O modelo

Acrescente um arquivo ao pacote, `Sources/PlannerCore/PlannerModel.swift`. Faça uma cópia do pacote da
aula 1 para esta aula, `cp -r ~/planner ~/observe`, e salve-o lá:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/PlannerModel.swift", "parts": [{"code": "// Sources/PlannerCore/PlannerModel.swift\nimport Observation\n\n@MainActor @Observable\npublic final class PlannerModel {\n    public var plan: Plan\n    public var today: String\n    @ObservationIgnored public var lastSaved: String?\n", "note": "O `@Observable` torna `plan` e `today` observáveis: ler qualquer um é registrado, escrever qualquer um é anunciado. O `@ObservationIgnored` tira o `lastSaved` disso, para um estado que nenhuma tela desenha. O `@MainActor` diz que o modelo é usado na thread principal, onde rodam as views do SwiftUI, e o compilador do Swift 6 cobra isso de todo chamador."}, {"code": "    public init(plan: Plan, today: String) {\n        self.plan = plan\n        self.today = today\n    }\n\n    public var week: WeekTotal { plan.weekTotal(today: today) }\n", "note": "O total da semana é calculado, como a aula 6 seção 06 defendeu. Uma propriedade calculada não é rastreada em si; o que é rastreado é o que ela lê, `plan` e `today`."}, {"code": "    public func add(_ session: StudySession) throws(PlanError) {\n        try plan.add(session)\n    }\n\n    public func markDone(_ id: String) throws(PlanError) {\n        try plan.markDone(id)\n    }\n}\n", "note": "As mudanças passam pelo modelo, que as entrega ao `Plan` da aula 1. As regras ficam no tipo de valor e o modelo só o guarda, então os testes da aula 1 continuam cobrindo-as."}]}
```

**O plano continua sendo um valor.** O modelo guarda um `Plan`, e uma mudança em qualquer sessão
atribui um `plan` novo do ponto de vista do Observation. Isso é simples, e a seção 03 mostra quanto
custa.

O pacote precisa de um programa para dirigir o modelo, então o manifesto desta aula tem um segundo
target executável, `track`. Substitua o `Package.swift` por este; a única linha nova é a que cita o
`track`:

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
        .executableTarget(name: "track", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

O `platforms` importa aqui pela primeira vez. A documentação da Apple lista o framework Observation a
partir do iOS 17 e do macOS 14, e esta linha é o que promete ao compilador que o pacote nunca roda em
nada mais antigo, então num Mac ele aceita o `@Observable` sem pedir uma checagem de disponibilidade.
No Linux a linha continua ignorada.
