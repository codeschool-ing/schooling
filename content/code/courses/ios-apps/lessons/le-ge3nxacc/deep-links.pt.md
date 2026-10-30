---
title: Deep links, interpretados e testados
version: 1
---

**Um deep link é uma URL que abre o app numa tela específica**, e com o path como um array de rotas,
tratar um é transformar uma URL num array. `planner://course/sql/session/s3` pede o curso de SQL com a
sessão `s3` no topo. Um app declara o esquema `planner` nos *URL Types* do target, e o SwiftUI entrega
cada URL a uma closure `onOpenURL`. Nenhum dos dois foi executado; foram escritos a partir da
documentação da Apple para `onOpenURL(perform:)` e *Defining a custom URL scheme for your app*.

```swift
// in CourseListView's body, on the NavigationStack
.onOpenURL { url in
    guard let asked = Route.path(from: url) else { return }
    model.path = Route.stillValid(asked, in: model.plan)
}
```

**Um link vem de fora do app, então é entrada, e entrada é conferida.** Qualquer um pode digitar uma URL
com o seu esquema num navegador ou pô-la numa mensagem, e o `stillValid` da seção 05 é a segunda
conferência. A primeira é o interpretador, que recusa tudo o que não for exatamente uma sequência de
tipo e valor. Salve-o como `Sources/PlannerCore/RouteLinks.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/RouteLinks.swift", "parts": [{"code": "// Sources/PlannerCore/RouteLinks.swift\nimport Foundation\n\nextension Route {\n    /// The path a link such as planner://course/sql/session/s3 asks for, or nil.\n    public static func path(from url: URL) -> [Route]? {\n        guard url.scheme == \"planner\", let host = url.host() else { return nil }\n        var words = [host] + url.pathComponents.filter { $0 != \"/\" }\n", "note": "Em `planner://course/sql/session/s3` o host é `course` e o path é `/sql/session/s3`. Juntá-los dá as palavras `course`, `sql`, `session`, `s3`. Qualquer outro esquema é recusado antes de qualquer outra coisa ser lida."}, {"code": "        var path: [Route] = []\n        while words.count >= 2 {\n            let kind = words.removeFirst(), value = words.removeFirst()\n            switch kind {\n            case \"course\": path.append(.course(id: value))\n            case \"session\": path.append(.session(id: value))\n            case \"week\": path.append(.week(day: value))\n            default: return nil\n            }\n        }\n        return words.isEmpty && !path.isEmpty ? path : nil\n    }\n}\n", "note": "As palavras são lidas em pares. Um tipo que o planner não tem recusa o link inteiro, e uma palavra que sobra no fim também, que é um link cortado no meio. Recusar é `nil`, e o `guard` de quem chama deixa o app onde estava."}]}
```

Os testes dizem o que o interpretador aceita e o que recusa. Salve-os como
`Tests/PlannerCoreTests/RouteLinkTests.swift`:

```swift
// Tests/PlannerCoreTests/RouteLinkTests.swift
import Foundation
import Testing
@testable import PlannerCore

@Test func aSessionLinkOpensItsCourseFirst() {
    let url = URL(string: "planner://course/sql/session/s3")!
    #expect(Route.path(from: url) == [.course(id: "sql"), .session(id: "s3")])
}

@Test func aWeekLinkOpensTheWeek() {
    let url = URL(string: "planner://week/2026-10-19")!
    #expect(Route.path(from: url) == [.week(day: "2026-10-19")])
}

@Test(arguments: [
    "planner://course/sql/session",
    "planner://teacher/ana",
    "https://example.com/course/sql",
])
func aLinkThatIsNotARouteIsRefused(link: String) {
    #expect(Route.path(from: URL(string: link)!) == nil)
}
```

```
ana@vm:~/navigate$ swift test --filter Link
Building for debugging...
[Constructing description]
[Planning deferred tasks]
Build complete! (0.69 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Test aLinkThatIsNotARouteIsRefused(link:) started.
◇ Test aSessionLinkOpensItsCourseFirst() started.
◇ Test aWeekLinkOpensTheWeek() started.
◇ Test case passing 1 argument link → "planner://course/sql/session" to aLinkThatIsNotARouteIsRefused(link:) started.
◇ Test case passing 1 argument link → "planner://teacher/ana" to aLinkThatIsNotARouteIsRefused(link:) started.
◇ Test case passing 1 argument link → "https://example.com/course/sql" to aLinkThatIsNotARouteIsRefused(link:) started.
✔ Test aSessionLinkOpensItsCourseFirst() passed after 0.001 seconds.
✔ Test aWeekLinkOpensTheWeek() passed after 0.001 seconds.
✔ Test aLinkThatIsNotARouteIsRefused(link:) with 3 test cases passed after 0.001 seconds.
✔ Test run with 3 tests in 0 suites passed after 0.001 seconds.
```

**O `@Test(arguments:)` roda um teste uma vez por argumento**, e o relatório nomeia cada execução pelo
seu argumento. Os três links recusados são um link cortado no meio, um tipo para o qual o planner não
tem tela, e um endereço da web que só se parece com o link. A aula 20 trata de testes parametrizados em
geral.

Um link com o esquema `https` que abre o app em vez do Safari é um **universal link**, e ele precisa
que o site publique um arquivo citando o app, como descreve a documentação da Apple sobre domínios
associados. Ele não foi configurado para este curso: precisa de um domínio e de um app assinado, aula
21.
