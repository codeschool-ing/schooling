---
title: Links que carregam um valor, e um lugar que decide a tela
version: 1
---

**Um link pode empilhar um valor em vez de uma view, e a pilha procura qual view mostrar para aquele
valor.** O link diz *mostre o curso `sql`*; um modificador `navigationDestination` diz *um id de curso
é mostrado pela `CourseDetailView`*. As duas metades se encontram pelo tipo do valor. Nada aqui foi
executado; foi escrito a partir da documentação da Apple para `NavigationLink(_:value:)` e
`navigationDestination(for:destination:)`.

Os valores são as rotas do planner. O pacote desta aula acrescenta o tipo, e a seção 04 o constrói e o
testa em qualquer computador:

```swift
public enum Route: Hashable, Codable, Sendable {
    case course(id: String)
    case session(id: String)
    case week(day: String)
}
```

```swift
// CourseListView.swift
NavigationStack {
    List(model.plan.courses) { course in
        NavigationLink(course.title, value: Route.course(id: course.id))
    }
    .navigationTitle("Courses")
    .navigationDestination(for: Route.self) { route in
        switch route {
        case .course(let id): CourseDetailView(courseID: id)
        case .session(let id): SessionDetailView(sessionID: id)
        case .week(let day): WeekView(day: day)
        }
    }
}
```

**Uma rota carrega ids, nunca o curso ou a sessão em si.** A tela de detalhe procura o curso no modelo
quando é mostrada, então sempre mostra o curso como ele está agora; uma rota que carregasse uma cópia
do `Course` mostraria o que existia quando o link foi tocado. É a regra da aula 6 sobre uma fonte da
verdade, aplicada à navegação, e é o que torna a seção 05 possível: um id pode ser salvo e lido de
volta, uma cópia dos dados envelhece no disco.

**Por que `Hashable`:** o `NavigationStack` guarda os seus valores numa coleção e os compara, então o
tipo do valor tem de ser `Hashable`. O `Codable` é para a seção 05.

Ponha o `navigationDestination` dentro da pilha, numa view que está sempre lá, como a lista raiz. A
documentação da Apple adverte contra pô-lo dentro de um contêiner preguiçoso, como as linhas de um
`List`, onde ele pode não estar carregado quando a pilha precisar.
