---
title: Decodificação, e o tipo que o servidor fala
version: 1
---

**O `JSONDecoder` transforma bytes em valores Swift, e faz isso lendo o tipo que você entrega a ele.**
A aula 13 de `swift` ensinou o `Codable`: uma struct que diz ser `Decodable` ganha a decodificação
escrita pelo compilador, uma chave por propriedade guardada. Esta seção põe isso para trabalhar na
resposta do servidor, e nas duas formas como essa resposta pode estar errada.

## Um tipo para o fio, não para o modelo

O movimento tentador é tornar o `Course` e o `StudySession` da aula 1 `Codable` e decodificar direto
neles. **Este curso mantém um tipo separado para o que viaja pela rede**, e o motivo aparece na
primeira sessão que o servidor envia: ela diz `courseId`, e a convenção de nomes do Swift diz
`courseID`. Mais diferenças vêm conforme um app cresce: um servidor que manda uma data como timestamp,
um campo que o app não guarda, um campo que o app guarda e o servidor nunca manda. Um tipo de fio
absorve todas elas num arquivo, e o modelo que as telas usam fica com o formato que o app quer.

Salve isto como `Sources/PlannerCore/Wire.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/Wire.swift", "parts": [{"code": "// Sources/PlannerCore/Wire.swift\nimport Foundation\n\n/// A course as the server spells it.\npublic struct WireCourse: Codable, Sendable {\n    public let id: String\n    public let title: String\n}\n", "note": "Um curso chega com os mesmos dois nomes que o modelo usa, então a decodificação do próprio compilador basta."}, {"code": "/// A session as the server spells it: `courseId`, where Swift says `courseID`.\npublic struct WireSession: Codable, Sendable {\n    public let id: String\n    public let courseID: String\n    public let date: String\n    public let minutes: Int\n    public let done: Bool\n\n    enum CodingKeys: String, CodingKey {\n        case id, date, minutes, done\n        case courseID = \"courseId\"\n    }\n}\n", "note": "O `CodingKeys` é o único lugar onde as duas grafias se encontram. Cada case é uma propriedade; o raw value dele é a chave no JSON. Deixe uma propriedade fora do enum e o compilador se recusa a sintetizar a decodificação, que é como você descobre."}, {"code": "extension WireCourse {\n    public var course: Course { Course(id: id, title: title) }\n}\n\nextension WireSession {\n    public init(_ s: StudySession) {\n        self.init(id: s.id, courseID: s.courseID, date: s.date, minutes: s.minutes, done: s.done)\n    }\n    public var session: StudySession {\n        StudySession(id: id, courseID: courseID, date: date, minutes: minutes, done: done)\n    }\n}\n", "note": "As conversões nos dois sentidos. Na ida, a seção 05 codifica um `WireSession` feito de uma sessão do modelo; na volta, todo valor de fio vira valor do modelo antes que qualquer outra coisa o veja."}]}
```

## Lendo a resposta do servidor

Troque o `Sources/fetch/main.swift`. Ele decodifica os cursos do servidor e depois decodifica duas
sessões escritas à mão no programa, cada uma errada de um jeito como servidores de fato erram:

```schooling-example
{"language": "swift", "file": "Sources/fetch/main.swift", "parts": [{"code": "// Sources/fetch/main.swift\nimport Foundation\n#if canImport(FoundationNetworking)\nimport FoundationNetworking\n#endif\nimport PlannerCore\n\nlet url = URL(string: \"http://127.0.0.1:8012/courses/sql/sessions\")!\nlet (data, _) = try await URLSession.shared.data(from: url)\nlet sessions = try JSONDecoder().decode([WireSession].self, from: data).map(\\.session)\nfor s in sessions {\n    print(s.id, s.courseID, s.date, s.minutes, s.done)\n}\n", "note": "`[WireSession].self` é o tipo a decodificar: um array deles. O decodificador percorre o JSON e o tipo juntos, e o `map(\\.session)` transforma cada valor de fio num valor do modelo."}, {"code": "let wrongType = Data(#\"{\"id\": \"s1\", \"courseId\": \"sql\", \"date\": \"2026-10-19\", \"minutes\": \"forty\", \"done\": true}\"#.utf8)\nlet wrongName = Data(#\"{\"id\": \"s1\", \"course_id\": \"sql\", \"date\": \"2026-10-19\", \"minutes\": 40, \"done\": true}\"#.utf8)\nfor body in [wrongType, wrongName] {\n    do {\n        _ = try JSONDecoder().decode(WireSession.self, from: body)\n    } catch {\n        print(error)\n    }\n}\n", "note": "`#\"…\"#` é uma raw string, então as aspas de dentro não precisam de barra. Um corpo manda um número como texto; o outro escreve uma chave em snake case, como muitos servidores fazem. Nenhum é decodificado pela metade: o decodificador lança, e nada fica construído pela metade."}]}
```

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (1.74 secs)
ana@vm:~/planner$ .build/debug/fetch
s1 sql 2026-10-19 50 true
s3 sql 2026-10-23 60 false
DecodingError.typeMismatch: Expected value of type Int. Path: minutes. Debug description: Expected to decode Int but found a string instead.
DecodingError.keyNotFound: Key 'courseId' not found in keyed decoding container. Debug description: No value associated with key CodingKeys(stringValue: "courseId", intValue: nil) ("courseId").
```

**Um `DecodingError` cita a chave e diz o que esperava, e isso é tudo de que você precisa para achar
a diferença.** `typeMismatch` é um valor do tipo errado num caminho; `keyNotFound` é uma chave que o
tipo exige e o JSON não tem. A segunda é a mais comum na prática, porque um servidor renomeou um campo
ou um app foi escrito contra a documentação em vez de contra uma resposta.

## Mantendo isso decodificado com um teste

A decodificação é uma promessa entre dois programas, então merece um teste próprio. Salve isto como
`Tests/PlannerCoreTests/WireTests.swift`; ele decodifica um corpo copiado do `curl` da seção 02 e
confere que a grafia `courseId` virou `courseID`:

```swift
// Tests/PlannerCoreTests/WireTests.swift
import Foundation
import Testing
@testable import PlannerCore

@Test func aSessionFromTheServerBecomesAModelSession() throws {
    let body = Data(#"[{"id": "s1", "courseId": "sql", "date": "2026-10-19", "minutes": 50, "done": true}]"#.utf8)
    let sessions = try JSONDecoder().decode([WireSession].self, from: body).map(\.session)
    #expect(sessions == [StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50, done: true)])
}

@Test func aSessionEncodesWithTheServersSpelling() throws {
    let s = StudySession(id: "s5", courseID: "mobile", date: "2026-10-22", minutes: 30)
    let text = String(decoding: try JSONEncoder().encode(WireSession(s)), as: UTF8.self)
    #expect(text.contains(#""courseId":"mobile""#))
}
```

```
ana@vm:~/planner$ swift test 2>&1 | grep -E "✔|✘"
✔ Test aSessionEncodesWithTheServersSpelling() passed after 0.001 seconds.
✔ Test aSessionFromTheServerBecomesAModelSession() passed after 0.001 seconds.
✔ Test aSessionForNoCourseIsRefused() passed after 0.001 seconds.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.002 seconds.
✔ Test run with 4 tests in 0 suites passed after 0.002 seconds.
```

O segundo teste é o sentido fácil de esquecer. Um enum `CodingKeys` decide também como um valor é
**codificado**, então a sessão que a seção 05 envia sai como `courseId`, que é a grafia que o handler
de `POST` do servidor lê.
