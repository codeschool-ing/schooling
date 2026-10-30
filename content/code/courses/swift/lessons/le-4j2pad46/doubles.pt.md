---
title: Dublês de teste, pelo protocolo
version: 1
---

O `MemoryStore` da seção 05 fez as vezes de um servidor real. Um substituto assim é um **dublê de
teste**, como o dublê que leva o tombo no lugar do ator, e o protocolo da aula 10 é o que o tornou
possível: o `Syncer` pede `any SessionStore`, e qualquer coisa que se conforme serve. Um dublê é
como um teste alcança os casos que um servidor real só produziria num dia ruim.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l18-seam\" aria-label=\"O Syncer pede any SessionStore, um protocolo. Quatro coisas se conformam a ele: o servidor real, usado pelo app; MemoryStore, um fake que guarda sessões num array; OfflineStore, um stub que sempre lança erro; e FlakyStore, um spy que conta as chamadas e falha na segunda.\"><defs><marker id=\"l18-seam-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-seam-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"110\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Syncer</text><text x=\"105\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pede um store</text><rect x=\"260\" y=\"110\" width=\"190\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"355\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">any SessionStore</text><text x=\"355\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a costura, um protocolo</text><path d=\"M182 140 L256 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-seam-ah-phosphor)\"></path><rect x=\"520\" y=\"30\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o servidor real</text><text x=\"610\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no app</text><path d=\"M516 55 L452 140\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-seam-ah-amber)\"></path><rect x=\"520\" y=\"100\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">MemoryStore</text><text x=\"610\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fake: um array</text><path d=\"M516 125 L452 140\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-seam-ah-amber)\" stroke-dasharray=\"5 4\"></path><rect x=\"520\" y=\"170\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">OfflineStore</text><text x=\"610\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">stub: sempre lança erro</text><path d=\"M516 195 L452 140\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-seam-ah-amber)\" stroke-dasharray=\"5 4\"></path><rect x=\"520\" y=\"240\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"257\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">FlakyStore</text><text x=\"610\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">spy: conta, falha na 2ª</text><path d=\"M516 265 L452 140\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-seam-ah-amber)\" stroke-dasharray=\"5 4\"></path><text x=\"250\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">O Syncer é compilado uma vez, e</text><text x=\"250\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nunca sabe qual recebeu.</text></svg>", "caption": "O protocolo é a costura: o código testado pede qualquer SessionStore, e cada teste lhe entrega o dublê que produz o caso de que precisa."}
```

## Quatro tipos, pelo que servem

Os nomes vêm do livro de Gerard Meszaros sobre padrões de teste e são usados com folga; o que
importa é o que cada um deixa um teste fazer.

| dublê | o que faz | nesta aula |
|---|---|---|
| **fake** | funciona, de um jeito mais simples que o real | `MemoryStore`, um array no lugar de um servidor |
| **stub** | dá uma resposta fixa, ou uma falha fixa | `OfflineStore` abaixo, que sempre lança erro |
| **spy** | registra como foi usado, para o teste inspecionar | `FlakyStore` abaixo conta as chamadas |
| **mock** | é avisado de antemão de que chamadas esperar, e as confere sozinho | nenhum: o Swift não tem biblioteca padrão de mocks, e um spy cobre o mesmo terreno |

## Um store fora do ar

O teste mais valioso do `sync` é aquele em que a rede caiu, e esse é justamente o que não se pode
pedir a um servidor real quando se quer:

```swift
// Tests/PlannerCoreTests/OfflineTests.swift
import Testing
@testable import PlannerCore

enum StoreError: Error {
    case offline
}

struct OfflineStore: SessionStore {
    func save(_ sessions: [StudySession]) async throws {
        throw StoreError.offline
    }
}

actor FlakyStore: SessionStore {
    private(set) var attempts = 0
    private(set) var saved: [StudySession] = []

    func save(_ sessions: [StudySession]) async throws {
        attempts += 1
        if attempts == 2 { throw StoreError.offline }
        saved += sessions
    }
}

func weekOfThree() -> Week {
    var week = Week()
    week.add(StudySession(course: "swift", minutes: 45, done: true))
    week.add(StudySession(course: "kotlin", minutes: 60, done: true))
    week.add(StudySession(course: "swift", minutes: 30, done: true))
    return week
}

@Suite struct OfflineTests {
    @Test func anOfflineStoreStopsTheSync() async {
        let syncer = Syncer(store: OfflineStore())
        await #expect(throws: StoreError.offline) {
            try await syncer.sync(weekOfThree())
        }
    }

    @Test func aFailureHalfwayKeepsWhatWasSaved() async {
        let store = FlakyStore()
        await #expect(throws: StoreError.offline) {
            try await Syncer(store: store).sync(weekOfThree())
        }
        #expect(await store.attempts == 2)
        #expect(await store.saved.count == 1)
    }
}
```

**O `#expect(throws:)` só passa se o bloco lançar aquele erro**, e falha se lançar outro ou retornar
normalmente. O bloco dele é assíncrono aqui, então a expectativa inteira é aguardada.

```
ana@vm:~/sw/l18/planner$ swift test --disable-xctest --filter OfflineTests 2>&1 | grep -v frontend
Building for debugging...
[Pre-planning 1 / 95]
[Planning deferred tasks]
[7 / 17] PlannerCoreTests-product
[7 / 18] PlannerCoreTests-product
[11 / 17] PlannerCoreTests-product
[14 / 17] PlannerCoreTests-product
[18 / 20] PlannerCoreTests-test-runner
[19 / 21] PlannerCoreTests-test-runner
[21 / 21] PlannerCoreTests-test-runner
Build complete! (3.73 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Suite OfflineTests started.
◇ Test anOfflineStoreStopsTheSync() started.
◇ Test aFailureHalfwayKeepsWhatWasSaved() started.
✔ Test anOfflineStoreStopsTheSync() passed after 0.049 seconds.
✔ Test aFailureHalfwayKeepsWhatWasSaved() passed after 0.184 seconds.
✔ Suite OfflineTests passed after 0.219 seconds.
✔ Test run with 2 tests in 1 suite passed after 0.219 seconds.
```

## O que o spy encontrou

O segundo teste passa, e vale dizer em palavras o que ele fixa: quando o store falha na segunda
sessão, o `sync` para ali, **a primeira sessão já está salva, e a terceira nem foi tentada**. Nada no
`Syncer` diz isso num comentário, e antes deste teste ninguém tinha decidido se esse era o
comportamento desejado. É razoável, porque salvar uma sessão duas vezes seria pior que salvá-la
tarde, e as aulas 9 e 10 do `mobile-offline` tratam de repetir uma sincronização dessas com
segurança. O teste agora prende o código a isso: se alguém reescrever o `sync` para continuar depois
de uma falha, é este teste que vai avisar.

**Um dublê deve ser tão pequeno quanto o teste precisa.** O `OfflineStore` tem uma linha de
comportamento. Dublês que ganham lógica própria, defeitos próprios e testes próprios são sinal de que
o protocolo pede demais, que é a pergunta da aula 10 sobre costuras voltando pelo outro lado.
