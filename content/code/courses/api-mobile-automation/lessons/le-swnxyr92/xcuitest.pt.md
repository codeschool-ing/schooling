---
title: XCUITest, o app conduzido por um segundo processo
version: 1
---

**Um teste XCUITest não roda dentro do app; ele roda num programa próprio e conduz o app por
fora.** O Xcode compila os testes de interface num app *executor* separado e o instala no simulador
ao lado do seu. O executor abre o seu app e age sobre ele pela camada de acessibilidade do iOS. Ele
encontra o que está na tela, toca e lê, do jeito que uma pessoa com leitor de tela faria. O
XCUITest é a metade de teste de interface do XCTest, da própria Apple desde 2015.

É tentador pensar nele como o Espresso da Apple, já que os dois são a ferramenta nativa de quem é
dono da plataforma. No que mais importa, ele é o contrário. O Espresso divide o processo com o app e
alcança os objetos dele, como a lição 16 mostrou, enquanto **um teste XCUITest só vê a tela**. Nisso ele fica mais
perto do Appium, da lição 15, e de fato o driver iOS do Appium é construído sobre ele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"No Mac, o Xcode ou o xcodebuild compila, instala e inicia os testes. Dentro do simulador há dois processos: o app executor, TicketsUITests, e o próprio Tickets. O executor só alcança o app pela camada de acessibilidade, a árvore do que está na tela.\"><defs><marker id=\"f18two-processes-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"660\" height=\"210\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"34\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o Mac</text><rect x=\"36\" y=\"118\" width=\"140\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"106\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Xcode</text><text x=\"106\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">xcodebuild</text><rect x=\"210\" y=\"56\" width=\"455\" height=\"168\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"224\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o simulador</text><rect x=\"226\" y=\"96\" width=\"160\" height=\"110\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"306\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">um processo</text><rect x=\"238\" y=\"128\" width=\"136\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"306\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o app executor</text><text x=\"306\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">TicketsUITests</text><rect x=\"408\" y=\"132\" width=\"104\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"460\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">acessibilidade</text><text x=\"460\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a árvore da tela</text><rect x=\"532\" y=\"96\" width=\"120\" height=\"110\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"592\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">outro processo</text><rect x=\"542\" y=\"128\" width=\"100\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"592\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Tickets</text><text x=\"592\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o app</text><line x1=\"176\" y1=\"143\" x2=\"236\" y2=\"156\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f18two-processes-ah)\"></line><line x1=\"374\" y1=\"156\" x2=\"406\" y2=\"156\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f18two-processes-ah)\"></line><line x1=\"512\" y1=\"156\" x2=\"540\" y2=\"156\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f18two-processes-ah)\"></line><text x=\"130\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">compila, instala, inicia</text><text x=\"350\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o teste age sobre o que a tela mostra, e não alcança nenhuma variável do app</text></svg>", "caption": "Um teste XCUITest roda num app executor próprio, ao lado do app, e o alcança pela acessibilidade, como o Appium faz.", "same": ["Tickets", "Xcode"]}
```

## Dizer algo ao app

Estando de fora, o teste não consegue mudar uma variável do app como a lição 16 mudou o
`Shows.baseUrl`. O que ele pode é abrir o app com **argumentos de inicialização** e **variáveis de
ambiente**, que o app lê ao iniciar. O teste abaixo define `BOXOFFICE_URL`. Quem desenvolve o app
o lê numa linha própria e o usa no lugar do endereço com que o app é distribuído. Essa linha é uma
promessa entre quem constrói o app e quem o testa, como os ids da lição 14.

O endereço é `localhost`, e no iOS isso está certo. **O simulador é um programa no Mac e divide a
rede do Mac**, então `localhost:8080` dentro dele é o boxoffice no Mac. Um emulador Android
precisava de `10.0.2.2` na lição 14, e a lição 19 diz por que os dois diferem. O app ainda precisa
da permissão da Apple para falar HTTP puro. O iOS o recusa por padrão, por uma regra chamada *App
Transport Security*. Uma exceção para endereços locais vai nas configurações do app, o equivalente
do arquivo de segurança de rede da lição 14.

## Como o app dá nome aos elementos

**O XCUITest encontra um elemento pelo identificador de acessibilidade** (accessibility
identifier), que quem desenvolve define no código do app. É o equivalente iOS do resource id do
Android. O Tickets para iOS não é construído neste curso. Então aqui está só a parte que quem testa
precisa ver, das views SwiftUI do app, e não um arquivo para salvar:

```swift
// the list: one button per show, named by the show's id
List(shows, id: \.id) { show in
    Button { selected = show } label: {
        VStack(alignment: .leading) {
            Text(show.title)
            Text("\(show.time) · \(show.price)")
        }
    }
    .accessibilityIdentifier("show-\(show.id)")
}

