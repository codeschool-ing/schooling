---
title: Uma classe vira dado guardado com uma macro
version: 1
---

**Esta aula é lida, não praticada, e diz isso primeiro.** O SwiftData só existe nos SDKs da Apple: não
há versão para Linux, e a seção 05 mostra o compilador da máquina do curso recusando `import SwiftData`.
Tudo o que o SwiftData faz nesta aula está escrito a partir da documentação da Apple para o framework
como estava em 30 de outubro de 2026, e nada disso foi executado. A seção 05 é a única parte com
captura, porque os predicados de que uma consulta é feita vêm do Foundation e rodam em qualquer lugar.

## Para que serve o SwiftData

A documentação da Apple apresenta o SwiftData como o framework que acrescenta "persistência gerenciada"
a um app: o app descreve as suas classes de modelo em Swift, e o SwiftData as guarda no aparelho, as
busca, avisa o SwiftUI quando elas mudam e, se o app pedir, as sincroniza pelo iCloud. Ele é construído
sobre o armazenamento do Core Data, que a documentação chama de "tecnologia de persistência comprovada",
sem os arquivos de modelo do Core Data. Para o planner ele responde a uma pergunta: onde os cursos e as
sessões ficam entre uma abertura e a seguinte, para o app abrir no plano que o estudante deixou.

## Os dois registros do planner

Uma classe vira algo que o SwiftData guarda quando a macro `@Model` é presa a ela. As do planner ficam no
target do app, porque importam o SwiftData:

```swift
// Records.swift
import Foundation
import SwiftData
import PlannerCore

@Model
final class CourseRecord {
    @Attribute(.unique) var courseID: String
    var title: String
    @Relationship(deleteRule: .cascade, inverse: \SessionRecord.course)
    var sessions: [SessionRecord] = []

    init(courseID: String, title: String) {
        self.courseID = courseID
        self.title = title
    }
}

@Model
final class SessionRecord {
    @Attribute(.unique) var sessionID: String
    var date: String
    var minutes: Int
    var done: Bool
    var course: CourseRecord?

    init(sessionID: String, date: String, minutes: Int, done: Bool = false) {
        self.sessionID = sessionID
        self.date = date
        self.minutes = minutes
        self.done = done
    }
}
```

A documentação da Apple para `Model()` diz o que a macro acrescenta quando o app é compilado:
conformidade a `PersistentModel`, que o SwiftData usa para examinar a classe e gerar o esquema dela, e a
`Observable`, que é a mesma observação que a aula 7 descreveu. **Então um registro é algo que o SwiftUI já
sabe vigiar**: mude `record.done` e toda view que o leu roda de novo, sem `@Published` e sem notificação
sua.

## Por que registros, e não os tipos da aula 1

O planner já tem `Course` e `StudySession`, e o passo óbvio é pôr `@Model` neles. **Isso não dá, e nem
deveria ser desejado.** O `@Model` se prende a uma classe, e os tipos da aula 1 são structs, valores que
se copiam, que é o que deixa um teste montar um plano e compará-lo. Mais importante, eles moram no pacote
que compila no Linux, e no momento em que o `PlannerCore` importar o SwiftData ele deixa de compilar fora
dos sistemas da Apple, levando junto todos os testes do curso.

Então o app tem duas formas dos mesmos dados. **Os registros são como eles são guardados; os valores são
como se raciocina sobre eles**, como são testados e mostrados. Converter de um para o outro são poucas
linhas, e a aula 14 os põe atrás de um repositório para que nenhuma tela precise saber qual tem nas mãos:

```swift
// Records.swift, continued
extension SessionRecord {
    /// The planner's value for this record, or nil for a session that lost its course.
    var value: StudySession? {
        guard let course else { return nil }
        return StudySession(id: sessionID, courseID: course.courseID, date: date, minutes: minutes, done: done)
    }
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l13-two-shapes\" aria-label=\"Duas colunas. À esquerda, dentro do target do app, que só compila num Mac: CourseRecord e SessionRecord, classes com a macro Model, ligadas por uma relação, guardadas pelo SwiftData num arquivo no aparelho. À direita, dentro do pacote PlannerCore, que compila em qualquer lugar: os valores Course e StudySession, ligados por courseID. Uma seta chamada value vai dos registros aos valores, e outra chamada insert volta.\"><defs><marker id=\"l13-two-shapes-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l13-two-shapes-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-two-shapes-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l13-two-shapes-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o target do app: só num Mac</text><rect x=\"50\" y=\"64\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">@Model CourseRecord</text><rect x=\"50\" y=\"160\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">@Model SessionRecord</text><path d=\"M170 110 L170 156\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-two-shapes-ah-amber)\"></path><text x=\"180\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma relação</text><text x=\"170\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">guardados pelo SwiftData,</text><text x=\"170\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">num arquivo no aparelho</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">PlannerCore: em qualquer lugar</text><rect x=\"430\" y=\"64\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">struct Course</text><rect x=\"430\" y=\"160\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">struct StudySession</text><path d=\"M550 156 L550 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-two-shapes-ah-phosphor)\"></path><text x=\"560\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">courseID, texto</text><text x=\"550\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">testados pelo swift test,</text><text x=\"550\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mostrados pelas telas</text><path d=\"M322 172 L398 172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-two-shapes-ah-paper-dim)\"></path><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.value</text><path d=\"M398 196 L322 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-two-shapes-ah-paper-dim)\"></path><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">insert</text></svg>", "caption": "Duas formas das mesmas sessões. Os registros são como o app as guarda; os valores são como ele raciocina sobre elas, e só os valores compilam no Linux."}
```

`courseID` e `sessionID` são os ids do próprio planner, os que o servidor e as outras plataformas usam. O
SwiftData também dá a cada registro um identificador próprio, `persistentModelID`, que não significa nada
fora deste armazenamento. **O identificador interno de um armazenamento nunca é o que vai para o
servidor**: a mesma sessão num segundo telefone tem outro.

A data continua texto, `2026-10-21`, pelo motivo da aula 1: um dia não é um instante, e a documentação da
Apple para o framework lista `String` entre os tipos que o SwiftData guarda como são.
