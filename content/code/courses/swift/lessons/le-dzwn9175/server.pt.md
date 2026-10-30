---
title: O planner como um pequeno servidor
version: 1
---

Swift num servidor não é curiosidade. A Apple roda serviços em Swift em produção, e a comunidade
mantém a biblioteca de rede por baixo da maioria deles, o **SwiftNIO**, e dois frameworks web
construídos sobre ela, o Vapor e o Hummingbird. Um planner de estudos num celular acaba
falando com um servidor que guarda as sessões, e esse servidor pode ser escrito na mesma linguagem do
app.

Esta seção constrói o menor servidor útil com o Hummingbird 2: duas rotas, `/week` e `/sessions`,
respondendo com texto e com JSON. É um pacote, como a aula 19 ensinou, com uma dependência buscada
no GitHub. Crie um diretório `server` e dois arquivos dentro dele:

```swift
// swift-tools-version: 6.2
// Package.swift
import PackageDescription

let package = Package(
    name: "PlannerServer",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.28.0"),
    ],
    targets: [
        .executableTarget(
            name: "PlannerServer",
            dependencies: [.product(name: "Hummingbird", package: "hummingbird")]
        ),
    ]
)
```

O `platforms` só importa num Mac: o Hummingbird precisa do macOS 14 ou mais novo, e a linha diz
isso. No Linux ela é ignorada, porque não há API de Linux mais antiga a excluir.

```schooling-example
{"language": "swift", "file": "Sources/PlannerServer/main.swift", "parts": [
 {"code": "// Sources/PlannerServer/main.swift\nimport Hummingbird", "note": "Um import. O Hummingbird traz o SwiftNIO e os tipos de HTTP com ele."},
 {"code": "struct Session: ResponseCodable {\n    let course: String\n    let date: String\n    let minutes: Int\n}", "note": "`ResponseCodable` é `Codable` mais a promessa do Hummingbird de mandar o valor como JSON. A aula 13 fez o resto do trabalho: o compilador escreve a codificação."},
 {"code": "let sessions = [\n    Session(course: \"Swift\", date: \"2026-11-02\", minutes: 45),\n    Session(course: \"Swift\", date: \"2026-11-03\", minutes: 30),\n    Session(course: \"SQL\", date: \"2026-11-04\", minutes: 60),\n]", "note": "Três sessões guardadas na memória. Um servidor de verdade as leria de um banco de dados; este mantém o exemplo num arquivo só."},
 {"code": "let router = Router()\nrouter.get(\"sessions\") { _, _ in sessions }\nrouter.get(\"week\") { _, _ in \"\\(sessions.map(\\.minutes).reduce(0, +)) of 300 minutes\\n\" }", "note": "Uma rota é um caminho e uma closure, com a closure no fim da chamada da aula 3. A closure recebe a requisição e um contexto, ignorados aqui com `_`, e devolve o que puder virar resposta: um array de `Session` vira JSON, uma `String` vira texto."},
 {"code": "let app = Application(router: router, configuration: .init(address: .hostname(\"127.0.0.1\", port: 8090)))\ntry await app.runService()", "note": "Escutar na porta 8090 só desta máquina, e rodar até ser parado. O `runService` é `async` e `throws`, então é chamado com `try await` no nível de cima do `main.swift`, como a aula 14 permitiu."}
]}
```

```
ana@vm:~/sw/l20/server$ swift build 2>&1 | tail -2
[740 / 740] PlannerServer-product
Build complete! (214.89 secs)
ana@vm:~/sw/l20/server$ ls .build/checkouts | wc -l
24
```

O primeiro build baixa o Hummingbird e tudo de que ele depende, e compila tudo. O `tail -2` guarda as
últimas linhas de uma longa lista de passos de compilação, e o `ls .build/checkouts` conta o que foi
buscado: vinte e quatro pacotes, o Hummingbird e os vinte e três abaixo dele, a maioria do SwiftNIO e
seus parentes. Esse primeiro build leva minutos, não segundos, e a linha acima diz quantos levou na
máquina em que o curso foi gravado; todo build depois dele leva segundos.

