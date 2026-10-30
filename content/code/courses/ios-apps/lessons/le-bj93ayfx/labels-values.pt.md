---
title: O rótulo diz o que é, o valor diz como está
version: 1
---

**O VoiceOver lê a tela em voz alta, um elemento de cada vez, e o que ele diz de cada elemento é algo
que o app decide.** O SwiftUI dá a todo controle um padrão razoável a partir do que consegue ver: um
`Text` é lido como a sua string, um `Button` como o seu título seguido de *botão*. O que ele não vê é
o significado. Uma linha que desenha `SQL Databases`, `50`, `min` e um visto são quatro coisas para o
olho e, lidas em ordem sem ajuda, quatro fragmentos para o ouvido. O SwiftUI desta aula não foi
executado para o curso; ele foi escrito a partir da documentação da Apple para os modificadores de
acessibilidade do SwiftUI, lida em 30 de outubro de 2026. O texto que o planner dá ao VoiceOver é
Swift puro, e essa parte rodou.

Três textos descrevem um elemento, e eles não são intercambiáveis:

| | o que responde | para uma linha de sessão |
|---|---|---|
| **rótulo** (label) | o que é isto? | `SQL Databases, 50 minutes, Monday 19 October` |
| **valor** (value) | em que estado está? | `done` |
| **dica** (hint) | o que acontece se eu agir sobre ele? | `Double-tap to mark as done` |

O erro mais comum é pôr o estado no rótulo. **Um rótulo é lido toda vez que se chega ao elemento; um
valor é o que muda.** Mantenha os dois separados e o VoiceOver anuncia sozinho uma mudança de valor,
e quem desce por uma lista ouve primeiro o curso, que é o que está procurando. A dica é lida depois
de uma pausa, e quem conhece o app desliga as dicas; o que a pessoa precisa ouvir vai no rótulo.

## As palavras, em Swift puro

A frase que o VoiceOver diz é uma função da sessão, então ela pertence ao pacote, onde um teste
consegue segurá-la. Um dia lido em voz alta é `Monday 19 October`, e não `2026-10-19`: o VoiceOver
leria os algarismos. Copie o pacote da aula 1 com `cp -r ~/planner ~/l19` e salve isto como
`Sources/PlannerCore/SpokenLabels.swift` na cópia:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/SpokenLabels.swift", "parts": [{"code": "// Sources/PlannerCore/SpokenLabels.swift\nimport Foundation\n\n/// \"2026-10-19\" as \"Monday 19 October\", the way a voice reads a day.\npublic func spokenDay(_ day: String, locale: Locale = Locale(identifier: \"en_GB\")) -> String {\n    let parse = DateFormatter()\n    parse.calendar = Calendar(identifier: .gregorian)\n    parse.timeZone = TimeZone(identifier: \"UTC\")\n    parse.locale = Locale(identifier: \"en_US_POSIX\")\n    parse.dateFormat = \"yyyy-MM-dd\"\n    guard let date = parse.date(from: day) else { return day }\n    let say = DateFormatter()\n    say.timeZone = parse.timeZone\n    say.locale = locale\n    say.setLocalizedDateFormatFromTemplate(\"EEEEdMMMM\")\n    return say.string(from: date)\n}\n", "note": "Dois formatadores: um lê o dia guardado num formato fixo e sem localidade, e o outro o escreve do jeito que o idioma de quem lê diz uma data. O `setLocalizedDateFormatFromTemplate` escolhe a ordem e as vírgulas para a localidade, então o português ganha as suas. Um dia que não se deixa ler é dito como está em vez de sumir."}, {"code": "extension StudySession {\n    /// What the row is: the course, the length and the day.\n    public func spokenLabel(courseTitle: String) -> String {\n        let length = minutes == 1 ? \"1 minute\" : \"\\(minutes) minutes\"\n        return \"\\(courseTitle), \\(length), \\(spokenDay(date))\"\n    }\n\n    /// How the row is: the one thing that changes.\n    public var spokenValue: String { done ? \"done\" : \"not done\" }\n}\n", "note": "O rótulo nunca menciona se está feito, e o valor não é outra coisa. `min` vira `minutes`, porque uma abreviação óbvia na tela é lida letra por letra ou como uma palavra que não existe. Um app de verdade traduz essas strings como qualquer outro texto que mostra, pelo seu catálogo de strings."}]}
```

E um teste que fixa o que a pessoa ouve. Salve-o como `Tests/PlannerCoreTests/SpokenLabelTests.swift`:

```swift
// Tests/PlannerCoreTests/SpokenLabelTests.swift
import Foundation
import Testing
@testable import PlannerCore

@Test func aRowIsReadAsOneSentence() {
    let s = StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50, done: true)
    #expect(s.spokenLabel(courseTitle: "SQL Databases") == "SQL Databases, 50 minutes, Monday 19 October")
    #expect(s.spokenValue == "done")
}

@Test func oneMinuteIsSingular() {
    let s = StudySession(id: "s9", courseID: "sql", date: "2026-10-25", minutes: 1)
    #expect(s.spokenLabel(courseTitle: "SQL Databases").hasSuffix("1 minute, Sunday 25 October"))
    #expect(s.spokenValue == "not done")
}

@Test func theDayFollowsTheLanguage() {
    #expect(spokenDay("2026-10-19", locale: Locale(identifier: "pt_BR")) == "segunda-feira, 19 de outubro")
}
```

```
ana@vm:~/l19$ swift test 2>&1 | grep -E "^(✔|✘|◇ Test run|Expectation)|passed after|failed after"
◇ Test run started.
✔ Test aSessionForNoCourseIsRefused() passed after 0.001 seconds.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.001 seconds.
✔ Test oneMinuteIsSingular() passed after 0.005 seconds.
✔ Test aRowIsReadAsOneSentence() passed after 0.005 seconds.
✔ Test theDayFollowsTheLanguage() passed after 0.005 seconds.
✔ Test run with 5 tests in 0 suites passed after 0.005 seconds.
```

Os dois testes da aula 1 rodam ao lado dos três novos. **A linha em português é o motivo de o dia ser formatado e não montado.** Juntar `Monday`, `19` e
`October` daria a quem lê em português `segunda-feira 19 outubro`; o formatador sabe que a língua põe
*de* antes do mês.

## A metade em SwiftUI

A linha entrega essas strings ao VoiceOver. Isto não foi executado:

```swift
// SessionRow.swift
import SwiftUI
import PlannerCore

struct SessionRow: View {
    let session: StudySession
    let courseTitle: String

    var body: some View {
        HStack {
            Text(courseTitle)
            Spacer()
            Text("\(session.minutes) min")
            Image(systemName: session.done ? "checkmark.circle.fill" : "circle")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(session.spokenLabel(courseTitle: courseTitle))
        .accessibilityValue(session.spokenValue)
    }
}
```

O `accessibilityElement(children: .ignore)` faz da linha um elemento só e descarta o que os filhos
diriam; a seção 04 trata dessa escolha e das suas duas alternativas.
