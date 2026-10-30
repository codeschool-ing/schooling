---
title: '@Query: uma busca que se mantém atualizada'
version: 1
---

**O `@Query` é uma propriedade cujo valor é o resultado de uma busca, e que o SwiftUI mantém em dia.** A
documentação da Apple para o SwiftData o descreve: o SwiftData faz a busca quando a view aparece, e avisa
o SwiftUI de qualquer mudança posterior nos registros buscados para que a view se atualize. Uma sessão
inserida pelo `SessionForm` aparece na lista atrás dele sem código nenhum para atualizar nada. Nada nesta
seção foi executado; a seção 05 roda as duas partes de uma consulta que não precisam do SwiftData.

## Todos os cursos

```swift
// CourseListView.swift
import SwiftUI
import SwiftData

struct CourseListView: View {
    @Query(sort: \CourseRecord.title) private var courses: [CourseRecord]

    var body: some View {
        NavigationStack {
            List(courses) { course in
                NavigationLink(course.title, value: course.courseID)
            }
            .navigationTitle("Courses")
        }
    }
}
```

`sort: \CourseRecord.title` ordena o resultado por um key path; sem filtro, a consulta devolve todos os
registros do tipo. A lista é construída a partir de `courses` como qualquer array, e as regras de
identidade da aula 8 valem: uma classe `@Model` é `Identifiable` pelo `persistentModelID`, que é estável
durante a vida de um registro guardado.

## As sessões de um curso, da mais recente para a mais antiga

Uma consulta cujo filtro depende de algo que a view recebeu é escrita no inicializador da view, porque os
argumentos de um property wrapper não conseguem ler as outras propriedades da view:

```swift
// CourseDetailView.swift
import SwiftUI
import SwiftData

struct CourseDetailView: View {
    let course: CourseRecord
    @Query private var sessions: [SessionRecord]

    init(course: CourseRecord) {
        self.course = course
        let id = course.courseID
        _sessions = Query(filter: #Predicate<SessionRecord> { $0.course?.courseID == id },
                          sort: \SessionRecord.date, order: .reverse)
    }

    var body: some View {
        List(sessions) { session in
            LabeledContent(session.date, value: "\(session.minutes) min")
        }
        .navigationTitle(course.title)
    }
}
```

**O predicado não é uma closure que o SwiftUI chama em cada registro.** O `#Predicate` é uma macro: ele
transforma a expressão numa descrição que o SwiftData consegue entregar ao armazenamento, para que a
filtragem aconteça onde os dados estão em vez de depois de todos os registros terem sido carregados na
memória. É por isso que `id` é copiado antes para uma constante local, e por isso que um predicado só
aceita o que pode ser descrito desse jeito. A seção 05 mostra o compilador recusando um que não pode.

## Mudando o que uma consulta vê

Uma consulta não tem `refresh()`. Ela vê o contexto, então mudar o contexto basta:

| o estudante | o código | a consulta |
|---|---|---|
| acrescenta uma sessão | `context.insert(record)` | a sessão nova está na lista |
| marca uma como feita | `record.done = true` | a linha a mostra feita |
| apaga uma com um gesto | `context.delete(record)` | a linha sai |

A documentação da Apple para `delete(_:)` acrescenta o caso que vale saber: um registro que foi inserido
e ainda não foi salvo é simplesmente descartado.
