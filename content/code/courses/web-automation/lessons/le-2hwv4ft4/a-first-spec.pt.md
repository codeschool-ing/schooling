---
title: Um primeiro spec, e a fila por trás dele
version: 1
---

Um arquivo de teste do Cypress se chama **spec**, e tem a forma que o Mocha deu aos testes em
JavaScript antes de o Cypress existir: `describe` nomeia um grupo, `it` nomeia um teste, e
`beforeEach` roda antes de cada um. O Cypress traz o Mocha para a estrutura e o Chai para as
asserções. Todo passo dentro de um teste é um comando de um único objeto global, `cy`.

O spec abaixo faz o que o teste de fumaça da aula 1 fazia, o título e os oito produtos, e depois
põe algo na cesta, coisa que o teste de fumaça nunca tocou. Crie a pasta antes, a partir do projeto:

```sh
mkdir -p cypress/e2e
```

Salve-o como `cypress/e2e/shop.cy.js`:

```schooling-example
{"language": "javascript", "file": "cypress/e2e/shop.cy.js", "parts": [{"code": "describe('the shop', () => {\n  beforeEach(() => {\n    cy.request('POST', '/api/reset');\n    cy.visit('/');\n  });", "note": "`describe`, `it` e `cy` são globais que o executor fornece, então o arquivo não importa nada. `cy.request` pede o reinício ao servidor pelo lado Node do Cypress, e não pela página; `cy.visit` então carrega a loja no frame da aplicação. Os dois rodam antes de cada teste, e assim cada um começa com a cesta vazia."}, {"code": "\n  it('opens and lists its fruit', () => {\n    cy.contains('h1', 'Fruit of the season').should('be.visible');\n    cy.get('#products li').should('have.length', 8);\n  });", "note": "`cy.contains` acha um elemento pelo texto, aqui o único `h1` que o diz. `cy.get` recebe um seletor CSS. Cada `should` é tentado de novo, junto com a consulta à frente dele, até passar ou até passarem quatro segundos."}, {"code": "\n  it('adds a banana to the basket', () => {\n    cy.get('[data-testid=product-banana]')\n      .contains('button', 'Add to basket')\n      .click();\n    cy.get('[data-testid=basket-count]').should('have.text', '1');\n    cy.get('.toast').should('have.text', 'Added Banana');\n  });", "note": "Uma corrente vai estreitando: o cartão da banana, depois o botão dentro dele cujo texto é *Add to basket*, depois um clique. As duas verificações seguintes esperam a requisição que o clique disparou voltar e redesenhar o cabeçalho."}, {"code": "\n  it('counts one more than before', () => {\n    cy.get('[data-testid=basket-count]').then(($count) => {\n      const before = Number($count.text());\n      cy.get('[data-testid=product-mango]').contains('button', 'Add to basket').click();\n      cy.get('[data-testid=basket-count]').should('have.text', String(before + 1));\n    });\n  });\n});", "note": "Para usar um valor da página, pegue-o dentro de `.then()`, que roda quando a fila chega nele e entrega o elemento que o Cypress achou, embrulhado em jQuery. Os comandos escritos ali dentro entram na fila nesse ponto. A próxima seção explica por que a versão óbvia, sem `.then()`, não tem como funcionar."}]}
```

**Cada comando dele foi conferido com as definições de tipos que vêm com o Cypress 16.1.1, e nenhum
foi executado.** Na sua máquina, com a loja iniciada em outro terminal, isto roda o spec sem janela,
no Electron, e imprime um resumo:

```sh
npx cypress run --spec cypress/e2e/shop.cy.js
```

e `npx cypress open` abre o executor numa janela, onde você escolhe **E2E Testing**, um navegador e
depois o spec. Na máquina de onde vêm estas aulas, sem o binário, o primeiro comando imprimiu isto e
parou, antes de qualquer teste:

```
%%CAP cypress-run-missing%%
```

É a mesma mensagem que o `cypress verify` deu na seção anterior; é tudo o que uma execução sem o
binário produz.

## O comando que ainda não aconteceu

O equívoco que todo mundo traz do JavaScript comum, ou do Playwright, é achar que uma linha como
`cy.get(...)` encontra um elemento e o devolve. Então a primeira tentativa de ler a contagem da
cesta fica assim:

```javascript
// This does not work: cy.get returns a chain, not the element.
const count = cy.get('[data-testid=basket-count]');
if (count.text() === '0') {
  cy.log('the basket is empty');
}
```

