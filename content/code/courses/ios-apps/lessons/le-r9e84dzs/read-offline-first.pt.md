---
title: Ler offline primeiro
version: 1
---

**O repositório responde a partir do aparelho e pergunta ao servidor quando pode.** Essa ordem é tudo
o que existe na leitura offline-first, e ela é mais simples do que parece: há um valor que o aparelho
já tem, que as telas leem, e uma atualização que o substitui quando o servidor responde. Uma
atualização que falha não muda nada, então o plano na tela é o último que foi verdadeiro.

## O repositório

Salve isto como `Sources/PlannerCore/PlannerRepository.swift`. Esta seção trata da primeira metade
dele, a leitura; a seção 05 trata da escrita:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/PlannerRepository.swift", "parts": [{"code": "// Sources/PlannerCore/PlannerRepository.swift\nimport Foundation\n\npublic actor PlannerRepository {\n    let source: any PlanSource\n    let store: any PlanStore\n    var snapshot: Snapshot\n    /// The last time the device could not write its file, said rather than swallowed.\n    public private(set) var storeError: String?\n\n    public init(source: any PlanSource, store: any PlanStore) throws {\n        self.source = source\n        self.store = store\n        self.snapshot = try store.load()\n    }\n\n", "note": "Um `actor`, porque duas telas podem perguntar coisas a ele no mesmo instante, e um actor roda um método seu por vez entre cada `await`. Ele guarda as duas metades, uma fonte e um armazenamento, pelos protocolos delas, e carrega o que o aparelho guardou assim que é criado. Uma gravação que falha fica registrada em `storeError` em vez de ser descartada."}, {"code": "    /// The plan as the device knows it now: what the server last said,\n    /// plus what was added here and not yet confirmed. Never waits.\n    public var plan: Plan {\n        let confirmed = snapshot.sessions.map(\\.session)\n        let waiting = snapshot.pending.map(\\.session).filter { p in !confirmed.contains { $0.id == p.id } }\n        return Plan(courses: snapshot.courses.map(\\.course), sessions: confirmed + waiting)\n    }\n\n    public var pendingCount: Int { snapshot.pending.count }\n\n", "note": "A leitura nunca espera a rede. Ela é o que o servidor disse por último, mais toda sessão acrescentada aqui que o servidor não confirmou, então uma sessão acrescentada offline aparece na hora."}, {"code": "    /// Ask the server for everything. On failure the plan on the device is untouched.\n    public func refresh() async throws(APIError) {\n        let courses = try await source.courses()\n        var sessions: [StudySession] = []\n        for c in courses { sessions += try await source.sessions(course: c.id) }\n        snapshot.courses = courses.map { WireCourse(id: $0.id, title: $0.title) }\n        snapshot.sessions = sessions.map(WireSession.init)\n        save()\n    }\n\n", "note": "A atualização substitui a metade do servidor e deixa `pending` em paz. Se qualquer pedido falha, o `throw` sai antes de o snapshot ser tocado, então uma atualização que falha no meio não muda nada no aparelho."}, {"code": "    /// Add a session on the device first, then try to tell the server.\n    /// Returns the ids the server refused for good, as `sync` does.\n    @discardableResult\n    public func add(_ s: StudySession) async throws(PlanError) -> [String] {\n        var check = plan\n        try check.add(s)                       // refuses a course the device does not know\n        snapshot.pending.append(WireSession(s))\n        save()\n        return await sync()\n    }\n\n", "note": "Uma escrita vai primeiro para o aparelho e depois para o servidor. A conferência contra o plano recusa um curso que o aparelho não conhece, como o `Plan.add` da aula 1 faz, antes de qualquer coisa ser guardada."}, {"code": "    /// Send every pending session. Returns the ids the server refused for good.\n    @discardableResult\n    public func sync() async -> [String] {\n        var refused: [String] = []\n        for p in snapshot.pending {\n            do throws(APIError) {\n                let sent = try await source.add(p.session)\n                snapshot.pending.removeAll { $0.id == sent.id }\n                if !snapshot.sessions.contains(where: { $0.id == sent.id }) {\n                    snapshot.sessions.append(WireSession(sent))\n                }\n            } catch {\n                switch error {\n                case .status(let code, _) where (400..<500).contains(code):\n                    snapshot.pending.removeAll { $0.id == p.id }\n                    refused.append(p.id)\n                default:\n                    break                      // offline or cancelled: try again later\n                }\n            }\n        }\n        save()\n        return refused\n    }\n\n", "note": "O `sync` percorre as sessões pendentes e envia cada uma. Um sucesso a passa para o outro lado; um `4xx` é uma recusa que nunca vai mudar, então ela é descartada e informada; qualquer outra coisa, offline acima de tudo, a deixa pendente para a próxima tentativa."}, {"code": "    func save() {\n        do {\n            try store.save(snapshot)\n            storeError = nil\n        } catch {\n            storeError = \"\\(error)\"\n        }\n    }\n}\n", "note": "Um lugar só grava o arquivo, e diz quando não conseguiu."}]}
```

**`plan` é uma propriedade, não um pedido.** Uma tela a lê e recebe uma resposta no tempo de montar um
`Plan` a partir de dois arrays, faça a rede o que fizer. A única coisa que espera é o `refresh`, e uma
tela o começa em segundo plano e redesenha quando ele termina.

## Dirigindo pelo terminal

O `repo` é um programa que faz uma coisa ao repositório e depois imprime o que o aparelho mostraria.
Salve isto como `Sources/repo/main.swift`:

```swift
// Sources/repo/main.swift
import Foundation
import PlannerCore

