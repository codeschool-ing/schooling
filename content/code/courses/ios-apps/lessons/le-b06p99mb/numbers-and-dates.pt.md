---
title: Números e datas, os dois tipos de digitação que dão errado
version: 1
---

**Minutos e uma data são os dois campos do `SessionForm`, e cada um falha de um jeito que o outro não
falha.** Os minutos falham alto: alguém digita uma palavra, ou um decimal, e o rascunho diz isso. A data
falha calada: o seletor sempre guarda um instante válido, e o erro está em qual dia esse instante é
considerado.

## O dia em que um instante cai

Um `DatePicker` se liga a um `Date`, e a documentação da Apple para o `Date` é clara sobre o que ele é:
um ponto no tempo, sem calendário e sem fuso horário. Um seletor que mostra só a data ainda entrega um
instante, o começo do dia ou a hora que ele guardava antes, no fuso do próprio telefone. A aula 1 guarda
o dia de uma sessão como texto, `2026-10-21`, então em algum lugar o instante tem de virar um dia, e **o
calendário que faz isso tem de ser o que a pessoa estava olhando**.

O `mondayOf` da aula 1 fixa um calendário em UTC, e ali isso está certo: ele lê um dia que já é texto.
Ler um instante escolhido em UTC é o erro. Este programa mostra os dois, e depois passa pelo rascunho
sete coisas que uma pessoa poderia digitar. Salve-o como `Sources/draft/main.swift`:

```swift
// Sources/draft/main.swift
import Foundation
import PlannerCore

var saoPaulo = Calendar(identifier: .gregorian)
saoPaulo.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
var utc = Calendar(identifier: .gregorian)
utc.timeZone = TimeZone(identifier: "UTC")!

// 23:30 on Wednesday 21 October in São Paulo, as a DatePicker hands it over
let picked = ISO8601DateFormatter().date(from: "2026-10-21T23:30:00-03:00")!
print("instant      ", picked)
print("São Paulo day", day(of: picked, in: saoPaulo))
print("UTC day      ", day(of: picked, in: utc))

for typed in ["45", " 45 ", "", "forty", "1.5", "0", "600"] {
    let draft = SessionDraft(courseID: "sql", date: picked, minutesText: typed)
    let result = draft.session(id: "s6", calendar: saoPaulo).map { "\($0.date) \($0.minutes) min" }
    print("\"\(typed)\"".padding(toLength: 9, withPad: " ", startingAt: 0), draft.problems, result ?? "no session")
}
```

Compile e rode:

```
ana@vm:~/l10$ swift build
Building for debugging...
[Pre-planning 1 / 124]
Build complete! (0.63 secs)
ana@vm:~/l10$ .build/debug/draft
instant       2026-10-22 02:30:00 +0000
São Paulo day 2026-10-21
UTC day       2026-10-22
"45"      [] 2026-10-21 45 min
" 45 "    [] 2026-10-21 45 min
""        [PlannerCore.DraftProblem.noMinutes] no session
"forty"   [PlannerCore.DraftProblem.minutesNotWhole("forty")] no session
"1.5"     [PlannerCore.DraftProblem.minutesNotWhole("1.5")] no session
"0"       [PlannerCore.DraftProblem.minutesOutOfRange(0)] no session
"600"     [PlannerCore.DraftProblem.minutesOutOfRange(600)] no session
```

**Onze e meia da noite de quarta-feira em São Paulo já é quinta-feira em UTC.** O instante é o mesmo,
impresso pelo `print` em UTC como `02:30:00 +0000` do dia 22; lido no calendário da pessoa ele é o dia
21, que é o dia que ela escolheu. Um planner que usasse UTC aqui arquivaria toda sessão do fim da noite
como sendo de amanhã, para todo mundo a oeste de Greenwich, e só depois das nove da noite em São Paulo,
então ninguém testando na hora do almoço veria. No app o calendário é o `Calendar.current`, que segue os
ajustes do telefone; o programa cita São Paulo para que a saída dele não dependa da máquina em que roda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l10-day\" aria-label=\"Duas linhas do tempo, uma sobre a outra, da noite de 21 de outubro à manhã de 22 de outubro. A de cima é o calendário de São Paulo, cuja meia-noite cai três horas depois da de baixo, o calendário UTC. Uma linha vertical marca um instante, 23:30 em São Paulo, que é 02:30 em UTC: na linha de cima ele cai no dia 2026-10-21, na de baixo em 2026-10-22.\"><defs><marker id=\"l10-day-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l10-day-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-day-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l10-day-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">calendário de São Paulo</text><rect x=\"40\" y=\"42\" width=\"360\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"220.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">2026-10-21</text><rect x=\"400\" y=\"42\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">2026-10-22</text><text x=\"406\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">meia-noite</text><text x=\"40\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">calendário UTC</text><rect x=\"40\" y=\"144\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"160.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">2026-10-21</text><rect x=\"280\" y=\"144\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">2026-10-22</text><text x=\"280\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">meia-noite</text><path d=\"M380.0 30 L380.0 40\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M380.0 86 L380.0 140\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M380.0 188 L380.0 206\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"380.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o instante escolhido: 23:30 aqui, 02:30 UTC</text></svg>", "caption": "Um instante, dois calendários. Lido no calendário que a pessoa via, é o dia que ela escolheu; lido em UTC, é o seguinte."}
```

## O que o `Int` aceita

A coluna dos minutos é a regra do rascunho tornada visível:

- ` 45 ` é aceito, porque o rascunho apara os espaços antes. A correção automática de um teclado põe um
  espaço depois de uma palavra mais vezes do que alguém percebe.
- `forty` e `1.5` são os dois `minutesNotWhole`: o `Int` lê dígitos e nada mais, então um decimal é
  recusado em vez de arredondado. Arredondar transformaria um `1.5` de horas digitado por engano em dois
  minutos.
- `0` e `600` são números, e estão fora do intervalo, o que é outra mensagem.
- o campo vazio é `noMinutes`, não `minutesNotWhole("")`: "digite os minutos" é uma coisa mais gentil de
  dizer do que "isso não é um número" para alguém que ainda não digitou.

**O `Int` não lê um número localizado**, e para minutos tudo bem: ninguém escreve milhares de minutos
com separador. Para um campo que precisa disso, o `IntegerFormatStyle` do Foundation interpreta o texto
do jeito que a localidade da pessoa o escreve, e o `TextField(value:format:)` da seção 03 usa esse tipo
de estilo.
