---
title: A hierarquia de views que o planner vai ganhar
version: 1
---

**Dentro de uma cena, tudo na tela é uma árvore de views, e a raiz é a view que a cena recebeu.** No
planner ela é a `CourseListView`. O `body` de cada view diz de quais views ela é feita, essas dizem as
suas, e a árvore termina em views que o próprio SwiftUI desenha: `Text`, `Image`, um `Toggle`. Nada
na tela está fora da árvore, e nada na árvore é desenhado por uma view que não está nela.

A imagem que vale trocar é a de uma tela como uma tela de pintura que você pinta e repinta. **No
SwiftUI você nunca pinta.** Você diz o que a árvore é para os dados que tem, o SwiftUI a desenha, e
quando os dados mudam você diz o que ela é agora. A aula 3 trata de como o SwiftUI transforma duas
dessas descrições nas poucas mudanças de que a tela realmente precisa.

## As quatro telas do planner

O planner tem as mesmas quatro telas em toda plataforma em que esta trilha o constrói, e estes são os
nomes delas neste curso:

| view | o que mostra | construída em |
|---|---|---|
| `CourseListView` | os cursos, cada um com os minutos planejados na semana | aulas 6 e 8 |
| `CourseDetailView` | as sessões de um curso, com um jeito de marcar uma como feita e de acrescentar outra | aulas 8 e 9 |
| `SessionForm` | uma data e um número de minutos para uma sessão nova | aula 10 |
| `WeekView` | o total da semana, planejado contra feito | aula 6 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-tree\" aria-label=\"A árvore de views do planner. PlannerApp no topo, depois WindowGroup, depois CourseListView. Abaixo de CourseListView, CourseDetailView, e abaixo dele SessionForm; WeekView também pende de CourseListView. Os dados descem pela árvore, desenhados como setas para baixo à esquerda; os eventos sobem como mudanças em dados que um pai possui, desenhados como setas para cima à direita.\"><defs><marker id=\"l02-tree-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l02-tree-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-tree-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l02-tree-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"280\" y=\"13\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PlannerApp</text><rect x=\"280\" y=\"68\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WindowGroup</text><rect x=\"280\" y=\"123\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CourseListView</text><rect x=\"180\" y=\"183\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CourseDetailView</text><rect x=\"390\" y=\"183\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WeekView</text><rect x=\"180\" y=\"243\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SessionForm</text><path d=\"M360 47 L360 66\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-tree-ah-wire)\"></path><path d=\"M360 102 L360 121\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-tree-ah-wire)\"></path><path d=\"M360 157 L260 181\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-tree-ah-wire)\"></path><path d=\"M360 157 L470 181\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-tree-ah-wire)\"></path><path d=\"M260 217 L260 241\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-tree-ah-wire)\"></path><path d=\"M70 60 L70 250\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-tree-ah-phosphor)\"></path><text x=\"70\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">os dados descem</text><path d=\"M650 250 L650 60\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-tree-ah-amber)\"></path><text x=\"650\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">os eventos sobem</text></svg>", "caption": "As quatro telas numa árvore. A aula 6 faz da seta para baixo um valor e da seta para cima um Binding."}
```

**Duas coisas viajam pela árvore, em sentidos opostos.** Os dados descem: um pai cria um filho e
entrega o que ele precisa para desenhar, do jeito que a `CourseListView` vai entregar a cada linha o
seu curso. Os eventos sobem: um toque numa linha, um toggle virado, um formulário salvo. No SwiftUI um
evento sobe como uma mudança em dados que o pai possui, por um `Binding`, que é a aula 6, ou por um
modelo observável, que é a aula 7.

## Uma primeira versão, ainda sem nada

Para a aula 3 ter o que desmontar, esta é a menor `CourseListView` que compila contra o pacote. Nada
aqui foi executado; ela foi escrita a partir da documentação da Apple para `View`, `List` e `Text`:

```swift
// CourseListView.swift
import SwiftUI
import PlannerCore

struct CourseListView: View {
    let courses = [
        Course(id: "sql", title: "SQL Databases"),
        Course(id: "mobile", title: "Mobile Fundamentals"),
    ]

    var body: some View {
        List(courses) { course in
            Text(course.title)
        }
    }
}
```

O `List(courses)` aceita o array direto porque `Course` é `Identifiable`, o que a aula 1 deu a ele
por esse motivo. A aula 8 trata de por que essa identidade importa mais do que parece, e do que dá
errado quando uma lista é montada sobre posições.
