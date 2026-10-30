---
title: O ambiente, para o que uma subárvore inteira precisa
version: 1
---

**O ambiente é um conjunto de valores que uma view entrega a tudo abaixo dela, lido por qualquer
descendente que pedir e ignorado por toda view que não pedir.** O SwiftUI já o usa para as próprias
configurações: o esquema de cores, o tamanho do Dynamic Type de que trata a aula 19, a localidade, e
ações como `dismiss`. Uma view lê um deles com `@Environment` e um key path:

```swift
@Environment(\.colorScheme) private var colorScheme
@Environment(\.dismiss) private var dismiss
```

Desde o iOS 17, um objeto observável pode ser posto no ambiente pelo seu tipo, e é assim que o modelo
do planner chega às telas sem passar pelas views entre elas. Nada nesta seção foi executado; ela foi
escrita a partir da documentação da Apple para `View.environment(_:)` e `Environment`.

```swift
// PlannerApp.swift
@main
struct PlannerApp: App {
    @State private var model = PlannerModel(plan: Plan(), today: "2026-10-21")

    var body: some Scene {
        WindowGroup {
            CourseListView()
                .environment(model)
        }
    }
}
```

```swift
// WeekView.swift
struct WeekView: View {
    @Environment(PlannerModel.self) private var model

    var body: some View {
        @Bindable var model = model
        let week = model.week
        Form {
            TextField("Any day of the week", text: $model.today)
            LabeledContent("Done", value: "\(week.done) of \(week.planned) min")
        }
    }
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" data-fig=\"l07-env\" aria-label=\"O PlannerApp guarda um PlannerModel em @State e o coloca no ambiente na raiz. Abaixo, uma árvore de views: CourseListView e WeekView leem o modelo do ambiente; um NavigationStack e um contêiner simples entre elas não leem nada e não recebem argumento; a CourseDetailView, mais abaixo, também lê o modelo. Só as views que pedem o modelo o tiram do ambiente; as do meio nunca o mencionam.\"><defs><marker id=\"l07-env-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l07-env-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-env-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l07-env-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"230\" y=\"16\" width=\"260\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">PlannerApp</text><text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">@State model  ·  .environment(model)</text><rect x=\"60\" y=\"90\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"180\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">NavigationStack</text><rect x=\"420\" y=\"90\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"540\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">WeekView</text><rect x=\"60\" y=\"170\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CourseListView</text><rect x=\"420\" y=\"170\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"540\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a plain VStack</text><rect x=\"60\" y=\"240\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CourseDetailView</text><path d=\"M300 66 L180 88\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-env-ah-wire)\"></path><path d=\"M420 66 L540 88\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-env-ah-wire)\"></path><path d=\"M180 130 L180 168\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-env-ah-wire)\"></path><path d=\"M540 130 L540 168\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-env-ah-wire)\"></path><path d=\"M180 210 L180 238\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-env-ah-wire)\"></path><rect x=\"330\" y=\"234\" width=\"14\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"352\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">reads @Environment(PlannerModel.self)</text><rect x=\"330\" y=\"262\" width=\"14\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"352\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nunca menciona o modelo</text></svg>", "caption": "O modelo é colocado no ambiente uma vez, na raiz. As views que o pedem o tiram de lá; as views entre elas não recebem argumento e nunca o mencionam.", "same": ["a plain VStack"]}
```

**O `.environment(model)` na raiz põe o modelo ao alcance de toda view abaixo dela**, e o
`@Environment(PlannerModel.self)` o tira de lá onde ele é preciso. A `CourseListView()` não recebe mais
argumento, e nenhuma view entre ela e as que leem o modelo recebe.

**A conveniência tem um preço, e ele é pago em tempo de execução.** Uma view que pede
`PlannerModel.self` quando nenhum ancestral o forneceu não deixa de compilar. A documentação da Apple
para o `Environment` diz que **o SwiftUI lança uma exceção** quando uma view busca um objeto pelo tipo
e o objeto não está no ambiente, e o app para. O jeito mais comum de encontrar isso é um preview feito
sem a linha `.environment(model)`. Onde o objeto pode de fato faltar, a mesma página mostra pedir um
opcional, `@Environment(PlannerModel.self) private var model: PlannerModel?`, e tratar o `nil`. A aula
20 escreve previews que fornecem o modelo.

Duas regras o mantêm honesto:

- **ponha um objeto no ambiente quando muitas views em profundidades diferentes precisam dele**, e o
  modelo do planner é o caso;
- **passe-o como propriedade quando uma filha precisa dele.** Uma propriedade aparece no inicializador,
  o compilador a exige, e quem lê vê de onde vêm os dados.