// the show's screen
VStack(alignment: .leading) {
    Text(show.title).font(.title).accessibilityIdentifier("title")
    Text(show.time).accessibilityIdentifier("time")
    Text(show.price).accessibilityIdentifier("price")
    Text("\(show.seatsLeft) seats left").accessibilityIdentifier("seats")
}
```

Duas diferenças em relação ao app Android merecem atenção. Cada linha da lista leva o nome do seu
espetáculo, `show-sh-103`, então um teste pode abrir *O Pagador de Promessas* pelo nome em vez de
como a terceira linha. Isso é melhor que a posição da lição 15. É também o caso contra o qual a
lição 15 alertou: **dois apps que dão nomes diferentes às coisas**. Um mesmo teste Appium não
conduz os dois sem uma tabela que traduza um nome no outro.

O colchete numa consulta, `app.buttons["show-sh-103"]`, é comparado com o identificador e também com
o rótulo (label) do elemento, o texto que ele mostra. Então `app.buttons["Refresh"]` também encontra
o botão. É a armadilha da lição 14 de novo: falha no dia em que a palavra muda, ou em que o
celular está em português.

## O teste

Os testes de interface pertencem ao projeto Xcode do app, no alvo de testes de interface dele. Salve
como `ios/Tickets/TicketsUITests/TicketsUITests.swift`:

```swift
// ios/Tickets/TicketsUITests/TicketsUITests.swift
import XCTest

final class TicketsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["BOXOFFICE_URL"] = "http://localhost:8080"
        app.launch()
        return app
    }

    @MainActor
    func testTheListHasEveryShow() throws {
        let app = launch()
        let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'show-'"))
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 15))
        XCTAssertEqual(rows.count, 3)
    }

    @MainActor
    func testAShowOpensWithItsSeats() throws {
        let app = launch()
        let row = app.buttons["show-sh-103"]
        XCTAssertTrue(row.waitForExistence(timeout: 15))
        row.tap()

        let seats = app.staticTexts["seats"]
        XCTAssertTrue(seats.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["title"].label, "O Pagador de Promessas")
        XCTAssertTrue(seats.label.hasSuffix(" seats left"), seats.label)
    }
}
```

```schooling-example
{
 "language": "swift",
 "file": "TicketsUITests.swift",
 "parts": [
  {
   "code": "final class TicketsUITests: XCTestCase {\n    override func setUpWithError() throws {\n        continueAfterFailure = false\n    }",
   "note": "O formato do XCTest: uma classe cujos métodos que começam com `test` são os testes, e `setUpWithError` antes de cada um. `continueAfterFailure = false` para um teste de interface na primeira falha, já que todo toque depois dela age sobre uma tela que não é a que o teste espera."
  },
  {
   "code": "    @MainActor\n    private func launch() -> XCUIApplication {\n        let app = XCUIApplication()\n        app.launchEnvironment[\"BOXOFFICE_URL\"] = \"http://localhost:8080\"\n        app.launch()\n        return app\n    }",
   "note": "`XCUIApplication` é o app sob teste, visto de fora. O ambiente é definido antes de `launch()`, que abre o app do zero para cada teste. `@MainActor` está ali porque o próprio modelo do Xcode marca assim os testes de interface: as chamadas XCUI rodam na thread principal."
  },
  {
   "code": "        let rows = app.buttons.matching(NSPredicate(format: \"identifier BEGINSWITH 'show-'\"))\n        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 15))\n        XCTAssertEqual(rows.count, 3)",
   "note": "Uma **consulta** descreve elementos e só os encontra quando perguntada. `waitForExistence` espera até 15 segundos pela lista carregar e responde verdadeiro ou falso; sozinha ela não falha, e é por isso que fica dentro de `XCTAssertTrue`."
  },
  {
   "code": "        let row = app.buttons[\"show-sh-103\"]\n        XCTAssertTrue(row.waitForExistence(timeout: 15))\n        row.tap()",
   "note": "A linha pelo identificador, esperada e tocada. O XCUITest espera o app sossegar antes de um toque, como o Espresso espera a thread principal, mas não sabe nada de uma requisição em andamento: a lista chegando do boxoffice é exatamente isso, então a espera é escrita."
  },
  {
   "code": "        let seats = app.staticTexts[\"seats\"]\n        XCTAssertTrue(seats.waitForExistence(timeout: 5))\n        XCTAssertEqual(app.staticTexts[\"title\"].label, \"O Pagador de Promessas\")\n        XCTAssertTrue(seats.label.hasSuffix(\" seats left\"), seats.label)",
   "note": "A tela do espetáculo. `label` é o texto que o elemento mostra. Os lugares são conferidos pelo formato, não pelo número: a lição 15 perguntou o número ao boxoffice, e a versão em Swift faria o mesmo com uma requisição própria, deixada de fora aqui para o teste ficar curto."
  }
 ]
}
```

**Este teste não foi compilado nem rodado para este curso**, que não tem Mac. A seção 02 diz isso
para a lição inteira. Ele foi escrito pela API documentada do XCTest, e o app iOS que ele testa só
existe como o fragmento acima.
