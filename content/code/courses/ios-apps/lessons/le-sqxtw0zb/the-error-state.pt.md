---
title: O estado de erro também é uma tela
version: 1
---

**Uma tela que carrega algo tem pelo menos três estados, e o que a maioria dos apps esquece de
desenhar é o terceiro.** Enquanto o pedido está fora, a tela está carregando. Quando ele volta, a tela
tem os cursos. E quando não volta, a tela tem um erro, e a pessoa que segura o telefone precisa ouvir
algo com que consiga agir. Um app que desenha só os dois primeiros mostra um indicador girando para
sempre, ou uma lista vazia igualzinha a um planner sem nenhum curso.

A correção é fazer dos três estados um tipo só, para que uma tela não consiga guardar "carregando" e
"um erro" ao mesmo tempo, e para que o compilador exija que todo estado seja desenhado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l12-states\" aria-label=\"Três estados de uma tela. Ela começa em loading. De loading vai para loaded, com os cursos, ou para failed, com um APIError. De failed, uma seta com o rótulo tentar de novo volta para loading, e ela só é desenhada quando o erro pode ser tentado de novo.\"><defs><marker id=\"l12-states-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l12-states-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-states-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l12-states-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"60\" y=\"80\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">.loading</text><text x=\"135\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o pedido saiu</text><rect x=\"470\" y=\"20\" width=\"190\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"565\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">.loaded(courses)</text><text x=\"565\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">desenhe a lista</text><rect x=\"470\" y=\"140\" width=\"190\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"565\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">.failed(error)</text><text x=\"565\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">desenhe a mensagem</text><path d=\"M212 98 L466 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-states-ah-phosphor)\"></path><path d=\"M212 122 L466 168\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-states-ah-amber)\"></path><path d=\"M470 192 C 330 228, 200 214, 140 144\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-states-ah-paper-dim)\"></path><text x=\"320\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tentar de novo, se canRetry</text></svg>", "caption": "Um valor, três estados que se excluem. O caminho de volta de um erro só existe onde tentar de novo pode dar outra resposta."}
```

## Três estados, um valor

Salve isto como `Sources/PlannerCore/Loadable.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/Loadable.swift", "parts": [{"code": "// Sources/PlannerCore/Loadable.swift\npublic enum Loadable<Value: Sendable>: Sendable {\n    case loading\n    case loaded(Value)\n    case failed(APIError)\n\n    public static func run(_ work: () async throws(APIError) -> Value) async -> Loadable {\n        do throws(APIError) {\n            return .loaded(try await work())\n        } catch {\n            return .failed(error)\n        }\n    }\n}\n\nextension Loadable: Equatable where Value: Equatable {}\n", "note": "Um enum, porque os três estados se excluem. O `run` faz o trabalho e dobra o resultado num estado: aconteça o que acontecer, volta um `Loadable`, e uma tela tem o que desenhar."}, {"code": "extension APIError {\n    /// The sentence a screen shows.\n    public var message: String {\n        switch self {\n        case .offline: \"You are offline, or the planner's server is not answering.\"\n        case .status(404, _): \"That is not in the planner any more.\"\n        case .status(let code, let detail): \"The server answered \\(code). \\(detail)\"\n        case .unreadable: \"The server's answer could not be read. This is a bug in the app.\"\n        case .cancelled: \"\"\n        }\n    }\n", "note": "Cada erro diz o que aconteceu com palavras que a pessoa consegue usar. Um `404` para um curso quer dizer que ele foi apagado em outro lugar; um `500` é culpa do servidor e diz isso; uma resposta ilegível é culpa nossa, e dizer isso é mais honesto que \"algo deu errado\". As frases ficam em inglês no código; um app traduzido as põe no catálogo de strings dele."}, {"code": "    /// Whether trying again could give a different answer.\n    public var canRetry: Bool {\n        switch self {\n        case .offline: true\n        case .status(let code, _): code >= 500\n        case .unreadable, .cancelled: false\n        }\n    }\n}\n", "note": "Um botão de tentar de novo só onde tentar de novo pode funcionar. Pedir de novo um curso que sumiu dá o mesmo `404`, e pedir de novo uma resposta que o app não consegue ler dá o mesmo bug."}]}
```

O `cancelled` tem uma mensagem vazia de propósito. Um carregamento é cancelado quando a tela que o
começou foi embora, então não há ninguém a quem mostrar nada; a seção 07 trata desse caso.

## Desenhando, num Mac

Este é o `CourseListView` com os três estados desenhados. Ele foi escrito a partir da documentação
da Apple para `ProgressView`, `List` e `ContentUnavailableView`, que o iOS 17 trouxe exatamente para
esta tela, e **não foi executado**:

```swift
// CourseListView.swift
import SwiftUI
import PlannerCore

struct CourseListView: View {
    let api: APIClient
    @State private var state: Loadable<[Course]> = .loading

    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
            case .loaded(let courses):
                List(courses) { course in
                    Text(course.title)
                }
            case .failed(let error):
                ContentUnavailableView {
                    Label("No courses", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error.message)
                } actions: {
                    if error.canRetry {
                        Button("Try again") { Task { await load() } }
                    }
                }
            }
        }
        .task { await load() }
    }

    func load() async {
        state = .loading
        state = await .run { () async throws(APIError) in try await api.courses() }
    }
}
```

**O `switch` é a garantia.** Acrescente um quarto case ao `Loadable` e esta view para de compilar até
desenhá-lo, que é o compilador fazendo o trabalho que de outro jeito seria de uma lista de
conferência.

## Os estados, sem a tela

O que a view desenha é decidido inteiramente pelo `Loadable` que ela guarda, e essa parte roda em
qualquer lugar. Troque o `Sources/fetch/main.swift` por um programa que produz cada estado e imprime o
que a tela diria:

```swift
// Sources/fetch/main.swift
import Foundation
import PlannerCore

let api = APIClient(base: URL(string: "http://127.0.0.1:8012")!)
let broken = APIClient(base: URL(string: "http://127.0.0.1:8012/?fail")!)
let nowhere = APIClient(base: URL(string: "http://127.0.0.1:8099")!)

let attempts: [(String, () async throws(APIError) -> [Course])] = [
    ("working server", { () async throws(APIError) in try await api.courses() }),
    ("failing server", { () async throws(APIError) in try await broken.courses() }),
    ("no server", { () async throws(APIError) in try await nowhere.courses() }),
]
for (name, work) in attempts {
    switch await Loadable.run(work) {
    case .loading:
        print(name, "-> still loading")
    case .loaded(let courses):
        print(name, "-> \(courses.count) courses")
    case .failed(let error):
        print(name, "-> \(error.message) retry: \(error.canRetry)")
    }
}
```

O `?fail` na URL base é o interruptor do servidor da seção 02, levado para todo caminho que o cliente
acrescenta:

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (2.31 secs)
ana@vm:~/planner$ .build/debug/fetch
working server -> 2 courses
failing server -> The server answered 500. The server failed on purpose. retry: true
no server -> You are offline, or the planner's server is not answering. retry: true
```

**O servidor com falha e o servidor ausente são lidos de formas diferentes, e os dois oferecem tentar
de novo**, porque os dois podem se resolver esperando. O `Loadable.run` não lançou nada nos três: o
que quer que tenha voltado, a tela ganhou um estado para desenhar.
