---
title: Códigos de status, e um cliente para todo pedido
version: 1
---

**O `URLSession` só lança quando não há resposta. Um `404` ou um `500` é uma resposta, e chega como
sucesso.** A seção 03 mostrou isso: a chamada devolveu uma resposta e um corpo, e se esse corpo é a
lista de cursos ou `{"error": "no course art"}` é o código que o lê quem tem de descobrir. Um código
que pula a conferência decodifica uma mensagem de erro como dado, e a falha aparece três funções
depois como um `DecodingError` sobre uma chave que nunca ia estar ali.

Então o planner ganha um lugar só que envia um pedido e transforma cada resultado num de quatro
erros, ou num valor. Toda aula seguinte o chama.

## O cliente

Salve isto como `Sources/PlannerCore/APIClient.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/APIClient.swift", "parts": [{"code": "// Sources/PlannerCore/APIClient.swift\nimport Foundation\n#if canImport(FoundationNetworking)\nimport FoundationNetworking\n#endif\n\npublic enum APIError: Error, Equatable, Sendable {\n    case offline(String)      // no answer: no network, no server, a timeout\n    case status(Int, String)  // an answer, and it was an error\n    case unreadable(String)   // a success whose body is not what was expected\n    case cancelled            // the caller stopped waiting\n}\n", "note": "Quatro resultados, e uma tela trata cada um de um jeito: offline vale uma nova tentativa, um status vale ser mostrado, ilegível é um bug a relatar, e cancelado não vale nada, porque ninguém está esperando por ele."}, {"code": "public struct APIClient: Sendable {\n    public let base: URL\n    let session: URLSession\n\n    public init(base: URL, session: URLSession = .shared) {\n        self.base = base\n        self.session = session\n    }\n", "note": "A URL base é dada em vez de escrita aqui dentro, então o mesmo cliente fala com `127.0.0.1` neste curso e com um endereço de verdade em produção, e um teste consegue entregar a ele uma sessão própria."}, {"code": "    public func courses() async throws(APIError) -> [Course] {\n        let wire: [WireCourse] = try await send(URLRequest(url: base.appending(path: \"courses\")))\n        return wire.map(\\.course)\n    }\n\n    public func sessions(course id: String) async throws(APIError) -> [StudySession] {\n        let url = base.appending(path: \"courses\").appending(path: id).appending(path: \"sessions\")\n        let wire: [WireSession] = try await send(URLRequest(url: url))\n        return wire.map(\\.session)\n    }\n\n    public func add(_ s: StudySession) async throws(APIError) -> StudySession {\n        var request = URLRequest(url: base.appending(path: \"sessions\"))\n        request.httpMethod = \"POST\"\n        request.setValue(\"application/json\", forHTTPHeaderField: \"Content-Type\")\n        request.httpBody = try? JSONEncoder().encode(WireSession(s))\n        let wire: WireSession = try await send(request)\n        return wire.session\n    }\n", "note": "Os três pedidos que o planner faz. Cada um diz o que envia e que tipo volta, e deixa todo o resto para o `send`. O `appending(path:)` escapa o que recebe, então um id de curso com um espaço não consegue mudar o caminho."}, {"code": "    func send<T: Decodable>(_ request: URLRequest) async throws(APIError) -> T {\n        let data: Data, response: URLResponse\n        do {\n            (data, response) = try await session.data(for: request)\n        } catch let error as URLError where error.code == .cancelled {\n            throw .cancelled\n        } catch is CancellationError {\n            throw .cancelled\n        } catch let error as URLError {\n            throw .offline(\"\\(error.code)\")\n        } catch {\n            throw .offline(\"\\(error)\")\n        }\n", "note": "O primeiro estágio: houve resposta? O cancelamento chega em duas formas, um `URLError` com código `cancelled` quando um pedido em andamento é parado, e um `CancellationError` quando a tarefa foi cancelada antes de chegar até ali. Para uma tela as duas querem dizer a mesma coisa."}, {"code": "        guard let http = response as? HTTPURLResponse else { throw .offline(\"not HTTP\") }\n        guard (200..<300).contains(http.statusCode) else {\n            let message = (try? JSONDecoder().decode([String: String].self, from: data))?[\"error\"]\n            throw .status(http.statusCode, message ?? \"\")\n        }\n", "note": "O segundo estágio: houve resposta, mas foi um sucesso? Qualquer coisa fora de 200 a 299 é erro, e o servidor do planner põe em `error` uma frase que vale guardar. Um servidor que não manda esse corpo deixa a mensagem vazia em vez de falhar uma segunda vez."}, {"code": "        do {\n            return try JSONDecoder().decode(T.self, from: data)\n        } catch {\n            throw .unreadable(\"\\(error)\")\n        }\n    }\n}\n", "note": "O terceiro estágio: um sucesso, no formato que o tipo espera? Só agora o corpo é decodificado, então um `DecodingError` aqui é de fato uma diferença entre dois programas, e nunca uma página de erro lida como dado."}]}
```

