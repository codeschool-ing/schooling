---
title: Salvar onde a pessoa estava, e recusar uma tela que não existe mais
version: 1
---

**O iOS pode encerrar um app em segundo plano a qualquer momento, e uma pessoa que volta espera a tela
que deixou.** A aula 2 trata de quando isso acontece. Com o path como um array de valores `Codable`,
salvar a pilha é codificar um array, e restaurá-la é decodificar um. Num Mac o app faria isso com
`@SceneStorage` ou um arquivo quando a cena vai para segundo plano; nenhum dos dois foi executado. A
codificação, a decodificação e a única conferência de que a restauração precisa rodam aqui.

**A conferência é a parte que as pessoas esquecem.** Um path salvo na segunda pode citar uma sessão
apagada na terça. Restaurado às cegas, ele empilha uma tela para algo que não está lá. A correção é
ficar com o maior começo do path em que toda rota ainda cita algo no plano. Salve isto como
`Sources/PlannerCore/RoutePruning.swift`:

```swift
// Sources/PlannerCore/RoutePruning.swift
extension Route {
    /// The longest start of `path` whose every route still names something in `plan`.
    public static func stillValid(_ path: [Route], in plan: Plan) -> [Route] {
        Array(path.prefix { route in
            switch route {
            case .course(let id): plan.courses.contains { $0.id == id }
            case .session(let id): plan.sessions.contains { $0.id == id }
            case .week(let day): day.count == 10
            }
        })
    }
}
```

O `prefix(while:)` para na primeira rota que falha, em vez de filtrá-la fora, e isso é de propósito:
uma tela de sessão cujo curso sumiu não deve ser mostrada sem nada embaixo. A conferência do dia de uma
semana só olha o tamanho; a aula 10 é onde um dia digitado por uma pessoa é conferido direito.

Um programa para vê-lo funcionar. O manifesto desta aula acrescenta um target executável `paths`, do
mesmo jeito que o da aula 7 acrescentou o `track`. Substitua o `Package.swift`:

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
        .executableTarget(name: "paths", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

E salve isto como `Sources/paths/main.swift`:

```schooling-example
{"language": "swift", "file": "Sources/paths/main.swift", "parts": [{"code": "// Sources/paths/main.swift\nimport Foundation\nimport PlannerCore\n\nlet encoder = JSONEncoder()\nencoder.outputFormatting = [.sortedKeys]\n\nlet path: [Route] = [.course(id: \"sql\"), .session(id: \"s3\")]\nlet saved = try encoder.encode(path)\nprint(\"saved:   \", String(decoding: saved, as: UTF8.self))\nlet restored = try JSONDecoder().decode([Route].self, from: saved)\nprint(\"restored:\", restored == path)\n", "note": "A pessoa estava na sessão `s3` do curso de SQL. Codifique o path, imprima o JSON, decodifique e compare. O `.sortedKeys` deixa a saída igual em toda execução."}, {"code": "var plan = Plan(\n    courses: [Course(id: \"sql\", title: \"SQL Databases\")],\n    sessions: [StudySession(id: \"s3\", courseID: \"sql\", date: \"2026-10-23\", minutes: 60)]\n)\nprint(\"nothing deleted:\", Route.stillValid(restored, in: plan))\nplan.sessions.removeAll()\nprint(\"s3 deleted:     \", Route.stillValid(restored, in: plan))\nplan.courses.removeAll()\nprint(\"sql deleted:    \", Route.stillValid(restored, in: plan))\n", "note": "Depois a restauração, três vezes: com tudo ainda lá, depois de a sessão ser apagada, e depois de o curso também ser."}]}
```

```
ana@vm:~/navigate$ .build/debug/paths
saved:    [{"course":{"id":"sql"}},{"session":{"id":"s3"}}]
restored: true
nothing deleted: [PlannerCore.Route.course(id: "sql"), PlannerCore.Route.session(id: "s3")]
s3 deleted:      [PlannerCore.Route.course(id: "sql")]
sql deleted:     []
```

**O JSON é o que o compilador sintetizou a partir do enum**: cada rota é um objeto cuja única chave é o
nome do case e cujo valor guarda os valores associados com rótulo. Esse é um formato que agora é seu.
Renomeie `session` para `sessionDetail` no enum e todo path salvo antes da renomeação para de
decodificar, então um path salvo deve ser tratado como qualquer outro dado salvo: se a decodificação
lançar um erro, comece na raiz em vez de cair.

**As três restaurações são a regra funcionando.** Com a sessão apagada, o app reabre no curso de SQL, a
tela em que a pessoa estava antes dela. Com o curso apagado também, ele reabre na lista.
