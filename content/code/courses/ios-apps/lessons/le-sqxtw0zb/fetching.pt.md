---
title: Um pedido, com async/await
version: 1
---

**O `URLSession` é como um app da Apple fala HTTP, e desde o iOS 15 pedir algo a ele é uma linha
com `await` na frente.** A linha suspende a função até a resposta chegar, e o resto do app segue
enquanto isso. Foi na aula 14 de `swift` que `async` e `await` foram ensinados; esta seção os usa num
pedido de verdade.

O mesmo `URLSession` existe no Linux, num módulo próprio. Nos sistemas da Apple ele faz parte do
Foundation. No Foundation de código aberto que vem com o toolchain do Swift no Linux ele mora no
`FoundationNetworking`, porque precisa da `libcurl` por baixo, e um programa que nunca toca a rede não
deveria ter de ligá-la. Então todo arquivo deste curso que o usa começa com as mesmas quatro linhas, e
num Mac o `#if` simplesmente é falso.

## Um target para ele

O pacote do planner ganha um segundo programa, `fetch`, ao lado do `week` da aula 1. Troque o
`Package.swift` em `~/planner` por este, que é o da aula 1 com uma linha a mais:

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
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

## Esquecendo o import primeiro

Esta é a primeira versão que a maioria das pessoas escreve, com o Foundation e mais nada. Salve-a como
`Sources/fetch/main.swift`:

```swift
// Sources/fetch/main.swift
import Foundation

let url = URL(string: "http://127.0.0.1:8012/courses")!
let (data, response) = try await URLSession.shared.data(from: url)
print(response, data.count)
```

Num Mac ela compila. No Linux não, e vale reconhecer a mensagem, porque ela não diz "import
FoundationNetworking":

```
ana@vm:~/planner$ swift build 2>&1 | grep error:
error: SwiftCompile normal x86_64 failed with a nonzero exit code. Command line:     cd /home/ana
/home/ana/planner/Sources/fetch/main.swift:5:45: error: type 'URLSession' (aka 'AnyObject') has no member 'shared'
  |                                             `- error: type 'URLSession' (aka 'AnyObject') has no member 'shared'
error: Build failed
```

**O `URLSession` é encontrado, mas como um marcador vazio**, e é por isso que o compilador o chama de
`AnyObject` e não acha nenhum `shared` nele. Quando você vir essa frase sobre qualquer tipo de rede
no Linux, o que falta é o import.

## O pedido

Com o import, e com a resposta lida direito. Troque o `Sources/fetch/main.swift`:

```schooling-example
{"language": "swift", "file": "Sources/fetch/main.swift", "parts": [{"code": "// Sources/fetch/main.swift\nimport Foundation\n#if canImport(FoundationNetworking)\nimport FoundationNetworking\n#endif\n", "note": "O `canImport` pergunta se o módulo existe no sistema para o qual se está compilando. No Linux existe, e é importado; num Mac não existe, e a linha some."}, {"code": "let url = URL(string: \"http://127.0.0.1:8012/courses\")!\nlet (data, response) = try await URLSession.shared.data(from: url)\n", "note": "O `data(from:)` envia um `GET` e suspende até o corpo inteiro chegar. Ele devolve duas coisas: os bytes, e um `URLResponse` que descreve a resposta. Um `await` no nível de cima é permitido no `main.swift`, que roda como uma função assíncrona."}, {"code": "guard let http = response as? HTTPURLResponse else { fatalError(\"not HTTP\") }\nprint(http.statusCode, http.value(forHTTPHeaderField: \"Content-Type\") ?? \"\")\nprint(String(decoding: data, as: UTF8.self))\n", "note": "Para uma URL `http` a resposta é um `HTTPURLResponse`, que traz o código de status e os cabeçalhos. O corpo é impresso como texto aqui só para vê-lo; a seção 04 o transforma em valores Swift."}]}
```

Com o servidor da seção 02 rodando no terminal dele:

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (5.76 secs)
ana@vm:~/planner$ .build/debug/fetch
200 application/json
[{"id": "sql", "title": "SQL Databases"}, {"id": "mobile", "title": "Mobile Fundamentals"}]
```

**O status, o tipo e o corpo chegam separados, e só o código decide em qual deles confiar.** O
`URLSession` não lançou nada aqui, e não teria lançado nada para um `404` também: um erro HTTP ainda é
uma resposta, e para o `URLSession` só a falta de resposta é um erro. A seção 05 é construída em cima
dessa diferença.

## Num Mac, a mesma chamada dentro de um app

Nada muda na chamada. O que muda é onde ela roda: num app, uma função que espera um pedido é
iniciada a partir de uma view, e o modificador `task` do SwiftUI é o lugar de costume, porque ele
cancela o trabalho quando a view vai embora. Isto não foi executado, como nada do Xcode foi:

```swift
// CourseListView.swift
import SwiftUI

struct CourseListView: View {
    @State private var count = 0

    var body: some View {
        Text("\(count) bytes")
            .task {
                let url = URL(string: "http://127.0.0.1:8012/courses")!
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    count = data.count
                }
            }
    }
}
```

O `try?` joga o erro fora, o que serve para a primeira linha de uma tela e é errado para a última. A
seção 06 o troca por um estado que a tela consegue desenhar.
