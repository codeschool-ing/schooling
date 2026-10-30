---
title: Codificando um planner em JSON
version: 1
---

Um planner que esquece tudo quando fecha não é um planner. Os cursos e as sessões dele precisam ser
gravados em algum lugar, um arquivo no celular ou uma requisição a um servidor, e lidos de volta
depois, e JSON é o formato que quase todo servidor e arquivo deste curso fala. **Escrever a conversão
à mão, uma propriedade por vez em cada sentido, é como um campo acaba salvo e nunca carregado.** A
resposta do Swift é deixar o compilador escrevê-la.

Um tipo que conforma a **`Codable`** pode virar JSON e voltar. Para uma struct cujas propriedades são
todas `Codable` também, como `Int`, `Bool`, `String`, arrays e outras structs `Codable`, a conformância
é a palavra e mais nada: o compilador gera o código que lê e escreve cada propriedade, pelo nome.

```swift
// Encode.swift
import Foundation

struct StudySession: Codable {
    var minutes: Int
    var done: Bool
}

struct Course: Codable {
    var name: String
    var sessions: [StudySession]
}

let planner = [
    Course(name: "Swift", sessions: [StudySession(minutes: 45, done: true),
                                     StudySession(minutes: 30, done: false)]),
    Course(name: "Kotlin", sessions: []),
]

let encoder = JSONEncoder()
let compact = try encoder.encode(planner)
print(String(decoding: compact, as: UTF8.self))
print(compact.count, "bytes")

encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let pretty = try encoder.encode(planner)
try pretty.write(to: URL(fileURLWithPath: "planner.json"))
print("wrote planner.json,", pretty.count, "bytes")
```

```
ana@vm:~/sw/l13$ swift Encode.swift
[{"name":"Swift","sessions":[{"minutes":45,"done":true},{"minutes":30,"done":false}]},{"name":"Kotlin","sessions":[]}]
118 bytes
wrote planner.json, 242 bytes
ana@vm:~/sw/l13$ cat planner.json; echo
[
  {
    "name" : "Swift",
    "sessions" : [
      {
        "done" : true,
        "minutes" : 45
      },
      {
        "done" : false,
        "minutes" : 30
      }
    ]
  },
  {
    "name" : "Kotlin",
    "sessions" : [

    ]
  }
]
```

O `import Foundation` traz o `JSONEncoder` e o `JSONDecoder`, que não fazem parte da biblioteca
padrão; no Linux, o toolchain traz o seu próprio Foundation (a aula 20 trata do que ele tem e do que
não tem). O `encoder.encode(planner)` devolve **`Data`**, um buffer de bytes, que é o que um arquivo ou
uma requisição de rede guarda; o `String(decoding:as:)` lê esses bytes como texto UTF-8 para o `print`
poder mostrá-los. O encoder pode lançar, se um valor não puder ser representado, então a chamada leva
`try` (aula 12), e no nível de cima de um script não é preciso mais nada.

A primeira linha é JSON **compacto**, 118 bytes sem espaços, que é o que vai pela rede. Depois, duas
opções de formatação: `.prettyPrinted` quebra linhas e indenta, e `.sortedKeys` escreve as chaves de
cada objeto em ordem alfabética. O `write(to:)` põe os 242 bytes em `planner.json`, e o `cat` mostra o
arquivo. Dois detalhes nele: o encoder escreve `" : "` com um espaço de cada lado, e o arquivo não
termina com quebra de linha, e é por isso que o comando acrescenta um `echo`.

## Por que ordenar as chaves

Nessa execução a linha compacta pôs `name` primeiro, como foi declarado, e `minutes` antes de `done`.
**Um objeto JSON não tem ordem, e o encoder não promete nenhuma.** Rode o mesmo programa três vezes:

```
ana@vm:~/sw/l13$ for run in 1 2 3; do swift Encode.swift | head -1; done
[{"name":"Swift","sessions":[{"minutes":45,"done":true},{"minutes":30,"done":false}]},{"name":"Kotlin","sessions":[]}]
[{"name":"Swift","sessions":[{"done":true,"minutes":45},{"done":false,"minutes":30}]},{"name":"Kotlin","sessions":[]}]
[{"sessions":[{"done":true,"minutes":45},{"done":false,"minutes":30}],"name":"Swift"},{"sessions":[],"name":"Kotlin"}]
```

Três execuções, três arranjos dos mesmos dados: `minutes` antes de `done` na primeira e depois nas
outras duas, `name` primeiro em duas execuções e por último na terceira. O encoder guarda as chaves de
cada objeto num dicionário, e o Swift sorteia uma semente nova para o hashing a cada processo, então a
ordem muda entre execuções de um programa que não mudou. O `.sortedKeys` deixa a saída igual em toda
execução, o que importa no momento em que um arquivo é comparado com uma cópia mais velha dele mesmo,
no controle de versão ou num teste que confere o que foi gravado. Um programa que lê o JSON nunca se
importa, e a seção 02 o lê de volta.
