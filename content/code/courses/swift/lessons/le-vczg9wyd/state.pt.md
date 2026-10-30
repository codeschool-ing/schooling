---
title: A vida de uma sessão como máquina de estados
version: 1
---

Uma sessão de estudo passa por etapas: planejada, depois em andamento, depois feita, e uma sessão
planejada pode ser pulada em vez disso. Uma struct com os booleanos `isRunning`, `isDone` e
`isSkipped` permite oito combinações, das quais quatro fazem sentido, e nada impede uma sessão de
estar feita e pulada ao mesmo tempo. **Um enum com um caso por etapa permite exatamente as etapas que
existem**, e os valores associados carregam o que cada etapa sabe:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l07-states\" aria-label=\"Um diagrama de estados. Quatro estados em caixas: planned com minutos, running com os minutos planejados e uma hora de início, done com minutos, e skipped. Setas: start vai de planned para running, finish vai de running para done, skip vai de planned para skipped. Uma nota diz que qualquer outro evento é recusado e o estado fica como está.\"><defs><marker id=\"l07-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l07-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"30\" y=\"60\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">.planned</text><text x=\"120\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">minutes</text><rect x=\"270\" y=\"60\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">.running</text><text x=\"360\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">planned, startedAt</text><rect x=\"510\" y=\"60\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">.done</text><text x=\"600\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">minutes</text><rect x=\"270\" y=\"170\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">.skipped</text><path d=\"M210 88 L268 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-ah)\"></path><text x=\"239\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">start(at:)</text><path d=\"M450 88 L508 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-ah)\"></path><text x=\"479\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">finish(minutes:)</text><path d=\"M120 116 L120 198 L268 198\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-ah2)\"></path><text x=\"150\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">skip</text><text x=\"600\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">qualquer outro evento: recusado, o estado fica</text></svg>", "caption": "Três movimentos são permitidos e todo outro par de estado e evento é recusado. Cada estado carrega só o que é verdade nele."}
```

As transições pertencem ao tipo, como um método `mutating` que recebe um evento e decide qual é o
próximo estado. Um switch sobre o par, estado e evento, lista os movimentos permitidos, e todo o
resto é recusado em vez de feito pela metade:

```swift
// Status.swift
enum Status {
    case planned(minutes: Int)
    case running(planned: Int, startedAt: String)
    case done(minutes: Int)
    case skipped
}
enum Event {
    case start(at: String)
    case finish(minutes: Int)
    case skip
}
extension Status {
    mutating func handle(_ event: Event) -> Bool {
        switch (self, event) {
        case let (.planned(minutes), .start(at)):
            self = .running(planned: minutes, startedAt: at)
        case let (.running, .finish(minutes)):
            self = .done(minutes: minutes)
        case (.planned, .skip):
            self = .skipped
        default:
            return false
        }
        return true
    }
}
var status = Status.planned(minutes: 45)
let events: [Event] = [.finish(minutes: 10), .start(at: "19:00"), .skip, .finish(minutes: 50)]
for event in events {
    let accepted = status.handle(event)
    print(accepted ? "accepted" : "refused ", event, "->", status)
}
```

```
ana@vm:~/sw/l07$ swift Status.swift
refused  finish(minutes: 10) -> planned(minutes: 45)
accepted start(at: "19:00") -> running(planned: 45, startedAt: "19:00")
refused  skip -> running(planned: 45, startedAt: "19:00")
accepted finish(minutes: 50) -> done(minutes: 50)
```

Quatro eventos, dois recusados. **Terminar uma sessão que nunca começou foi recusado**, e pular uma
já em andamento também; nos dois casos o status ficou como estava. O `self = …` troca o valor inteiro
por um caso novo, que é como um método `mutating` de um enum o muda. O `case let (…)` liga todos os
nomes do padrão de uma vez, então `minutes` e `at` saem de dois enums diferentes numa linha.

O `default` aqui é proposital e a regra da seção 04 continua valendo: este switch é sobre pares, e
listar todo par recusado, nove dos doze, esconderia os três que importam. O que o `default` custa é
exatamente o aviso que a seção 04 descreveu. Um caso novo de `Status` ainda é pego onde quer que um
switch só sobre `Status` liste os casos, como uma tela que mostra cada estado, e esse switch é onde o
caso novo ganha significado.

Esse é o formato que o `ios-apps` dá a uma sessão na tela, e o formato que a lição 13 grava em JSON.
