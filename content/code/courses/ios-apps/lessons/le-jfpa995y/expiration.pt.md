---
title: Quando o tempo acaba
version: 1
---

**Uma tarefa em segundo plano termina quando o sistema diz, e o trabalho do app tem de estar certo em
qualquer ponto em que isso caia.** A seção 03 citou a documentação da Apple: quando o tempo acaba, o
sistema cancela a tarefa que o handler está rodando. O trabalho não chega a terminar o laço, escrever o
resumo ou arrumar as coisas. O que ele não salvou se perde, e o que fez pela metade fica pela metade.

Então a pergunta para a sincronização em segundo plano do planner não é como terminar em 30 segundos.
**É como estar certa depois de qualquer número de segundos**: toda sessão que o servidor confirmou fica
registrada como enviada, toda sessão que ele não confirmou continua esperando, e nada é enviado duas
vezes. O `sync` da aula 14 salvava uma vez, no fim, que é o formato errado para isso.

## Sincronizar, uma sessão por vez

Salve isto como `Sources/PlannerCore/BackgroundSync.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/BackgroundSync.swift", "parts": [{"code": "// Sources/PlannerCore/BackgroundSync.swift\nextension PlannerRepository {\n    /// Send pending sessions one at a time for as long as the task is allowed\n    /// to run. Each success is saved at once, so a task the system cancels\n    /// halfway keeps everything it had already sent.\n", "note": "Uma extensão do repositório da aula 14, num arquivo próprio: ela alcança o mesmo `snapshot`, a mesma `source` e o mesmo `save`, porque uma extensão no mesmo módulo enxerga os membros internos."}, {"code": "    public func syncUntilCancelled() async -> (sent: Int, left: Int) {\n        var sent = 0\n        for p in snapshot.pending {\n", "note": "O laço envia uma sessão pendente por vez e devolve o que conseguiu. Ele pergunta `Task.isCancelled` antes de cada uma, então uma tarefa cancelada não começa nada novo."}, {"code": "            if Task.isCancelled { break }\n            do throws(APIError) {\n                let s = try await source.add(p.session)\n                snapshot.pending.removeAll { $0.id == s.id }\n                if !snapshot.sessions.contains(where: { $0.id == s.id }) {\n                    snapshot.sessions.append(WireSession(s))\n                }\n                sent += 1\n                save()\n", "note": "**Cada sucesso é salvo na hora**, não no fim. É esse todo o ponto: quando o tempo do sistema acaba entre duas sessões, a primeira já está no aparelho como enviada, e nada vai enviá-la duas vezes."}, {"code": "            } catch {\n                if case .status(let code, _) = error, (400..<500).contains(code) {\n                    snapshot.pending.removeAll { $0.id == p.id }\n                    save()\n                    continue\n                }\n                break                          // offline or cancelled: stop, keep the rest\n            }\n        }\n        return (sent, snapshot.pending.count)\n    }\n}\n", "note": "Uma recusa é descartada como o `sync` da aula 14 descarta, e o laço segue. Qualquer outra coisa, inclusive o cancelamento que chega como `APIError.cancelled` no meio de um pedido, para o laço e deixa o resto pendente."}]}
```

## A expiração, no Linux

O cancelamento do sistema é o cancelamento comum do Swift, então dá para praticá-lo sem o sistema:
começar o trabalho numa `Task`, esperar o tempo que o orçamento permite, e cancelar. Troque o
`Sources/background/main.swift` por esta versão, que mantém o trabalho da seção 06 como o comando
`next` e acrescenta o `run`. O `SlowSource` dela embrulha o cliente de verdade e faz todo envio levar
400 milissegundos, uma rede móvel lenta, para um orçamento curto cortar o trabalho no meio:

```swift
// Sources/background/main.swift
import Foundation
import PlannerCore

/// The planner's server, reached over a slow connection: every post takes 400 ms.
struct SlowSource: PlanSource {
    let api: APIClient

    func courses() async throws(APIError) -> [Course] { try await api.courses() }
    func sessions(course id: String) async throws(APIError) -> [StudySession] { try await api.sessions(course: id) }
    func add(_ s: StudySession) async throws(APIError) -> StudySession {
        do { try await Task.sleep(for: .milliseconds(400)) } catch { throw .cancelled }
        return try await api.add(s)
    }
}

let args = Array(CommandLine.arguments.dropFirst())
let api = APIClient(base: URL(string: "http://127.0.0.1:8012")!)
let repo = try PlannerRepository(source: SlowSource(api: api), store: FileStore(url: URL(fileURLWithPath: "planner.json")))

switch args.first {
case "run":
    // The system's budget for this run, in seconds; when it is up, the task is cancelled.
    let budget = Double(args[1])!
    let work = Task { await repo.syncUntilCancelled() }
    try await Task.sleep(for: .seconds(budget))
    work.cancel()
    let (sent, left) = await work.value
    print("given \(budget) s: sent \(sent), \(left) still waiting")
case "next":
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: args[1])!
    let format = ISO8601DateFormatter()
    format.timeZone = calendar.timeZone
    let now = format.date(from: args[2])!
    for pending in [0, 3] {
        let next = nextRefresh(after: now, pending: pending, calendar: calendar)
        print("\(pending) waiting: next refresh \(format.string(from: next)), in \(Int(next.timeIntervalSince(now) / 60)) min")
    }
default:
    print(await repo.pendingCount, "waiting to be sent")
}
```

