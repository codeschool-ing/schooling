---
title: Swift Testing, para o código por trás das telas
version: 1
---

**O Swift Testing é o framework da Apple para testar código, e ele não toca em tela nenhuma.** Um
teste é uma função marcada com `@Test`. Uma verificação dentro dele é `#expect`, que registra a
falha e deixa o teste seguir, ou `#require`, que para o teste ali mesmo. A Apple o lançou em 2024,
com o Swift 6 e o Xcode 16, ao lado do XCTest, o framework que os testes de iOS usavam desde 2013. Ele
é o equivalente iOS dos *testes locais* da lição 14: rápidos, numerosos e cegos para tudo o que o
app desenha.

A imagem a trocar é a do Swift Testing como o novo XCTest, que um dia vai testar tudo. No momento em
que este curso foi escrito, ele **não roda testes de interface de jeito nenhum**. O próprio diálogo
de projeto novo do Xcode oferece "Swift Testing with XCTest UI Tests", e a segunda metade dessa
frase é a seção 04. Então um projeto iOS de hoje carrega os dois: Swift Testing para a lógica,
XCTest para as telas.

## A lógica do Tickets, em Swift

Um Tickets para iOS precisaria das mesmas regras do Android: ler a lista do boxoffice, escrever um
preço a partir de centavos inteiros, escrever uma data como o teatro a anuncia. Postas num **pacote
Swift** próprio, essas regras podem ser testadas sem o app e sem simulador. Já que o Swift 6 roda em outros lugares
também, podem ser testadas até sem Mac. O pacote fica numa pasta `ios/TicketsCore` do seu projeto boxoffice.

O manifesto nomeia uma biblioteca e os testes dela. Salve como `ios/TicketsCore/Package.swift`:

```swift
// swift-tools-version: 6.0
// ios/TicketsCore/Package.swift
import PackageDescription

let package = Package(
    name: "TicketsCore",
    targets: [
        .target(name: "TicketsCore"),
        .testTarget(name: "TicketsCoreTests", dependencies: ["TicketsCore"]),
    ]
)
```

As regras, as mesmas três do `Shows.kt` da lição 14. Salve como
`ios/TicketsCore/Sources/TicketsCore/Show.swift`:

```swift
// ios/TicketsCore/Sources/TicketsCore/Show.swift
import Foundation

/// A show as boxoffice describes it, and the two lines a screen prints from it.
public struct Show: Decodable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let startsAt: String
    public let priceCents: Int
    public let seatsLeft: Int

    enum CodingKeys: String, CodingKey {
        case id, title
        case startsAt = "starts_at"
        case priceCents = "price_cents"
        case seatsLeft = "seats_left"
    }

    /// "R$ 80,00", from whole cents and never through a floating-point number.
    public var price: String {
        let cents = priceCents % 100
        return "R$ \(priceCents / 100)," + (cents < 10 ? "0" : "") + "\(cents)"
    }

    /// "2026-11-06T20:00:00-03:00" becomes "06/11 20:00", the time as the theatre states it.
    public var time: String {
        let c = Array(startsAt)
        return String(c[8...9]) + "/" + String(c[5...6]) + " " + String(c[11...15])
    }
}

/// The body of GET /v1/shows.
public enum ShowList {
    struct Body: Decodable {
        let shows: [Show]
    }

    public static func parse(_ body: Data) throws -> [Show] {
        try JSONDecoder().decode(Body.self, from: body).shows
    }
}
```

`CodingKeys` liga o `starts_at` do boxoffice ao `startsAt` do Swift. O preço é montado a partir de
dois números inteiros, pelo motivo que a lição 14 deu: `6500 / 100.0` passa por um número de ponto
flutuante, e um centavo pode se perder no caminho.

Os testes. Salve como `ios/TicketsCore/Tests/TicketsCoreTests/ShowTests.swift`:

