---
title: Quando os nomes do JSON não são os seus
version: 1
---

O código gerado usa o nome de cada propriedade como chave. Isso funciona enquanto você escolhe os dois
lados. **Um servidor escrito por outra pessoa, muitas vezes em outra linguagem, nomeia os campos do
jeito dele**: `study_minutes` e `is_done`, no snake case que Python e SQL usam, onde o Swift escreve
`minutes` e `done`. Renomeie as suas propriedades para bater e toda linha de Swift que as usa fica
estranha; deixe como está, e a decodificação falha na primeira chave ausente.

A ponte é o enum `CodingKeys` que a seção 02 descreveu. Escreva-o você mesmo, e o compilador usa o seu
em vez de gerar um:

```swift
// Keys.swift
import Foundation

struct StudySession: Codable {
    var minutes: Int
    var done: Bool

    enum CodingKeys: String, CodingKey {
        case minutes = "study_minutes"
        case done = "is_done"
    }
}

let fromServer = #"[{"study_minutes": 45, "is_done": true}, {"study_minutes": 30, "is_done": false}]"#
let sessions = try JSONDecoder().decode([StudySession].self, from: Data(fromServer.utf8))
print(sessions)
let back = try JSONEncoder().encode(sessions[0])
print(String(decoding: back, as: UTF8.self))
```

```
ana@vm:~/sw/l13$ swift Keys.swift
[Keys.StudySession(minutes: 45, done: true), Keys.StudySession(minutes: 30, done: false)]
{"study_minutes":45,"is_done":true}
```

O `CodingKeys` é um enum com raw value `String` (lição 7) que conforma a `CodingKey`. **Cada caso é uma
propriedade, e o raw value dele é a chave no JSON.** Os dois sentidos o usam: as sessões foram
decodificadas de `study_minutes` e `is_done`, e codificar uma de volta escreve os nomes do servidor, não
os do Swift. O JSON no programa é uma string crua, `#"…"#`, em que as aspas dispensam barra invertida.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 160\" role=\"img\" data-fig=\"l13-keys\" aria-label=\"Três colunas. À esquerda, a struct StudySession do Swift com as propriedades minutes e done. No meio, o enum CodingKeys com case minutes = \"study_minutes\" e case done = \"is_done\". À direita, o objeto JSON com as chaves study_minutes: 45 e is_done: true. Setas ligam cada propriedade ao seu caso e cada caso à sua chave, nos dois sentidos.\"><defs><marker id=\"l13-keys-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-keys-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l13-keys-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a struct do Swift</text><rect x=\"20\" y=\"38\" width=\"180\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">var minutes: Int</text><text x=\"110.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">var done: Bool</text><text x=\"360.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">CodingKeys</text><rect x=\"250\" y=\"38\" width=\"220\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">case minutes = \"study_minutes\"</text><text x=\"360.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">case done = \"is_done\"</text><text x=\"610.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o JSON do servidor</text><rect x=\"520\" y=\"38\" width=\"180\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">\"study_minutes\": 45</text><text x=\"610.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">\"is_done\": true</text><path d=\"M202 70 L248 70\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-keys-ah-amber)\"></path><path d=\"M472 70 L518 70\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-keys-ah-amber)\"></path><path d=\"M202 112 L248 112\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-keys-ah-amber)\"></path><path d=\"M472 112 L518 112\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-keys-ah-amber)\"></path></svg>", "caption": "O CodingKeys fica entre os dois nomes: cada caso é uma propriedade, e o raw value dele é a chave no JSON. O mesmo enum serve para decodificar e para codificar.", "same": ["CodingKeys"]}
```

Duas regras prendem o enum à struct. Toda propriedade armazenada que deve ser codificada precisa de um
caso, e uma propriedade deixada fora de um `CodingKeys` escrito à mão não é codificada nem decodificada,
então precisa ter um valor padrão. E um caso que não nomeia propriedade nenhuma não compila.

## Quando a regra é mecânica

Quando toda chave é simplesmente a forma snake case do nome da propriedade, um decoder pode fazer a
conversão para todas:

```swift
// Snake.swift
import Foundation

struct StudySession: Codable {
    var studyMinutes: Int
    var isDone: Bool
}

let fromServer = #"{"study_minutes": 45, "is_done": true}"#
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
let session = try decoder.decode(StudySession.self, from: Data(fromServer.utf8))
print(session)
```

```
ana@vm:~/sw/l13$ swift Snake.swift
StudySession(studyMinutes: 45, isDone: true)
```

`keyDecodingStrategy = .convertFromSnakeCase` transforma `study_minutes` em `studyMinutes` antes de
casar, e o `JSONEncoder` tem o espelho, `.convertToSnakeCase`. Isso poupa escrever o enum, e tira o
mapeamento do tipo e o põe em quem configura o decoder, então **todo decoder que lê esse tipo precisa
lembrar de ajustá-lo**. Um enum `CodingKeys` viaja com a struct, e por isso é a escolha mais segura
quando um tipo é decodificado em vários lugares.
