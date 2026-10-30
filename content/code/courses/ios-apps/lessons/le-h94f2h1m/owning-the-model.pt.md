---
title: Quem cria o modelo, e quem só o lê
version: 1
---

**Um objeto observável precisa de um dono exatamente como um valor em `@State`, e o dono é a view que o
cria.** Ela o guarda em `@State`; toda outra view recebe uma referência simples e lê dela. Nada nesta
seção foi executado para o curso; ela foi escrita a partir do artigo da Apple *Managing model data in
your app* e da documentação para `Observable` e `State`, como estavam em 30 de outubro de 2026.

```swift
// PlannerApp.swift
import SwiftUI
import PlannerCore

@main
struct PlannerApp: App {
    @State private var model = PlannerModel(plan: Plan(), today: "2026-10-21")

    var body: some Scene {
        WindowGroup {
            CourseListView(model: model)
        }
    }
}
```

**O `@State` aqui não observa o objeto; ele o mantém vivo.** A aula 2 mostrou que o `App` é uma struct
como uma view, refeita quando o SwiftUI quer. Sem o `@State`, cada cópia nova do `PlannerApp` criaria
um `PlannerModel` novo e o plano se perderia. Com ele, o SwiftUI guarda a primeira instância pela vida
da cena. Observar é trabalho do Observation, e acontece em qualquer `body` que leia uma propriedade.

As views que recebem o modelo o recebem como uma propriedade comum:

```swift
// CourseListView.swift
import SwiftUI
import PlannerCore

struct CourseListView: View {
    let model: PlannerModel

    var body: some View {
        NavigationStack {
            List(model.plan.courses) { course in
                NavigationLink(course.title) {
                    CourseDetailView(model: model, course: course)
                }
            }
            .navigationTitle("Courses")
        }
    }
}
```

**`let`, sem wrapper nenhum.** O modelo é uma classe, então toda view guarda uma referência para a
mesma instância, e ler `model.plan.courses` dentro do `body` é o que inscreve esta view, como a seção
03 mediu. A tela de detalhe recebe a mesma referência e as escritas dela, `model.markDone(…)`, chegam
ao único plano; a lista é redesenhada porque leu `plan`.

O custo de passá-lo assim é o que motivou a aula: uma view no meio da árvore que não precisa de nada
ainda tem de receber `model` para repassá-lo. A seção 06 tira isso.
