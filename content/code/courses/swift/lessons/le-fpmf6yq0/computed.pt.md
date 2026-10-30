---
title: Propriedades computadas
version: 1
---

O total de minutos da semana poderia ser uma propriedade armazenada, atualizada toda vez que uma
sessão é acrescentada. Seria então mais uma coisa a manter em dia, e no dia em que alguém acrescentar
uma sessão sem atualizar o total, os dois discordam. **Uma propriedade computada não guarda nada: ela
roda código toda vez que é lida**, então não tem como discordar dos dados de que é calculada.

```schooling-example
{"language": "swift", "file": "Computed.swift", "parts": [{"code": "// Computed.swift\nstruct Week {\n    var sessions: [Int]\n    var goal = 300", "note": "Duas propriedades armazenadas: os minutos de cada sessão e a meta da semana, com um valor padrão."}, {"code": "    var total: Int { sessions.reduce(0, +) }\n    var remaining: Int { max(goal - total, 0) }\n}", "note": "Duas propriedades computadas. O tipo é obrigatório, e as chaves guardam o código que roda a cada leitura. Um corpo de uma expressão a devolve sem `return`."}, {"code": "struct StudySession {\n    var minutes: Int\n    var hours: Double {\n        get { Double(minutes) / 60 }\n        set { minutes = Int(newValue * 60) }\n    }\n}", "note": "Uma propriedade computada com getter e setter. O setter recebe o valor atribuído como `newValue` e o escreve na propriedade armazenada."}, {"code": "var week = Week(sessions: [45, 30])\nprint(week.total, week.remaining)\nweek.sessions.append(60)\nprint(week.total, week.remaining)\nvar session = StudySession(minutes: 45)\nsession.hours = 1.25\nprint(session.minutes, session.hours)", "note": "Ler `total` depois do append roda o código de novo, então o total acompanha as sessões sem ninguém atualizá-lo."}], "output": "75 225\n135 165\n75 1.25"}
```

Cada leitura rodou o código de novo: `total` virou 135 depois da terceira sessão sem ninguém mexer
nele. `remaining` nunca fica abaixo de zero, porque o `max` fica com o maior dos dois argumentos.

## Só leitura, a menos que diga outra coisa

Uma propriedade computada só com `get`, ou com o corpo escrito direto nas chaves como o `total`, é
**só de leitura**. Atribuir a ela é recusado, porque não há onde pôr o valor:

```swift
// GetOnly.swift
struct Week {
    var sessions: [Int]
    var total: Int { sessions.reduce(0, +) }
}
var week = Week(sessions: [45, 30])
week.total = 200
```

```
ana@vm:~/sw/l06$ swiftc GetOnly.swift -o getonly
GetOnly.swift:7:6: error: cannot assign to property: 'total' is a get-only property
5 | }
6 | var week = Week(sessions: [45, 30])
7 | week.total = 200
  |      `- error: cannot assign to property: 'total' is a get-only property
8 | 
```

O `hours` do `Computed.swift` tem também um `set`, e o setter recebe o valor novo como `newValue`.
Pôr as horas de uma sessão em 1.25 escreveu 75 em `minutes`, a propriedade realmente armazenada.
**Um setter traduz; ele não guarda**: o valor mora em `minutes`, e `hours` é um segundo jeito de lê-lo
e escrevê-lo.

## Propriedade ou método?

`total` poderia muito bem ser `func total() -> Int`, e a aula 5 o escreveu assim. A convenção das
diretrizes de API do próprio Swift é que uma propriedade se lê como um fato sobre o valor e é barata;
um método se lê como uma ação, e pode custar algo ou receber argumentos. **Faça uma propriedade quando
quem chama não deveria precisar saber que ela é computada.** O total dos minutos de uma semana é um
fato; ler um arquivo do disco é uma ação, seja como for escrito.