**Três estágios, nessa ordem, e cada um só roda se o anterior passou.** Essa ordem é o projeto
inteiro. Decodifique primeiro e uma página de erro vira um erro de decodificação; confira o status
depois de decodificar e um `500` de corpo vazio vira a mesma coisa; pule o primeiro estágio e um
telefone sem sinal mostra "resposta ilegível".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l12-stages\" aria-label=\"Um pedido passa por três conferências da esquerda para a direita. Primeira: houve resposta? Se não, o erro é offline, ou cancelled se quem chamou parou de esperar. Segunda: o status está entre 200 e 299? Se não, o erro é status com o código e a mensagem do servidor. Terceira: o corpo decodifica como o tipo esperado? Se não, o erro é unreadable. Só um pedido que passa pelas três vira um valor.\"><defs><marker id=\"l12-stages-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l12-stages-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-stages-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l12-stages-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"40\" width=\"96\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"64\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">pedido</text><rect x=\"150\" y=\"40\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"210\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">houve resposta?</text><text x=\"210\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">estágio 1</text><path d=\"M112 65 L148 65\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-stages-ah-wire)\"></path><path d=\"M210 92 L210 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-stages-ah-amber)\"></path><text x=\"224\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">não</text><rect x=\"138\" y=\"160\" width=\"144\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"210\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">.offline / .cancelled</text><rect x=\"300\" y=\"40\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">200 a 299?</text><text x=\"360\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">estágio 2</text><path d=\"M270 65 L298 65\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-stages-ah-wire)\"></path><path d=\"M360 92 L360 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-stages-ah-amber)\"></path><text x=\"374\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">não</text><rect x=\"288\" y=\"160\" width=\"144\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">.status(code, msg)</text><rect x=\"450\" y=\"40\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"510\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">decodifica como T?</text><text x=\"510\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">estágio 3</text><path d=\"M420 65 L448 65\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-stages-ah-wire)\"></path><path d=\"M510 92 L510 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-stages-ah-amber)\"></path><text x=\"524\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">não</text><rect x=\"438\" y=\"160\" width=\"144\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"510\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">.unreadable</text><path d=\"M570 65 L608 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-stages-ah-phosphor)\"></path><rect x=\"610\" y=\"40\" width=\"94\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"657\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">um valor</text><text x=\"657\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">do tipo T</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">todo resultado sai como exatamente um destes</text></svg>", "caption": "A ordem é o projeto: resposta antes de status, status antes de decodificação. Um pedido só chega ao valor da direita passando pelas três."}
```

## Cada resultado, uma vez

Troque o `Sources/fetch/main.swift` por um programa que pede uma coisa de cada tipo:

```swift
// Sources/fetch/main.swift
import Foundation
import PlannerCore

let api = APIClient(base: URL(string: "http://127.0.0.1:8012")!)
let nowhere = APIClient(base: URL(string: "http://127.0.0.1:8099")!)

do {
    for c in try await api.courses() { print("course", c.id, c.title) }
    print("sql", try await api.sessions(course: "sql").map(\.id))
    print("posted", try await api.add(StudySession(id: "s5", courseID: "mobile", date: "2026-10-22", minutes: 30)).id)
} catch {
    print("unexpected:", error)
}

let failures: [(String, () async throws(APIError) -> Void)] = [
    ("no such course", { () async throws(APIError) in
        _ = try await api.sessions(course: "art")
    }),
    ("post for no course", { () async throws(APIError) in
        _ = try await api.add(StudySession(id: "s6", courseID: "art", date: "2026-10-22", minutes: 30))
    }),
    ("no server", { () async throws(APIError) in
        _ = try await nowhere.courses()
    }),
]
for (name, attempt) in failures {
    do throws(APIError) {
        try await attempt()
    } catch {
        print(name, "->", error)
    }
}
```

`8099` é uma porta em que nada escuta, que é como "o servidor caiu" parece do lado do cliente. **Uma
closure diz o seu tipo de erro em voz alta**, `() async throws(APIError) in`, porque o compilador
infere `any Error` para uma closure que não diz, e aí se recusa a pô-la numa lista de closures que
lançam `APIError`. O `do throws(APIError)` faz o mesmo para o `catch`, então ali o `error` tem esse
tipo e não `any Error`.

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (1.77 secs)
ana@vm:~/planner$ .build/debug/fetch
course sql SQL Databases
course mobile Mobile Fundamentals
sql ["s1", "s3"]
posted s5
no such course -> status(404, "no course art")
post for no course -> status(422, "no course art")
no server -> offline("cannotConnectToHost")
```

As três primeiras linhas são os sucessos, e o envio voltou com o id que recebeu. Depois, **duas
respostas que eram erros, e uma que não foi resposta nenhuma.** A frase do próprio servidor viajou
até o case `status`. `cannotConnectToHost` é o código de `URLError` para uma conexão recusada, e um
telefone num túnel imprimiria `notConnectedToInternet` ou `timedOut`, os três pegos pelo mesmo case
`offline`.

O terminal do servidor registrou os mesmos três pedidos do lado dele, `404`, `422` e nada para o
terceiro, que nunca chegou até ele.
