---
title: O path é um array que é seu
version: 1
---

**Dê ao `NavigationStack` um binding para um array de valores, e o array é a pilha.** Cada valor nele é
uma tela empilhada; o primeiro é a tela acima da raiz, o último é a do topo. Um link tocado pela pessoa
acrescenta a ele, o botão de voltar remove o último elemento, e o código pode fazer qualquer dos dois
mudando o array. Nada do que o SwiftUI faz aqui foi executado para o curso; o array em si é Swift puro
e é construído abaixo.

```swift
// in PlannerModel, from this lesson on
public var path: [Route] = []
```

```swift
// CourseListView.swift
struct CourseListView: View {
    @Environment(PlannerModel.self) private var model

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.path) {
            List(model.plan.courses) { course in
                NavigationLink(course.title, value: Route.course(id: course.id))
            }
            .navigationDestination(for: Route.self) { route in
                RouteView(route: route)
            }
        }
    }
}
```

**Navegar em código é mudar um array**, e toda operação de que uma tela precisa é uma linha dele:

| a pessoa ou o app… | o path |
|---|---|
| toca no curso de SQL | `[.course(id: "sql")]` |
| depois toca na sessão `s3` | `[.course(id: "sql"), .session(id: "s3")]` |
| toca em voltar | `path.removeLast()` → `[.course(id: "sql")]` |
| salva uma sessão nova e volta à lista | `path.removeAll()` → `[]` |
| abre um link para a sessão `s3` | `path = [.course(id: "sql"), .session(id: "s3")]` |

A última linha é o motivo de guardar o path no modelo em vez de deixar o SwiftUI guardá-lo. Uma
notificação tocada pela pessoa, aula 17, ou um link vindo de outro app, seção 06, tem de pôr o app numa
tela específica, e com o path na mão isso é uma atribuição. A documentação da Apple para o
`NavigationStack` oferece também o `NavigationPath`, um path com tipo apagado para pilhas que empilham
valores de vários tipos; o planner empilha um tipo só, `Route`, então um array simples diz mais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-path\" aria-label=\"À esquerda, uma pilha de três telas desenhadas como cartões sobrepostos: a raiz, CourseListView, que não está no path; acima dela o curso de SQL; no topo, a sessão s3. À direita, o array do path, model.path, com dois elementos, .course(id: &quot;sql&quot;) no índice 0 e .session(id: &quot;s3&quot;) no índice 1, cada um ligado por uma linha à tela que empilha. Embaixo, as operações: um toque acrescenta, voltar remove o último elemento, e um deep link atribui o array inteiro.\"><defs><marker id=\"l09-path-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l09-path-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-path-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l09-path-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"150\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"165\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CourseListView</text><text x=\"165\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a raiz, fora do path</text><rect x=\"70\" y=\"100\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"195\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CourseDetailView</text><text x=\"195\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">curso sql</text><rect x=\"100\" y=\"50\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"225\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SessionDetailView</text><text x=\"225\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sessão s3, no topo</text><text x=\"560\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">model.path</text><rect x=\"440\" y=\"50\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"452\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"570\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.session(id: \"s3\")</text><rect x=\"440\" y=\"100\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"452\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"570\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.course(id: \"sql\")</text><path d=\"M440 70 L354 72\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-path-ah-amber)\"></path><path d=\"M440 120 L324 122\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-path-ah-amber)\"></path><text x=\"440\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tocar num link</text><text x=\"540\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">path.append(…)</text><text x=\"440\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">voltar</text><text x=\"540\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">path.removeLast()</text><text x=\"440\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">deep link</text><text x=\"540\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">path = […]</text></svg>", "caption": "O path guarda um valor por tela empilhada, sem contar a raiz. Navegar é mudar o array: acrescentar para empilhar, remover o último para voltar, atribuir para pular.", "same": ["deep link"]}
```

## O tipo da rota

Copie o pacote da aula 1 para esta aula, `cp -r ~/planner ~/navigate`, e acrescente o tipo que a aula
inteira usa. Salve isto como `Sources/PlannerCore/Route.swift`:

```swift
// Sources/PlannerCore/Route.swift
import Foundation

/// One screen the planner can push, named by the id of what it shows.
public enum Route: Hashable, Codable, Sendable {
    case course(id: String)
    case session(id: String)
    case week(day: String)
}
```

**Os valores associados têm rótulo, `id:` e `day:`,** e isso é para a seção 05, onde os rótulos viram
as chaves do JSON salvo. `Hashable` e `Codable` são sintetizados pelo compilador porque todo valor
associado é uma `String`, que é as duas coisas. Compile:

```
ana@vm:~/navigate$ swift build
Building for debugging...
[Pre-planning 1 / 95]
[4 / 8] PlannerCore
[6 / 10] PlannerCore
[13 / 14] PlannerCore
[18 / 21] week-product
[22 / 22] week-product
Build complete! (1.07 secs)
```
