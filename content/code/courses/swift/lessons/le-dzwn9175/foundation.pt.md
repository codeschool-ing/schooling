---
title: A Foundation no Linux, e o código que pergunta onde está
version: 1
---

A biblioteca padrão é a mesma em toda plataforma: `Int`, `String`, `Array`, opcionais, `Codable`,
`async`/`await` e atores são compilados de um único fonte para todas. **A Foundation é a camada acima
dela, e não é uma biblioteca só em todo lugar.** Num Mac ela é a da Apple, parte do sistema
operacional. No Linux e no Windows é a **swift-corelibs-foundation**, de código aberto, refeita nas
versões recentes sobre um núcleo comum escrito em Swift, e distribuída dentro do toolchain que você
desempacotou na lição 1.

Para quase tudo o que este curso usou, as duas concordam. `JSONEncoder`, `Date`,
`ISO8601DateFormatter`, `ProcessInfo` e `URL` funcionaram no Ubuntu nas lições 13 e 14. Três
diferenças valem a pena conhecer antes que elas surpreendam você:

- **A rede mora num módulo separado no Linux**, o `FoundationNetworking`, porque é construída sobre a
  `libcurl`, e é por isso que a linha do `apt` da lição 1 instalou o `libcurl4-openssl-dev`. Num Mac,
  o `URLSession` simplesmente faz parte da Foundation.
- **Os outros frameworks da Apple não existem lá.** SwiftUI, UIKit, Combine, Core Data e SwiftData
  são da Apple e só vêm com os sistemas da Apple.
- **A biblioteca C por baixo é outra**: `Darwin` nos sistemas da Apple, `Glibc` na maioria das
  distribuições Linux e `Musl` com o SDK estático da seção 05.

## Perguntando na compilação

O Swift responde à pergunta "onde estou?" ao compilar, não ao rodar. O `#if os(Linux)` mantém ou
descarta código conforme o alvo, e o `#if canImport(Module)` pergunta se um módulo existe para aquele
alvo, que na maioria das vezes é a pergunta melhor: é sobre o que o código precisa, e não sobre um
nome para o sistema.

```swift
// Where.swift
import Foundation

#if os(Linux)
print("Compiled for Linux")
#elseif os(macOS)
print("Compiled for macOS")
#endif

#if canImport(Darwin)
print("Darwin: yes")
#else
print("Darwin: no, Glibc instead")
#endif

#if canImport(FoundationNetworking)
print("FoundationNetworking: yes, a separate module")
#else
print("FoundationNetworking: no, URLSession is in Foundation")
#endif

#if canImport(SwiftUI)
print("SwiftUI: yes")
#else
print("SwiftUI: no")
#endif

let start = ISO8601DateFormatter().date(from: "2026-11-02T09:00:00-03:00")!
print(start.addingTimeInterval(45 * 60).formatted(.iso8601))
print(ProcessInfo.processInfo.operatingSystemVersionString)
```

```
ana@vm:~/sw/l20$ swift Where.swift
Compiled for Linux
Darwin: no, Glibc instead
FoundationNetworking: yes, a separate module
SwiftUI: no
2026-11-02T12:45:00Z
Ubuntu 24.04 LTS
```

**Os ramos não tomados nem chegam a ser compilados.** É por isso que um `#elseif os(macOS)` pode
ficar num arquivo compilado no Linux: a linha dele é descartada antes de o compilador verificá-la,
então ela poderia até chamar uma função que o Linux não tem. O mesmo arquivo num Mac imprime o outro
ramo de cada par. Essa execução é descrita e não gravada, porque o curso não tem Mac. A linha da data
mostra a Foundation fazendo a mesma conta que faz num Mac: 09:00 em São Paulo mais 45 minutos,
impressa em UTC como 12:45, que é o formato padrão do `.iso8601`.

## A diferença em que você vai esbarrar

Código escrito num Mac que usa `URLSession` deixa de compilar no Linux, com um erro que não diz o
motivo:

```swift
// Fetch.swift
import Foundation

let session = URLSession.shared
print(type(of: session))
```

```
ana@vm:~/sw/l20$ swiftc Fetch.swift -o fetch
Fetch.swift:4:26: error: type 'URLSession' (aka 'AnyObject') has no member 'shared'
2 | import Foundation
3 | 
4 | let session = URLSession.shared
  |                          `- error: type 'URLSession' (aka 'AnyObject') has no member 'shared'
5 | print(type(of: session))
6 | 

Fetch.swift:5:7: error: cannot convert 'type(of:)' metatype to non-metatype 'Any'
3 | 
4 | let session = URLSession.shared
5 | print(type(of: session))
  |       `- error: cannot convert 'type(of:)' metatype to non-metatype 'Any'
6 | 
```

**"`URLSession` (aka `AnyObject`)" é a pista.** No Linux, a Foundation sozinha só conhece o nome
`URLSession` como um marcador, então o compilador vê um tipo sem membros. O segundo erro decorre do
primeiro: sem `shared`, `session` não tem um tipo que o compilador consiga imprimir, e corrigir o
primeiro remove os dois. A correção é um import, escrito de modo que o mesmo arquivo continue
compilando num Mac, onde o `FoundationNetworking` não existe:

```swift
// FetchFixed.swift
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let session = URLSession.shared
print(type(of: session))
```

```
ana@vm:~/sw/l20$ swiftc FetchFixed.swift -o fetchfixed && ./fetchfixed
URLSession
```

Você verá essas três linhas no topo de quase todo arquivo Swift de servidor que fala com a rede.
**Escreva-as uma vez, no topo, e o arquivo compila nos dois sistemas.** A seção 04 as usa num cliente
que conversa com um servidor.
