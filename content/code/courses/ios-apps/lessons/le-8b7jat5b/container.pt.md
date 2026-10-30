---
title: O contêiner, e onde fica o armazenamento
version: 1
---

**Um `ModelContainer` é o próprio armazenamento: o esquema, o arquivo no disco, e a coordenação de toda
leitura e escrita.** A documentação da Apple para ele diz que um app que usa SwiftData precisa de pelo
menos um, e que sempre que uma busca roda ou um contexto salva, é o contêiner que faz a leitura ou a
escrita de fato. Nada nesta seção foi executado; ela segue essa documentação e a dos modificadores
`modelContainer`, lidas em 30 de outubro de 2026.

## Uma linha no app

A documentação recomenda criá-lo com o modificador do SwiftUI, porque assim todas as janelas do app
compartilham o mesmo contêiner:

```swift
// PlannerApp.swift, with a store
import SwiftUI
import SwiftData

@main
struct PlannerApp: App {
    var body: some Scene {
        WindowGroup {
            CourseListView()
        }
        .modelContainer(for: [CourseRecord.self, SessionRecord.self])
    }
}
```

**Essa linha faz três coisas**, segundo a documentação de `modelContainer(for:)`: cria o contêiner para
esses dois tipos, guarda os dados de forma persistente no disco a não ser que se peça o contrário, e põe
um **contexto de modelo** desse contêiner no ambiente da cena, onde todo `@Query` e todo
`@Environment(\.modelContext)` mais abaixo o encontram. A documentação também observa que o contêiner é
criado uma vez: valores passados ao modificador depois da primeira vez são ignorados.

## O contexto

Um `ModelContext` é onde as mudanças são feitas antes de serem guardadas: `insert`, `delete`, e
atribuições simples às propriedades de um registro. O contexto que o modificador cria é o `mainContext`
do contêiner, que roda no main actor, o mesmo em que as views do SwiftUI rodam, e que salva sozinho, como
explica a seção 07.

```swift
// SessionForm's onAdd, with a store
@Environment(\.modelContext) private var context

func add(_ session: StudySession, to course: CourseRecord) {
    let record = SessionRecord(sessionID: session.id, date: session.date,
                               minutes: session.minutes, done: session.done)
    record.course = course
    context.insert(record)
}
```

A documentação da Apple para `insert(_:)` diz que o registro é registrado no contexto "para que ele possa
incluir o modelo na próxima operação de salvar", e recebe um identificador provisório até lá. O registro
aparece em toda consulta na hora, porque as consultas leem o contexto e não o arquivo.

## Um armazenamento que esquece de propósito

O mesmo modificador aceita `inMemory: true`, e a documentação é exata sobre isso: dados guardados só na
memória, "durante a vida do processo do app". **Esse é o armazenamento para previews e para testes**: um
preview que escrevesse no arquivo de verdade deixaria sessões de exemplo no plano do estudante, e um teste
que o lesse passaria ou falharia conforme o que a última execução deixou. A aula 20 constrói os dois
sobre isso.

Uma `ModelConfiguration` é a forma longa, para o que o modificador não diz: um armazenamento num
contêiner de App Group que um widget também consiga ler, ou um segundo armazenamento separado do
primeiro. O planner não precisa de nenhum dos dois.