```swift
// ios/TicketsCore/Tests/TicketsCoreTests/ShowTests.swift
import Foundation
import Testing
@testable import TicketsCore

let pagador = Show(id: "sh-103", title: "O Pagador de Promessas",
                   startsAt: "2026-11-08T18:00:00-03:00", priceCents: 6500, seatsLeft: 4)

@Test func priceIsInReais() {
    #expect(pagador.price == "R$ 65,00")
}

@Test("a price keeps every cent", arguments: [
    (8000, "R$ 80,00"),
    (8005, "R$ 80,05"),
    (1999, "R$ 19,99"),
    (5, "R$ 0,05"),
])
func price(cents: Int, shown: String) {
    let show = Show(id: "sh-x", title: "x", startsAt: pagador.startsAt, priceCents: cents, seatsLeft: 1)
    #expect(show.price == shown)
}

@Test func timeIsTheTheatres() {
    #expect(pagador.time == "08/11 18:00")
}

@Test func theListIsReadFromBoxoffice() throws {
    let body = Data(#"{"shows":[{"id":"sh-103","title":"O Pagador de Promessas","starts_at":"2026-11-08T18:00:00-03:00","price_cents":6500,"seats_left":4}]}"#.utf8)
    let shows = try ShowList.parse(body)
    let first = try #require(shows.first)
    #expect(first == pagador)
}

@Test func aBodyWithoutShowsIsRefused() {
    #expect(throws: DecodingError.self) {
        try ShowList.parse(Data("{}".utf8))
    }
}
```

## Lendo os testes

```schooling-example
{
 "language": "swift",
 "file": "ShowTests.swift",
 "parts": [
  {
   "code": "import Testing\n@testable import TicketsCore",
   "note": "`Testing` é o framework. `@testable` deixa os testes enxergarem o que o pacote mantém interno, como o inicializador que monta um `Show` à mão."
  },
  {
   "code": "@Test func priceIsInReais() {\n    #expect(pagador.price == \"R$ 65,00\")\n}",
   "note": "Um teste é qualquer função marcada com `@Test`: nenhuma classe para herdar, nenhum nome pelo qual precise começar. `#expect` recebe uma expressão Swift comum e, quando ela é falsa, informa os dois lados do `==`, então a falha diz qual era o preço."
  },
  {
   "code": "@Test(\"a price keeps every cent\", arguments: [\n    (8000, \"R$ 80,00\"),\n    (8005, \"R$ 80,05\"),\n    (1999, \"R$ 19,99\"),\n    (5, \"R$ 0,05\"),\n])\nfunc price(cents: Int, shown: String) {",
   "note": "Um teste **parametrizado**: uma função, rodada uma vez por par, cada execução informada separadamente. Os pares são os limites que quem testa escolheria para dinheiro: um preço redondo, um centavo, noventa e nove centavos e menos de um real."
  },
  {
   "code": "    let shows = try ShowList.parse(body)\n    let first = try #require(shows.first)\n    #expect(first == pagador)",
   "note": "`shows.first` é um opcional: pode não haver primeiro espetáculo. `#require` o desembrulha ou para o teste ali, porque toda linha depois dele estaria verificando nada. Use `#require` onde o resto do teste depende da resposta, e `#expect` em todo o resto."
  },
  {
   "code": "@Test func aBodyWithoutShowsIsRefused() {\n    #expect(throws: DecodingError.self) {\n        try ShowList.parse(Data(\"{}\".utf8))\n    }\n}",
   "note": "O caso negativo: um corpo sem `shows` precisa ser recusado, não lido como lista vazia. `#expect(throws:)` só passa se o código de dentro lançar esse tipo de erro. A lição 2 tirou casos negativos como este do contrato do boxoffice."
  }
 ]
}
```

`#expect` e `#require` são as duas metades do que o JUnit chama de asserção, e vale guardar essa
divisão para todo framework deste curso. Uma verificação que falha e deixa o teste continuar informa
**todos** os campos errados de um espetáculo numa execução só. Uma verificação que para só está
certa onde continuar informaria bobagem, como os campos de um espetáculo que não existe.

## Rodando

Da pasta do pacote, `ios/TicketsCore`, o comando é `swift test`, num Mac ou em qualquer computador
com Swift 6. No Xcode, abrir o `Package.swift` mostra os testes no *Test navigator* com um botão ao
lado de cada um. A seção 05 diz mais. **Estes testes não foram rodados para este curso.** A máquina
de gravação não conseguiu baixar o toolchain do Swift, e a seção 02 diz o que isso significa para
tudo nesta lição.
