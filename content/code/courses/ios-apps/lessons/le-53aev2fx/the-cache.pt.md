---
title: Um cache que o app controla
version: 1
---

**Uma lista pede a mesma imagem muitas vezes, e um cache é o que torna o segundo pedido de graça.** A
lista do planner desenha uma capa para cada linha, muitas linhas compartilham um curso, e as mesmas
linhas voltam toda vez que a pessoa rola para cima. Sem cache, cada uma dessas é um download e uma
decodificação. Com um, só a primeira é.

Há dois caches que um app de iPhone pode usar, e eles guardam coisas diferentes. **O `URLCache` guarda
respostas**, os bytes, em disco e na memória, conforme o que os cabeçalhos HTTP do servidor permitem; é
o que torna rápido o segundo download. **Um cache de memória do próprio app guarda imagens
decodificadas**, prontas para desenhar, e é o que torna de graça a segunda exibição. O `AsyncImage` no
iOS 17 não promete nenhum dos dois. Esta seção constrói o segundo, em Swift puro, e o roda.

## O cache

Salve isto como `Sources/PlannerCore/ImageCache.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/ImageCache.swift", "parts": [{"code": "// Sources/PlannerCore/ImageCache.swift\nimport Foundation\n#if canImport(FoundationNetworking)\nimport FoundationNetworking\n#endif\n\npublic actor ImageCache {\n    let session: URLSession\n    let memory = NSCache<NSString, NSData>()\n    var inFlight: [URL: Task<Data, any Error>] = [:]\n    public private(set) var downloads = 0\n\n    public init(costLimit: Int, session: URLSession = .shared) {\n        self.session = session\n        memory.totalCostLimit = costLimit\n    }\n\n", "note": "Três coisas guardadas por um actor, para que duas linhas perguntando ao mesmo tempo não vejam as duas um cache vazio e comecem as duas um download. O `NSCache` é o cache de memória do Foundation: ele descarta por conta própria quando passa do `totalCostLimit`, ou quando o sistema fica sem memória. O `inFlight` guarda os downloads que começaram e não terminaram."}, {"code": "    public func data(for url: URL) async throws -> Data {\n        let key = url.absoluteString as NSString\n        if let kept = memory.object(forKey: key) {\n            return kept as Data\n        }\n", "note": "O primeiro lugar a olhar é a memória. A chave é a URL como texto, porque o `NSCache` quer um objeto como chave."}, {"code": "        if let running = inFlight[url] {\n            return try await running.value\n        }\n", "note": "O segundo é um download já em andamento para a mesma URL. Esperar a `Task` dele faz a décima linha que pede `sql.png` esperar o download da primeira linha em vez de começar o seu."}, {"code": "        let task = Task { try await session.data(from: url).0 }\n        inFlight[url] = task\n        downloads += 1\n        defer { inFlight[url] = nil }\n        let data = try await task.value\n        let size = pngSize(data) ?? (0, 0)\n        memory.setObject(data as NSData, forKey: key, cost: decodedBytes(width: size.width, height: size.height))\n        return data\n    }\n\n", "note": "Só então um download novo começa. `inFlight` e `downloads` mudam antes do primeiro `await`, então nenhum outro chamador consegue se meter entre a olhada e o começo. O custo dado ao `NSCache` é o tamanho decodificado da seção 04, não o do arquivo: essa é a memória que a imagem vai ocupar quando desenhada."}, {"code": "    public func isKept(_ url: URL) -> Bool {\n        memory.object(forKey: url.absoluteString as NSString) != nil\n    }\n}\n", "note": "Um jeito de perguntar, de fora, se uma imagem ainda está guardada."}]}
```

No Linux o cache guarda o `Data` baixado, já que não há tipo de imagem em que decodificá-lo; no app ele
guardaria a `UIImage` reduzida da seção 05, com o custo dessa imagem pequena. A estrutura não muda.

## Dez linhas de uma vez

Troque o `Sources/covers/main.swift`. Ele pede dez capas do jeito que a primeira tela de uma lista
pede, todas no mesmo instante, e depois olha o que o cache guardou. O limite é 50 MB de imagens
decodificadas:

```swift
// Sources/covers/main.swift
import Foundation
import PlannerCore

let base = URL(string: "http://127.0.0.1:8015/covers/")!
let cache = ImageCache(costLimit: 50_000_000)       // 50 MB of decoded images

// Ten rows of a list appear at once, asking for three different covers.
let rows = ["sql", "mobile", "sql", "photo", "sql", "mobile", "sql", "mobile", "photo", "sql"]
try await withThrowingTaskGroup(of: Void.self) { group in
    for name in rows {
        group.addTask { _ = try await cache.data(for: base.appending(path: "\(name).png")) }
    }
    try await group.waitForAll()
}
print("\(rows.count) rows, \(await cache.downloads) downloads")

// What the cache still holds once all three are in.
for name in ["sql", "mobile", "photo"] {
    print(name, await cache.isKept(base.appending(path: "\(name).png")) ? "kept" : "evicted")
}
```

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (2.97 secs)
ana@vm:~/planner$ .build/debug/covers
10 rows, 3 downloads
sql evicted
mobile evicted
photo kept
```

**Dez linhas, três downloads.** Toda linha depois da primeira de cada capa achou a imagem na memória ou
o download já rodando, e esperou por ele. Esse é o dicionário de downloads em andamento trabalhando:
sem ele, as cinco linhas pedindo `sql.png` no mesmo instante teriam visto, cada uma, um cache vazio e
começado, cada uma, um download.

**E a fotografia empurrou as duas capas para fora.** O custo dela é 48.771.072 bytes, as duas capas
custam 3.840.000 cada, e juntas passam do limite de 50.000.000, então o `NSCache` descartou. Ele
escolheu ficar com a fotografia e jogar fora as duas capas que a lista mostrava dez vezes entre elas.
O `NSCache` decide sozinho o que descartar, e a documentação da Apple não promete uma ordem, então a
lição não é qual saiu. É que **uma imagem decodificada no tamanho cheio consegue esvaziar um cache
dimensionado para uma lista**. Com o downsampling da seção 05, a fotografia custaria 230.400 e as três
teriam cabido com espaço para mais duzentas.
