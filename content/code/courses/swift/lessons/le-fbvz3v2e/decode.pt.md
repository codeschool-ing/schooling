---
title: Decodificando de volta
version: 1
---

Decodificar é a mesma conversão no sentido contrário, e **o tipo que você pede é a especificação
inteira**: `JSONDecoder().decode([Course].self, from: data)` lê um array de cursos, e confere cada valor
que lê contra a propriedade a que ele se destina.

```swift
// Decode.swift
import Foundation

struct StudySession: Codable {
    var minutes: Int
    var done: Bool
}

struct Course: Codable {
    var name: String
    var sessions: [StudySession]
}

let data = try Data(contentsOf: URL(fileURLWithPath: "planner.json"))
let planner = try JSONDecoder().decode([Course].self, from: data)
for course in planner {
    let done = course.sessions.filter(\.done).map(\.minutes).reduce(0, +)
    print("\(course.name): \(course.sessions.count) sessions, \(done) minutes done")
}
```

```
ana@vm:~/sw/l13$ swift Decode.swift
Swift: 2 sessions, 45 minutes done
Kotlin: 0 sessions, 0 minutes done
```

O programa lê o `planner.json` que a seção 01 gravou, no mesmo diretório, e recebe de volta dois
cursos com suas sessões, como valores Swift de verdade: `course.sessions.filter(\.done)` guarda as
sessões cujo `done` é `true`, e o `map(\.minutes)` pega os minutos delas (aula 4). O curso de Swift tem
duas sessões e 45 minutos feitos; Kotlin não tem nenhuma.

`[Course].self` é como o Swift escreve **o próprio tipo como valor**, a coisa pedida, em vez de um
curso. O decoder precisa dele porque não consegue inferir o tipo a partir do JSON: os mesmos bytes
poderiam ser um `[Course]`, um `[[String: Any]]` ou outra coisa, e só quem chama sabe.

## O que o compilador escreveu por você

`Codable` são dois protocolos, `Encodable` e `Decodable`, e conformar a ele pede ao compilador que gere
três coisas na struct: um método `encode(to:)`, um inicializador `init(from:)`, e um enum aninhado
chamado **`CodingKeys`** com um caso por propriedade armazenada. Nada disso aparece no código, e tudo
isso está lá. As seções 03 e 05 escrevem partes dele à mão, que é como você muda o que o compilador
teria feito.

Uma struct que precisa de um sentido só pode conformar a um protocolo só. Uma resposta de servidor que
só é lida pode ser `Decodable`, e o compilador então não gera código de codificação para ela.