Para ter o que enviar, o aparelho precisa de sessões acrescentadas offline. Com o servidor da aula 12
rodando, atualize uma vez para o aparelho conhecer os cursos, depois pare o servidor e acrescente seis
sessões com o `repo` da aula 14:

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (2.46 secs)
ana@vm:~/planner$ .build/debug/repo refresh | head -1
refreshed from the server
ana@vm:~/planner$ for n in 1 2 3 4 5 6; do .build/debug/repo add b$n mobile 2026-10-22 20 | head -1; done
added b1 on the device
added b2 on the device
added b3 on the device
added b4 on the device
added b5 on the device
added b6 on the device
ana@vm:~/planner$ .build/debug/background
6 waiting to be sent
```

Inicie o servidor de novo, e dê ao trabalho em segundo plano um segundo por vez:

```
ana@vm:~/planner$ .build/debug/background run 1.0
given 1.0 s: sent 2, 4 still waiting
ana@vm:~/planner$ .build/debug/background run 1.0
given 1.0 s: sent 2, 2 still waiting
ana@vm:~/planner$ .build/debug/background run 1.0
given 1.0 s: sent 2, 0 still waiting
```

**Três execuções de um segundo enviaram duas sessões cada, e nada se perdeu nem dobrou entre elas.**
Cada execução enviou duas nos seus 800 milissegundos de envio e foi cancelada durante a espera do
terceiro; essa sessão ficou pendente e foi a primeira na execução seguinte. O terminal do servidor
registrou seis envios, um por sessão. Num telefone, este é o mesmo trabalho espalhado por três
atualizações do app, talvez com horas entre elas, cada uma cortada pelo sistema onde o tempo dela
acabou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l16-runs\" aria-label=\"Três execuções em segundo plano desenhadas como linhas numa linha do tempo, cada uma de um segundo. Em cada uma, dois envios de 400 milissegundos terminam, cada um seguido de um salvamento, e um terceiro envio começa e é cortado quando o segundo acaba e a tarefa é cancelada. Ao lado de cada linha, as sessões esperando: seis antes da primeira execução, quatro depois dela, duas depois da segunda, nenhuma depois da terceira. Entre as linhas, a nota de que num telefone as execuções podem estar a horas de distância.\"><defs><marker id=\"l16-runs-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l16-runs-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l16-runs-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l16-runs-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 s</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.0 s</text><text x=\"670\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">esperando</text><text x=\"60\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">execução 1</text><rect x=\"120.0\" y=\"48\" width=\"186.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"213.0\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">envio b1, salvo</text><rect x=\"312.0\" y=\"48\" width=\"186.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"405.0\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">envio b2, salvo</text><rect x=\"504.0\" y=\"48\" width=\"96.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"552.0\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">b3</text><path d=\"M600 42 L600 86\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"670\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6 → 4</text><text x=\"360.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">num telefone, talvez horas depois</text><text x=\"60\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">execução 2</text><rect x=\"120.0\" y=\"130\" width=\"186.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"213.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">envio b3, salvo</text><rect x=\"312.0\" y=\"130\" width=\"186.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"405.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">envio b4, salvo</text><rect x=\"504.0\" y=\"130\" width=\"96.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"552.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">b5</text><path d=\"M600 124 L600 168\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"670\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4 → 2</text><text x=\"360.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">num telefone, talvez horas depois</text><text x=\"60\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">execução 3</text><rect x=\"120.0\" y=\"212\" width=\"186.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"213.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">envio b5, salvo</text><rect x=\"312.0\" y=\"212\" width=\"186.0\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"405.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">envio b6, salvo</text><path d=\"M600 206 L600 250\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"670\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2 → 0</text><text x=\"600\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cancelada</text></svg>", "caption": "Todo sucesso é salvo no momento em que acontece, então onde quer que o cancelamento caia, o envio cortado continua esperando e vai primeiro da próxima vez."}
```

## Percebendo, quando há algo a arrumar

O trabalho do planner não precisa de arrumação: a lista pendente está sempre certa. Um trabalho que
segura um recurso, um arquivo escrito pela metade ou uma transação aberta, pode ser avisado no instante
em que o cancelamento chega, que é para isso que serve a sugestão da documentação de
`withTaskCancellationHandler`. O handler roda na hora, na thread que cancelou a tarefa, então ele só
deve sinalizar, nunca fazer a limpeza ele mesmo.