## Dois terminais

Um servidor roda até ser parado, então precisa de um terminal só para ele. **Inicie-o num
terminal**:

```
ana@vm:~/sw/l20/server$ .build/debug/PlannerServer
2026-10-30T15:47:37-0300 info Hummingbird: [HummingbirdCore] Server started and listening on 127.0.0.1:8090
```

O `swift run` roda o executável de um pacote, e o `--skip-build` manda usar o que acabou de ser
construído em vez de conferir todos os pacotes de novo; sem a opção ele faz as duas coisas, e imprime
primeiro o progresso do build. A linha que ele imprimiu é o log do próprio servidor, pelo
`swift-log`, o pacote de log que a maior parte do Swift de servidor usa. Deixe esse terminal quieto e
**abra um segundo** para as requisições:

```
ana@vm:~/sw/l20/server$ curl -s -i localhost:8090/week
HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8
Content-Length: 19
Date: Fri, 30 Oct 2026 18:47:38 GMT

135 of 300 minutes
ana@vm:~/sw/l20/server$ curl -s localhost:8090/sessions; echo
[{"date":"2026-11-02","course":"Swift","minutes":45},{"date":"2026-11-03","course":"Swift","minutes":30},{"date":"2026-11-04","course":"SQL","minutes":60}]
ana@vm:~/sw/l20/server$ curl -s -i localhost:8090/semana
HTTP/1.1 404 Not Found
Content-Length: 0
Date: Fri, 30 Oct 2026 18:47:39 GMT
```

O `-s` deixa o `curl` calado sobre o próprio progresso, e o `echo` depois da segunda requisição
acrescenta a quebra de linha com que o JSON não termina. A primeira requisição devolve texto, com os
cabeçalhos que o `curl -i` pede para ver: status `200 OK`, um `Content-Type` de texto puro e um
tamanho de 19 bytes. A segunda devolve as três sessões em JSON, e a ordem das chaves dentro de cada
objeto não é a ordem das propriedades da struct, e nem foi a mesma de uma execução do servidor
para a outra. Objetos JSON não têm ordem, o `JSONEncoder` não
promete uma, e a aula 13 mostrou o `.sortedKeys` para o dia em que a ordem importar a uma pessoa. A
terceira pede um caminho que nenhuma rota trata e recebe **`404 Not Found` com corpo vazio**, que o
Hummingbird manda sem uma linha de código sua.

## O outro lado do fio

A mesma linguagem pode ser o cliente. Este script pede as sessões ao servidor com `URLSession`, a API
que um app de iPhone usa, e as decodifica com a metade `Decodable` da aula 13:

```swift
// Client.swift
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct Session: Decodable {
    let course: String
    let date: String
    let minutes: Int
}

let url = URL(string: "http://localhost:8090/sessions")!
let (data, response) = try await URLSession.shared.data(from: url)
let status = (response as? HTTPURLResponse)?.statusCode ?? 0
let sessions = try JSONDecoder().decode([Session].self, from: data)
print("HTTP \(status), \(sessions.count) sessions")
for session in sessions {
    print(session.date, session.course, session.minutes)
}
```

```
ana@vm:~/sw/l20/server$ swift Client.swift
HTTP 200, 3 sessions
2026-11-02 Swift 45
2026-11-03 Swift 30
2026-11-04 SQL 60
```

**A struct é declarada duas vezes**, uma de cada lado, e nada confere que as duas concordam. Uma
propriedade renomeada no servidor vira um `keyNotFound` no cliente, como a aula 13 mostrou.
Compartilhar uma definição é para isso que serve um pacote: um target de biblioteca com os modelos,
do qual dependem o servidor e o app. A aula 19 construiu exatamente esse formato, com o
`PlannerCore`.

Pare o servidor com Ctrl+C no terminal dele.

## Onde um servidor Swift é implantado

No Linux, quase sempre, e normalmente num contêiner. O arquivo do toolchain tem 1,1 GB, e ninguém
quer isso dentro de uma imagem que só precisa rodar um programa. A seção 05 gera um binário que não
precisa de nada disso.
