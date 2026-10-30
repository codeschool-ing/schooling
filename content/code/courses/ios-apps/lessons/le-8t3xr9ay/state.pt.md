---
title: '@State: armazenamento que a view possui'
version: 1
---

**Uma view SwiftUI é uma struct, e o SwiftUI a joga fora e faz uma nova toda vez que o `body` do pai
roda.** Então uma view não consegue guardar nada numa propriedade armazenada comum: a próxima cópia
começaria de novo do valor inicial. O `@State` é como uma view pede ao SwiftUI que guarde um valor
para ela **fora da struct**, enquanto a view estiver na tela, e que rode o `body` de novo sempre que
o valor mudar.

Nada nesta seção foi executado para o curso: o SwiftUI não tem versão para Linux, e o código foi
escrito a partir da documentação da Apple para o `State`, lida em 30 de outubro de 2026.

```swift
// CourseDetailView.swift
import SwiftUI
import PlannerCore

struct CourseDetailView: View {
    let course: Course
    @State private var plan: Plan

    init(course: Course, plan: Plan) {
        self.course = course
        _plan = State(initialValue: plan)
    }

    var body: some View {
        let total = plan.weekTotal(today: "2026-10-21")
        List {
            ForEach(plan.sessions.filter { $0.courseID == course.id }) { session in
                Text("\(session.date) · \(session.minutes) min\(session.done ? " · done" : "")")
            }
            Text("\(total.done) of \(total.planned) minutes this week")
        }
        .navigationTitle(course.title)
    }
}
```

Três coisas nele são regras, e não estilo.

**`private`.** A documentação da Apple diz para declarar o estado como privado, porque a view é dona
dele e nada de fora deveria defini-lo. Um pai que quer dar um valor inicial à view o passa ao
inicializador, como acima, e a view decide o que fazer com ele.

**`_plan = State(initialValue: plan)`.** O sublinhado nomeia o próprio property wrapper, e não o
valor dentro dele. Essa linha roda toda vez que o pai faz uma cópia nova da struct, e **o SwiftUI usa
o valor inicial só na primeira vez que a view aparece**. Depois disso, vale o armazenamento que ele
guardou. A seção 07 mostra a armadilha que sai disso.

**Tipos de valor.** O `Plan` é uma struct, então mudar `plan.sessions[0].done` atribui um `plan` novo
do ponto de vista do `@State`, e o SwiftUI vê a mudança. Uma classe guardada em `@State` é outra
história: mudar uma das propriedades dela não muda nada que o `@State` consiga ver. A aula 7 trata de
classes que o SwiftUI consegue observar.

## O que o `body` lê

O `body` lê `plan` duas vezes, para a lista e para o total. Quando `plan` muda, o SwiftUI roda o
`body` de novo e compara a descrição nova com a antiga, e a lista e o total mudam juntos porque os
dois foram calculados a partir do mesmo valor. **Não há linha nenhuma que atualize o total**, e esse é
o desenho: não há nada para esquecer.