**Um comando do Cypress não roda quando você o chama. Ele entra numa fila, e a chamada retorna na
hora.** A sua função de teste roda de cima a baixo num instante, escrevendo a lista; só depois que
ela retorna o Cypress tira o primeiro comando da fila e o executa, depois o próximo. Então `count`
não é o elemento, nem uma promessa de elemento: é a corrente à qual o próximo comando vai se ligar.
Uma corrente não tem método `text()`, então `count.text()` lança um `TypeError` enquanto a função de
teste ainda está escrevendo a lista, antes de qualquer comando rodar.

`await` também não ajuda. A documentação é explícita: comandos não são promessas, e um `await` na
frente de um deles não espera nada de útil. O jeito de usar um valor da página é o que o terceiro
teste do spec mostra: `.then()`, cuja função roda quando a fila chega nela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Em cima, três comandos, cy.visit, cy.get e should, cada um marcado na fila: chamá-los só os acrescenta a uma lista. Embaixo, uma linha do tempo da fila rodando: a página carrega, depois o get e sua asserção são tentados seis vezes enquanto a lista está vazia, achando 0, e passam na sétima, achando 8. No fim, uma nota de que falharia em 4 segundos.\"><text x=\"20\" y=\"28\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">1. Sua função roda uma vez e retorna. Nada aconteceu ainda.</text><rect x=\"20\" y=\"42\" width=\"210\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"32\" y=\"64\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cy.visit('/')</text><text x=\"32\" y=\"94\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">na fila</text><rect x=\"250\" y=\"42\" width=\"210\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"262\" y=\"64\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cy.get('#products li')</text><text x=\"262\" y=\"94\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">na fila</text><rect x=\"480\" y=\"42\" width=\"210\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"492\" y=\"64\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.should('have.length', 8)</text><text x=\"492\" y=\"94\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">na fila</text><text x=\"20\" y=\"140\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">2. Depois o Cypress executa a fila, um comando por vez.</text><path d=\"M20 200 L700 200\" stroke=\"var(--wire)\"></path><rect x=\"20\" y=\"160\" width=\"120\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"30\" y=\"181\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">página carregada</text><rect x=\"160\" y=\"160\" width=\"36\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"178\" y=\"181\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0</text><rect x=\"204\" y=\"160\" width=\"36\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"222\" y=\"181\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0</text><rect x=\"248\" y=\"160\" width=\"36\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"266\" y=\"181\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0</text><rect x=\"292\" y=\"160\" width=\"36\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"310\" y=\"181\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0</text><rect x=\"336\" y=\"160\" width=\"36\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"354\" y=\"181\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0</text><rect x=\"380\" y=\"160\" width=\"36\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"398\" y=\"181\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0</text><rect x=\"424\" y=\"160\" width=\"36\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"442\" y=\"181\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">8</text><text x=\"160\" y=\"220\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">get e should, tentados de novo</text><text x=\"424\" y=\"220\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">8 achados: passa,</text><text x=\"424\" y=\"237\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">próximo comando</text><text x=\"700\" y=\"181\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ou falha em 4 s</text></svg>", "caption": "A função de teste só escreve a lista. A espera acontece depois, dentro da fila, enquanto a lista da página ainda está vazia."}
```

## Por que a fila compensa: uma verificação que tenta de novo

A fila é o que deixa o Cypress repetir. Quando chega em `cy.get('#products li').should('have.length',
8)`, ele procura os itens, testa a asserção e, se ela falhar, **procura de novo e testa de novo**, até
passar ou até acabar o tempo permitido. Esse tempo é `defaultCommandTimeout`, e as definições de
tipos dão o padrão de 4000 milissegundos.

Isso importa nesta loja por causa da brecha que a aula 1 achou no painel Network: a página está na
tela, com a lista vazia, antes de `/api/products` responder. Uma verificação que olhasse uma vez, no
momento errado, não acharia nada. Esta não acha nada várias vezes, e depois acha oito. A aula 3 é
construída em torno dessa brecha, e a aula 13 compara este tipo de espera com os outros.

Dois detalhes impedem que a repetição pareça mágica:

- **Só as consultas antes de uma asserção são repetidas com ela.** `cy.get`, `cy.contains` e
  `.find` são consultas. Uma ação como `.click()` não é repetida: ela espera até o elemento poder
  ser clicado e clica uma vez. Um teste que clicasse, falhasse e clicasse de novo poria duas
  bananas na cesta.
- **Repetir não espera uma requisição.** Espera o DOM ficar certo. Quando o que você espera é uma
  resposta do servidor, a próxima seção tem uma ferramenta melhor.

O `expect(locator).toHaveCount(8)` do Playwright, no teste de fumaça da aula 1, também repete. O
que é próprio do Cypress é que a repetição é uma propriedade da fila, e não de um tipo especial de
asserção, então todo `should` se comporta assim sem ninguém pedir.
