---
title: Um protocolo como costura
version: 1
---

O planner lembra uma estudante de quais sessões são hoje. "Hoje" vem do relógio do computador, então
o mesmo código imprime uma resposta diferente a cada dia, e um teste escrito numa segunda falha numa
terça. **Um protocolo no lugar de uma dependência concreta dá ao código uma costura**: o programa passa
a coisa real, e um teste, ou uma demonstração, passa algo que ele controla.

```swift
// Reminder.swift
import Foundation

protocol Clock {
    func now() -> Date
}

struct SystemClock: Clock {
    func now() -> Date { Date() }
}

struct FixedClock: Clock {
    let date: Date
    func now() -> Date { date }
}

struct StudySession {
    var title: String
    var day: DateComponents
}

struct Reminder {
    let clock: any Clock
    let calendar = Calendar(identifier: .gregorian)

    func today(_ sessions: [StudySession]) -> [String] {
        let now = calendar.dateComponents([.year, .month, .day], from: clock.now())
        return sessions.filter { $0.day == now }.map(\.title)
    }
}

let sessions = [
    StudySession(title: "Optionals", day: DateComponents(year: 2026, month: 11, day: 2)),
    StudySession(title: "Generics", day: DateComponents(year: 2026, month: 11, day: 2)),
    StudySession(title: "Protocols", day: DateComponents(year: 2026, month: 11, day: 3)),
]

let monday = DateComponents(calendar: Calendar(identifier: .gregorian),
                            year: 2026, month: 11, day: 2, hour: 9).date!
print("fixed: ", Reminder(clock: FixedClock(date: monday)).today(sessions))
print("system:", Reminder(clock: SystemClock()).today(sessions))
```

```
ana@vm:~/sw/l10$ swift Reminder.swift
fixed:  ["Optionals", "Generics"]
system: []
```

`Reminder` não sabe que relógio tem. Ele guarda um `any Clock` e chama `now()`, a caixa da aula 9 em
ação, então qualquer relógio serve. Com o relógio fixo em segunda, 2 de novembro de 2026, ele acha as
duas sessões daquele dia. Com o relógio do sistema não achou nenhuma, porque o dia em que esta
transcrição foi gravada, 30 de outubro de 2026, não tem sessão na lista. **O código testado é o mesmo
nas duas linhas; só o que foi passado muda.** O `Foundation` é a biblioteca da Apple de datas,
calendários, arquivos e JSON, e vem com o toolchain para Linux também; a aula 20 lista onde ele
difere.

## Por que um protocolo e não uma flag

A alternativa é um `Reminder` com um `var testDate: Date?` que ele confere antes de perguntar ao
sistema. Isso põe o teste dentro do produto, e cada nova dependência, um repositório de sessões ou um
cliente de rede, acrescenta outra flag. Com uma costura, o produto nem sabe que um teste existe. **A
dependência é nomeada pelo que faz, `Clock`, e o código depende disso e de nada mais**, que é a regra
da seção 03 aplicada a colaboradores em vez de dados.

## Onde compensa

A aula 18 escreve os testes que usam isto: um `Clock` falso que é segunda-feira, um repositório falso
com três sessões e verificações sobre o que o lembrete diz. A aula 14 faz o mesmo com um servidor
lento, com um falso que responde na hora. No iOS a mesma costura é como uma tela aparece num preview
com dados de exemplo em vez do que está no telefone, o que o `ios-apps` usa o tempo todo e que não
roda aqui. Cada caso é um protocolo com um ou dois requisitos, uma implementação real e uma falsa.
