---
title: Uma pilha de telas, e o botão de voltar que vem com ela
version: 1
---

**Num telefone, abrir alguma coisa empilha uma tela em cima daquela em que você estava, e voltar a
desempilha.** A lista de cursos, depois um curso, depois uma sessão: três telas numa pilha, com o botão
de voltar e o deslizar a partir da borda esquerda para desfazer o último empilhamento. O
`NavigationStack` é a view do SwiftUI que é dona dessa pilha. Nada nesta seção foi executado para o
curso; ela foi escrita a partir da documentação da Apple para `NavigationStack` e `NavigationLink`,
lida em 30 de outubro de 2026.

```swift
// CourseListView.swift
struct CourseListView: View {
    @Environment(PlannerModel.self) private var model

    var body: some View {
        NavigationStack {
            List(model.plan.courses) { course in
                NavigationLink(course.title) {
                    CourseDetailView(course: course)
                }
            }
            .navigationTitle("Courses")
        }
    }
}
```

**O `NavigationStack` vai uma vez, na raiz do que navega**, e não em toda tela. Cada tela empilhada
nele ganha a barra de navegação, um título vindo do próprio `.navigationTitle`, e um botão de voltar
com o título da tela anterior. Os exemplos da Apple põem uma pilha na raiz; outra dentro de uma tela
empilhada é uma segunda pilha, com um path só dela, e nada no planner quer isso.

O link acima carrega a própria view de destino: `NavigationLink(course.title) {
CourseDetailView(…) }`. Essa forma é a mais simples e tem dois limites. A pilha só sabe que *alguma
view* foi empilhada, então não há nada para salvar quando o app fecha e nada que um link de fora do
app possa pedir. E o SwiftUI pode construir o destino antes de alguém tocar. A seção 03 a troca por
links que carregam um valor, que é a base do resto da aula.

O antigo `NavigationView`, que você vai encontrar em código escrito antes do iOS 16, está obsoleto. O
guia da Apple *Migrating to new navigation types* o mapeia nas duas views que o substituíram,
`NavigationStack` para uma pilha e `NavigationSplitView` para as colunas de um iPad.
