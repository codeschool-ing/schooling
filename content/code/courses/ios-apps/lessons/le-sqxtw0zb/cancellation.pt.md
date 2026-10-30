---
title: Cancelar, e esperar menos
version: 1
---

**Um pedido pelo qual alguém parou de esperar deveria parar.** Uma pessoa abre um curso, as sessões
começam a carregar, e ela volta antes de a resposta chegar. Se o pedido continua, ele gasta a rede à
toa, e quando termina escreve o resultado numa tela que já foi embora, ou pior, na que a substituiu. A
concorrência do Swift tem uma palavra para isso, e o `URLSession` a escuta.

## Cancelando uma tarefa

Uma `Task` pode ser cancelada de fora com `cancel()`. Cancelar não para nada à força: liga uma
marca, e espera-se que o código dentro da tarefa a perceba e pare. Os métodos `async` do
`URLSession` percebem. Troque o `Sources/fetch/main.swift`:

```schooling-example
{"language": "swift", "file": "Sources/fetch/main.swift", "parts": [{"code": "// Sources/fetch/main.swift\nimport Foundation\n#if canImport(FoundationNetworking)\nimport FoundationNetworking\n#endif\nimport PlannerCore\n\nlet slow = APIClient(base: URL(string: \"http://127.0.0.1:8012/?delay=3\")!)\n", "note": "`?delay=3` faz o servidor esperar três segundos antes de cada resposta: tempo de sobra para mudar de ideia."}, {"code": "let load = Task { try await slow.courses() }\ntry await Task.sleep(for: .milliseconds(300))\nload.cancel()\ndo {\n    print(\"loaded\", try await load.value)\n} catch {\n    print(\"cancelled task ->\", error)\n}\n", "note": "A tarefa começa o pedido, o programa espera 300 milissegundos e a cancela. O `load.value` espera a tarefa terminar e devolve o resultado dela ou relança o erro. Uma `Task` esquece o throw tipado e guarda só `any Error`, então este `catch` não tem tipo; imprimir o erro ainda mostra qual case ele é."}, {"code": "let config = URLSessionConfiguration.default\nconfig.timeoutIntervalForRequest = 1\nlet impatient = APIClient(base: slow.base, session: URLSession(configuration: config))\ndo throws(APIError) {\n    print(\"loaded\", try await impatient.courses())\n} catch {\n    print(\"one second ->\", error)\n}\n", "note": "O outro jeito de parar de esperar: um timeout. `timeoutIntervalForRequest` é quanto a sessão espera por dados antes de desistir, sessenta segundos se você não mudar. Uma sessão feita com uma configuração própria é como um cliente ganha outra."}]}
```

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (1.12 secs)
ana@vm:~/planner$ .build/debug/fetch
cancelled task -> cancelled
one second -> offline("timedOut")
```

**Os dois pedidos pararam, e pararam como dois erros diferentes.** O cancelado é `cancelled`, que uma
tela desenha como nada, porque quem pediu foi embora. O que estourou o tempo é `offline("timedOut")`,
que uma tela desenha como uma mensagem com botão de tentar de novo, porque a pessoa ainda está ali e
ainda esperando. Foi o primeiro estágio do cliente na seção 05 que transformou o código `cancelled`
do `URLError` num case próprio, para que esses dois nunca se pareçam.

**Nenhum dos dois parou o servidor.** O log no fim da seção 02 mostra o outro lado: os dois pedidos
lentos foram respondidos três segundos depois, e nas duas vezes o servidor descobriu que o cliente
tinha ido embora. Cancelar poupa a bateria do telefone, os dados dele e a tela de uma resposta velha.
Não desfaz um pedido que já chegou ao servidor, o que importa no dia em que o pedido é um `POST`: é na
aula 14 que uma escrita que pode ou não ter acontecido é tratada.

## No SwiftUI, o cancelamento é feito por você

O modificador `task` da seção 03 começa o trabalho quando a view aparece e **o cancela quando a view
some**. É todo o motivo para preferi-lo a começar uma `Task` no `onAppear`, que ninguém cancela. A
outra forma dele, `task(id:)`, cancela e começa de novo sempre que o valor muda, o que serve a uma tela
cujo conteúdo depende de uma seleção. Esta listagem segue a documentação da Apple para
`task(id:priority:_:)` e **não foi executada**:

```swift
// CourseDetailView.swift
import SwiftUI
import PlannerCore

struct CourseDetailView: View {
    let api: APIClient
    let courseID: String
    @State private var state: Loadable<[StudySession]> = .loading

    var body: some View {
        List {
            if case .loaded(let sessions) = state {
                ForEach(sessions) { s in
                    Text("\(s.date)  \(s.minutes) min")
                }
            }
        }
        .task(id: courseID) {
            state = .loading
            let loaded = await Loadable.run { () async throws(APIError) in
                try await api.sessions(course: courseID)
            }
            if case .failed(.cancelled) = loaded { return }
            state = loaded
        }
    }
}
```

A última conferência é a regra da seção 06 posta em prática: **um carregamento cancelado não escreve
nada.** Quando o `courseID` muda, o carregamento antigo é cancelado e o novo começa, e o antigo não
pode pousar as sessões dele em cima das do curso novo.
