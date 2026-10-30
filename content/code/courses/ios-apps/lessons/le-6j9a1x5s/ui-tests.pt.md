---
title: Testes de interface, o app dirigido de fora
version: 1
---

**Um teste de interface abre o app de verdade e o usa como uma pessoa usaria: acha um botão pelo que o
botão diz, toca nele e confere o que aparece.** Ele roda num processo separado, não sabe nada do código
do app e só vê o que a acessibilidade expõe. Isso faz dele o único teste que pega uma tela que compila,
passa em todo teste unitário e mesmo assim não dá para usar. Também o faz lento e o mais fácil de
quebrar, então um projeto mantém poucos. Nada nesta seção foi executado: testes de interface precisam
do Xcode e de um simulador. Ela foi escrita a partir da documentação da Apple para o `XCUIApplication` e
o `XCUIElement`, lida em 30 de outubro de 2026.

```swift
// PlannerUITests/AddSessionUITests.swift
import XCTest

final class AddSessionUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testAddingASessionShowsItInTheWeek() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.buttons["SQL Databases"].tap()
        app.buttons["Add session"].tap()
        let minutes = app.textFields["Minutes"]
        minutes.tap()
        minutes.typeText("45")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["45 minutes"].waitForExistence(timeout: 2))
    }
}
```

**O teste acha os elementos pelos rótulos de acessibilidade**, os que a aula 19 escreveu. Um botão
rotulado para o VoiceOver é um botão que um teste de interface acha; um `Text` tocável da aula 19,
seção 03, é invisível para os dois. Onde um rótulo não é estável, uma frase que muda com o idioma, o
`.accessibilityIdentifier("addSession")` do SwiftUI dá ao elemento um nome para testes que o VoiceOver
nunca lê.

## Três coisas que fazem os testes de interface valerem a pena

- **Comece de um estado conhecido.** O `launchArguments` chega ao app, e o app procura `-ui-testing` ao
  abrir e carrega um plano fixo em vez do da pessoa. Sem isso, um teste de interface depende do que o
  simulador ficou guardando da última execução.
- **Espere, não durma.** O `waitForExistence(timeout:)` volta assim que o elemento aparece e falha
  depois do tempo limite. Um sleep fixo ou é curto demais numa máquina lenta ou é tempo perdido numa
  rápida.
- **`continueAfterFailure = false`.** Depois de um toque que falhou, todo passo seguinte falha pelo
  mesmo motivo, e o relatório enterra a primeira falha embaixo das outras.

**Mantenha poucos fluxos, e importantes**: acrescentar uma sessão, marcar uma como feita, o total da
semana mudando. Tudo o que é aritmética já é um teste unitário no pacote, onde roda em milissegundos em
qualquer computador. Um teste de interface que confere uma soma confere devagar, e só num Mac.
