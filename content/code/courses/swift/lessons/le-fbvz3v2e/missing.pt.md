---
title: Chaves que faltam
version: 1
---

Um JSON escrito por uma versão mais antiga de um app não tem os campos acrescentados depois. Um
servidor omite um campo quando não tem nada a dizer. **A regra do decoder é rígida e simples: uma
propriedade opcional pode faltar, e qualquer outra não pode.**

```swift
// Missing.swift
import Foundation

struct StudySession: Codable {
    var minutes: Int
    var done: Bool
    var note: String?
}

let older = #"{"minutes": 45, "done": true}"#
let session = try JSONDecoder().decode(StudySession.self, from: Data(older.utf8))
print(session)

let planned = #"{"minutes": 30}"#
do {
    _ = try JSONDecoder().decode(StudySession.self, from: Data(planned.utf8))
} catch {
    print(error)
}
```

```
ana@vm:~/sw/l13$ swift Missing.swift
StudySession(minutes: 45, done: true, note: nil)
DecodingError.keyNotFound: Key 'done' not found in keyed decoding container. Debug description: No value associated with key CodingKeys(stringValue: "done", intValue: nil) ("done").
```

O primeiro JSON não tem `note`, e `note` é `String?`, então foi decodificado com `note: nil`. O segundo
não tem `done`, e `done` é `Bool`: **`keyNotFound`**, com o nome da chave. A decodificação inteira
falhou, não só aquele campo, porque uma `StudySession` sem `done` não é uma `StudySession`.

Essa regra acerta mais do que incomoda: é o decoder se recusando a inventar um valor. Quando o app tem
um padrão sensato, uma sessão planejada que ainda não foi feita, o lugar de dizer isso é o
inicializador que o compilador geraria:

```schooling-example
{"language": "swift", "file": "Defaults.swift", "parts": [{"code": "// Defaults.swift\nimport Foundation\n\nstruct StudySession: Codable {\n    var minutes: Int\n    var done: Bool\n    var note: String?\n", "note": "A mesma struct do `Missing.swift`. Escrever o `init(from:)` substitui só esse inicializador: o compilador continua gerando o `CodingKeys` e o `encode(to:)`."}, {"code": "    init(from decoder: any Decoder) throws {\n        let container = try decoder.container(keyedBy: CodingKeys.self)", "note": "Um **container com chaves** é o objeto JSON visto através do `CodingKeys`. Ele lança se o JSON neste ponto não for um objeto."}, {"code": "        minutes = try container.decode(Int.self, forKey: .minutes)", "note": "`decode` para uma chave que precisa estar lá, exatamente como o código gerado faz: um `minutes` ausente continua sendo erro."}, {"code": "        done = try container.decodeIfPresent(Bool.self, forKey: .done) ?? false", "note": "O `decodeIfPresent` devolve `nil` para uma chave ausente em vez de lançar, e o `?? false` (lição 2) transforma isso no padrão. Uma chave presente com o tipo errado ainda lança."}, {"code": "        note = try container.decodeIfPresent(String.self, forKey: .note)\n    }\n}", "note": "`note` é opcional, então o código gerado também teria usado `decodeIfPresent`. Depois que você escreve o inicializador, toda propriedade é sua para atribuir."}, {"code": "\nlet planned = #\"{\"minutes\": 30}\"#\nlet session = try JSONDecoder().decode(StudySession.self, from: Data(planned.utf8))\nprint(session)", "note": "O JSON em que uma sessão planejada chega, sem a chave `done`, agora decodifica."}]}
```

```
ana@vm:~/sw/l13$ swift Defaults.swift
StudySession(minutes: 30, done: false, note: nil)
```

**O padrão mora no tipo**, escrito uma vez, e todo decoder que lê uma `StudySession` o recebe. Uma
propriedade declarada `var done: Bool = false` não faria o mesmo: o `init(from:)` gerado ignora o valor
padrão e continua exigindo a chave.

Tornar toda propriedade opcional é a outra saída, e ela muda o problema de lugar, para cada linha que
lê uma delas, que então precisa decidir o que `nil` quer dizer. Use um opcional onde a ausência
significa algo, como uma nota que ninguém escreveu, e um padrão onde não significa.