let args = Array(CommandLine.arguments.dropFirst())
let api = APIClient(base: URL(string: "http://127.0.0.1:8012")!)
let repo = try PlannerRepository(source: api, store: FileStore(url: URL(fileURLWithPath: "planner.json")))

switch args.first {
case "refresh":
    do throws(APIError) {
        try await repo.refresh()
        print("refreshed from the server")
    } catch {
        print("could not refresh:", error.message)
    }
case "add":
    let s = StudySession(id: args[1], courseID: args[2], date: args[3], minutes: Int(args[4])!)
    do throws(PlanError) {
        let refused = try await repo.add(s)
        print("added \(s.id) on the device" + (refused.isEmpty ? "" : ", and the server refused \(refused)"))
    } catch {
        print("not added:", error)
    }
case "sync":
    let refused = await repo.sync()
    print("synced" + (refused.isEmpty ? "" : ", and the server refused \(refused)"))
default:
    break
}
let plan = await repo.plan
print("\(plan.courses.count) courses, \(plan.sessions.count) sessions, \(await repo.pendingCount) waiting to be sent")
print(plan.weekTotal(today: "2026-10-21"))
if let problem = await repo.storeError { print("could not save:", problem) }
```

Ele guarda o arquivo como `planner.json` no diretório de onde você o roda, e julga a semana a partir
da quarta-feira, 21 de outubro, como o `week` da aula 1 fazia. Compile e rode uma atualização **com o
servidor parado**, do jeito que um telefone sem sinal abriria o app pela primeira vez:

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (6.58 secs)
ana@vm:~/planner$ .build/debug/repo refresh
could not refresh: You are offline, or the planner's server is not answering.
0 courses, 0 sessions, 0 waiting to be sent
WeekTotal(monday: "2026-10-19", planned: 0, done: 0)
```

Nada no aparelho ainda, e uma frase honesta sobre o porquê. Agora inicie o servidor no terminal dele,
como na aula 12, e atualize de novo:

```
ana@vm:~/planner$ .build/debug/repo refresh
refreshed from the server
2 courses, 4 sessions, 0 waiting to be sent
WeekTotal(monday: "2026-10-19", planned: 150, done: 90)
```

Dois cursos e quatro sessões, salvos no `planner.json` no caminho. **Depois pare o servidor**, com
`Ctrl-C` no terminal dele, e rode o `repo` sem comando, o que só lê:

```
ana@vm:~/planner$ .build/debug/repo
2 courses, 4 sessions, 0 waiting to be sent
WeekTotal(monday: "2026-10-19", planned: 150, done: 90)
```

O mesmo plano, sem servidor em lugar nenhum. Essa última execução é o trem: o app abriu, leu o que
tinha e mostrou. Os números da semana são as quatro sessões do servidor, 150 minutos planejados e 90
feitos, já que a sessão `s5` da aula 1 nunca esteve no servidor.
