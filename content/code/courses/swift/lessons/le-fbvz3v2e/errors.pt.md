---
title: Lendo um erro de decodificação
version: 1
---

Um erro de decodificação é um valor do enum **`DecodingError`**, e os casos dele dizem que tipo de
coisa deu errado; cada um carrega um **contexto** que diz onde. Impresso como está, é uma frase longa.
Pego por caso, vira algo que uma linha de log ou uma mensagem de suporte consegue usar. Três pedaços de
JSON quebrados, um de cada tipo:

```swift
// Errors.swift
import Foundation

struct StudySession: Codable {
    var minutes: Int
    var done: Bool
}

struct Course: Codable {
    var name: String
    var sessions: [StudySession]
}

let broken = [
    #"[{"name": "Swift", "sessions": [{"minutes": "45", "done": true}]}]"#,
    #"[{"name": "Swift", "sessions": [{"minutes": 45, "done": true}, {"done": false}]}]"#,
    #"[{"name": "Swift", "sessions": [{"minutes": 45, "done": true}]"#,
]

for text in broken {
    do {
        _ = try JSONDecoder().decode([Course].self, from: Data(text.utf8))
    } catch let DecodingError.typeMismatch(type, context) {
        print("wrong type: expected \(type) at \(path(context.codingPath))")
    } catch let DecodingError.keyNotFound(key, context) {
        print("missing key: \(key.stringValue) at \(path(context.codingPath))")
    } catch let DecodingError.dataCorrupted(context) {
        print("not JSON: \(context.debugDescription)")
    } catch {
        print("other:", error)
    }
}

func path(_ keys: [any CodingKey]) -> String {
    keys.map { $0.intValue.map { "[\($0)]" } ?? ".\($0.stringValue)" }.joined()
}
```

```
ana@vm:~/sw/l13$ swift Errors.swift
wrong type: expected Int at [0].sessions[0].minutes
missing key: minutes at [0].sessions[1]
not JSON: The given data was not valid JSON.
```

| caso | o que quer dizer | aqui |
|---|---|---|
| `typeMismatch(type, context)` | a chave está lá, com um valor de outro tipo | `"45"` entre aspas é uma string onde se esperava um `Int` |
| `keyNotFound(key, context)` | falta uma chave obrigatória | a segunda sessão não tem `minutes` |
| `dataCorrupted(context)` | os bytes não são JSON válido, ou um valor nem pode ser lido | falta o último `]` |
| `valueNotFound(type, context)` | a chave está lá e o valor dela é `null` | não aparece neste programa |

**O caminho de codificação é a metade útil.** O `context.codingPath` é a lista de chaves e índices do
topo do documento até a falha, e a pequena função `path` no fim do programa a escreve como
`[0].sessions[1]`: o primeiro curso, a segunda sessão dele. Num arquivo com duzentas sessões, esse
caminho é a diferença entre achar o registro ruim e ler o arquivo no olho.

Cada `catch` usa os padrões da aula 12, com `let` amarrando os valores que o caso carrega, e o `catch`
final trata o resto, já que o `decode` é declarado com `throws` puro.

## Falhe alto, na borda

O decoder recusou os três documentos em vez de produzir um planner com uma sessão errada dentro, e esse
é o comportamento a manter. **Pegue erros de decodificação onde os dados entram**, na leitura do arquivo
ou na resposta da rede, registre o caso e o caminho, e diga à estudante que o planner não pôde ser
carregado. Um `try?` ali transformaria um arquivo quebrado num planner vazio, e a estudante em alguém
que acredita não ter sessão nenhuma.
