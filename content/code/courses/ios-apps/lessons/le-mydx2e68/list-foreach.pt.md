---
title: List e ForEach, e para que serve cada um
version: 1
---

**O `List` desenha uma coluna de linhas que rola, no estilo da própria plataforma; o `ForEach` faz
views a partir de uma coleção.** Os dois costumam ser escritos juntos e são coisas diferentes. O
`List` é um contêiner com opiniões: separadores, margens, ações de deslizar, seleção, um modo de
edição. O `ForEach` não tem aparência nenhuma: ele transforma cada elemento de uma coleção numa view,
dentro do contêiner em que estiver, um `List`, um `VStack` ou um `Form`.

Nada nesta seção foi executado para o curso; ela foi escrita a partir da documentação da Apple para
`List` e `ForEach`, lida em 30 de outubro de 2026. A lista de cursos do planner é o caso mais simples:

```swift
// in CourseListView's body
List(model.plan.courses) { course in
    NavigationLink(course.title) {
        CourseDetailView(course: course)
    }
}
```

O `List(_:rowContent:)` é um atalho para um `List` em volta de um `ForEach`. A forma longa é a que você
escreve quando a lista tem mais de um tipo de linha:

```swift
List {
    ForEach(model.plan.courses) { course in
        NavigationLink(course.title) { CourseDetailView(course: course) }
    }
    NavigationLink("This week") { WeekView() }
}
```

**O `ForEach` não é um laço.** Um laço `for` roda o corpo uma vez por elemento e acabou. O `ForEach` é
uma view: ele descreve, para o SwiftUI, uma linha por elemento, e o SwiftUI decide quando construir
cada linha e quando construí-la de novo. É por isso que ele precisa saber, para cada elemento, **que
linha ele é** — a pergunta das seções 03 e 04, e aquela cuja resposta decide se uma lista anima,
guarda o seu estado e continua rápida.

Os dois inicializadores acima recebem `model.plan.courses` e mais nada porque o `Course` adota o
`Identifiable`, o protocolo que responde essa pergunta. A aula 1 o declarou pensando nesta aula.
