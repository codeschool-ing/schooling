---
title: Dois protocolos, uma fonte e um armazenamento
version: 1
---

**Um protocolo diz o que algo sabe fazer e nada sobre como.** O repositório precisa de uma fonte que
liste cursos, liste as sessões de um curso e acrescente uma sessão, e de um armazenamento que carregue
e salve o que o aparelho sabe. Esta seção escreve os dois, e a única implementação de cada um que esta
aula usa. Tudo aqui roda no Linux, no pacote do planner da aula 12.

## A fonte

Salve isto como `Sources/PlannerCore/PlanSource.swift`:

```swift
// Sources/PlannerCore/PlanSource.swift
/// Where the planner's data comes from when it is online.
public protocol PlanSource: Sendable {
    func courses() async throws(APIError) -> [Course]
    func sessions(course id: String) async throws(APIError) -> [StudySession]
    func add(_ s: StudySession) async throws(APIError) -> StudySession
}

extension APIClient: PlanSource {}
```

**O protocolo é o cliente da aula 12 com o corpo tirado.** O `APIClient` já tem esses três métodos com
exatamente essas assinaturas, então a extensão vazia é tudo de que ele precisa para seguir o
protocolo. Os erros continuam `APIError`, o que quer dizer que uma fonte falsa tem de falhar do jeito
que a de verdade falha, com `offline`, `status` ou `unreadable`, e não pode inventar um quarto tipo de
que o repositório nunca ouviu falar.

## O armazenamento

Salve isto como `Sources/PlannerCore/PlanStore.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/PlanStore.swift", "parts": [{"code": "// Sources/PlannerCore/PlanStore.swift\nimport Foundation\n\n/// What the planner keeps on the device: the last plan it saw, and the\n/// sessions added here that the server has not confirmed yet.\npublic struct Snapshot: Codable, Sendable {\n    public var courses: [WireCourse] = []\n    public var sessions: [WireSession] = []\n    public var pending: [WireSession] = []\n    public init() {}\n}\n", "note": "Tudo o que o aparelho guarda, como um valor só. Ele reaproveita os tipos de fio da aula 12, que já são `Codable`, então salvá-lo é uma chamada a um encoder. `pending` é a metade que importa offline: sessões que existem aqui e ainda não no servidor."}, {"code": "/// Where the planner keeps it.\npublic protocol PlanStore: Sendable {\n    func load() throws -> Snapshot\n    func save(_ snapshot: Snapshot) throws\n}\n", "note": "Duas operações, as duas síncronas e as duas podendo falhar. Um armazenamento que nunca salvou nada responde ao `load` com um snapshot vazio em vez de um erro: a primeira abertura não é uma falha."}, {"code": "/// A store that is one JSON file.\npublic struct FileStore: PlanStore {\n    let url: URL\n    public init(url: URL) { self.url = url }\n\n    public func load() throws -> Snapshot {\n        guard FileManager.default.fileExists(atPath: url.path) else { return Snapshot() }\n        return try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: url))\n    }\n\n    public func save(_ snapshot: Snapshot) throws {\n        let encoder = JSONEncoder()\n        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]\n        try encoder.encode(snapshot).write(to: url, options: .atomic)\n    }\n}\n", "note": "O `.atomic` grava num arquivo temporário e o renomeia por cima do antigo, então um app morto no meio da gravação deixa o arquivo antigo inteiro em vez de metade do novo. Formatado e com as chaves em ordem para você conseguir ler, o que a seção 05 faz."}]}
```

Num iPhone o arquivo iria para o diretório Application Support do app, que `URL.applicationSupportDirectory`
nomeia, e não para um lugar onde uma pessoa navega. Aqui ele fica ao lado do programa, como
`planner.json`, para você conseguir abri-lo.

## Um programa para dirigi-lo

O pacote ganha um terceiro programa, `repo`, que a seção 04 roda. Troque o `Package.swift` por este, o
da aula 12 com mais uma linha:

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
        .executableTarget(name: "fetch", dependencies: ["PlannerCore"]),
        .executableTarget(name: "repo", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```
