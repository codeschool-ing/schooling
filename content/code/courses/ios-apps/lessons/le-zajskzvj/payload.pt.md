---
title: O payload, e o limite que o APNs impõe
version: 1
---

**Uma notificação remota é um pequeno documento JSON, e o APNs recusa um que seja grande demais.** A
documentação da Apple sobre gerar uma notificação remota dá as duas metades: as chaves que a Apple
define, dentro de um dicionário chamado `aps`, e o limite, "para todas as outras notificações remotas, o
tamanho máximo do payload é 4 KB (4096 bytes)", com 5 KB para chamadas de voz pela internet. Montar esse
documento e medi-lo é Swift puro, então esta seção roda no Linux. Enviá-lo ao APNs precisa dos servidores
da Apple, de uma chave de uma conta de desenvolvedor paga e de um aparelho de verdade, e não foi feito
para o curso.

O planner envia um quando uma sessão é acrescentada em outro aparelho do estudante, para que este
telefone avise. Acrescente um programa ao pacote da seção 04: troque o `Package.swift` por este, que
acrescenta o `push`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Planner",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PlannerCore", targets: ["PlannerCore"]),
    ],
    targets: [
        .target(name: "PlannerCore"),
        .executableTarget(name: "week", dependencies: ["PlannerCore"]),
        .executableTarget(name: "remind", dependencies: ["PlannerCore"]),
        .executableTarget(name: "push", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

Salve isto como `Sources/PlannerCore/Push.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/Push.swift", "parts": [{"code": "// Sources/PlannerCore/Push.swift\nimport Foundation\n\n/// What the planner's server sends through APNs when a session is added on another device.\npublic struct PushPayload: Codable, Equatable, Sendable {\n    public struct Alert: Codable, Equatable, Sendable {\n        public var title: String\n        public var body: String\n    }\n\n", "note": "O alerta é o que a pessoa lê: um título e um corpo. A documentação da Apple sobre gerar uma notificação remota cita `title` e `body` como chaves de `alert`."}, {"code": "    public struct APS: Codable, Equatable, Sendable {\n        public var alert: Alert\n        public var sound: String?\n        public var threadID: String?\n\n        enum CodingKeys: String, CodingKey {\n            case alert, sound\n            case threadID = \"thread-id\"\n        }\n    }\n\n", "note": "Tudo o que a Apple define vai dentro de um dicionário chamado `aps`. O `thread-id` agrupa notificações na tela de bloqueio, aqui por curso. O Swift o chama de `threadID` e o `CodingKeys` o escreve como o APNs escreve, o mesmo movimento que a aula 12 faz com `courseId`."}, {"code": "    public var aps: APS\n    public var sessionID: String\n\n    enum CodingKeys: String, CodingKey {\n        case aps\n        case sessionID = \"session-id\"\n    }\n\n    public init(title: String, body: String, sessionID: String, courseID: String) {\n        aps = APS(alert: Alert(title: title, body: body), sound: \"default\", threadID: courseID)\n        self.sessionID = sessionID\n    }\n}\n\n", "note": "`session-id` é a chave própria do planner, fora do `aps`, onde a documentação diz que chaves personalizadas ficam. Ela diz ao app qual sessão abrir quando a notificação é tocada; o init preenche o resto."}, {"code": "/// APNs refuses a payload over this many bytes (Apple's documentation, for all but VoIP).\npublic let maximumPushBytes = 4096\n\npublic func encoded(_ payload: PushPayload) throws -> Data {\n    let encoder = JSONEncoder()\n    encoder.outputFormatting = [.sortedKeys]\n    return try encoder.encode(payload)\n}\n", "note": "O limite é um número publicado, e conferi-lo é uma comparação. O `sortedKeys` faz a saída ser a mesma a cada execução, o que permite comparar uma captura byte a byte."}]}
```

E isto como `Sources/push/main.swift`. Ele codifica um payload, o mede, o decodifica de volta como o app
faria, e então tenta um corpo que levasse a nota inteira da sessão:

```swift
// Sources/push/main.swift
import Foundation
import PlannerCore

let added = PushPayload(title: "Mobile Fundamentals", body: "45 min on Tue 27 Oct",
                        sessionID: "s4", courseID: "mobile")
let data = try encoded(added)
print(String(decoding: data, as: UTF8.self))
print(data.count, "bytes of", maximumPushBytes)

// The same payload back, as the app receives it
let back = try JSONDecoder().decode(PushPayload.self, from: data)
print(back == added, back.aps.threadID ?? "no thread")

// A body that carried the session's whole note instead of a summary
let note = String(repeating: "Read chapter 4 again and redo the exercises. ", count: 100)
let long = try encoded(PushPayload(title: "Mobile Fundamentals", body: note, sessionID: "s4", courseID: "mobile"))
print(long.count, "bytes:", long.count > maximumPushBytes ? "APNs refuses it" : "fits")
```

```
ana@vm:~/l17$ swift build
Building for debugging...
[Constructing description]
[Planning deferred tasks]
[10 / 26] PlannerCore
[21 / 36] remind-product
[23 / 37] remind-product
[32 / 41] week-product
[41 / 41] push-product
Build complete! (1.59 secs)
ana@vm:~/l17$ .build/debug/push
{"aps":{"alert":{"body":"45 min on Tue 27 Oct","title":"Mobile Fundamentals"},"sound":"default","thread-id":"mobile"},"session-id":"s4"}
136 bytes of 4096
true mobile
4616 bytes: APNs refuses it
```

**136 bytes é o que uma notificação precisa, e 4.616 é o que uma descuidada vira.** O primeiro payload é a
mensagem inteira: quem, o quê e quando, com o id da sessão para o app abrir. O segundo pôs uma nota de cem
frases no corpo, e o APNs a recusaria, então o pedido do servidor falha e o estudante nunca fica sabendo
que uma sessão foi acrescentada. A regra que sai disso é a do planner: **uma notificação leva um resumo e
um id, nunca os dados.** O app abre, lê o id e busca a sessão pelo repositório da aula 14, que tem a nota
inteira.

`true mobile` é a ida e volta: o que foi enviado decodifica para um valor igual, e o `thread-id` chegou
como `threadID`. No app, o payload chega ao delegate da seção 05 como o `userInfo` da notificação, um
dicionário, e o planner o decodifica do mesmo jeito depois de transformar esse dicionário de volta em
JSON.
