---
title: Os limites, e de onde vem cada um
version: 1
---

Listas de limites do Cypress são fáceis de achar e difíceis de lembrar, porque parecem arbitrárias.
Não são. **Quase todas são o preço da posição com que esta aula começou**: um teste que roda como
script numa página vive pelas regras dos scripts numa página. Esta seção trata dos quatro que
importam para quem testa, mede o primeiro de verdade e termina com o que o Cypress custa.

## Uma origem por vez

Uma **origem** é o esquema, o host e a porta de um endereço juntos: `http://localhost:3000` é uma. O
navegador deixa um script ler um frame, uma janela ou uma resposta só quando eles vêm da origem do
próprio script. Essa regra, a **política de mesma origem** (*same-origin policy*), é quase tudo o que
impede um site de ler outro aberto no mesmo navegador.

Dá para ver a regra funcionando sem o Cypress. Este script abre a loja, põe dois frames na página,
um de `localhost` e um de `127.0.0.1`, e pergunta o título de cada um duas vezes: uma de um código
que roda dentro da página, e outra do próprio processo do Playwright. Salve-o como `origins.mjs`:

```schooling-example
{"language": "javascript", "file": "origins.mjs", "parts": [{"code": "// One page, two frames: one from the page's own origin and one from\n// another. Run it with the shop started: node origins.mjs\nimport { chromium } from '@playwright/test';\n\nconst browser = await chromium.launch();\nconst page = await browser.newPage();\nawait page.goto('http://localhost:3000/');", "note": "O Playwright abre a loja em `localhost`, como qualquer teste deste curso."}, {"code": "\nawait page.evaluate(async () => {\n  for (const src of ['http://localhost:3000/', 'http://127.0.0.1:3000/']) {\n    const frame = document.createElement('iframe');\n    frame.src = src;\n    document.body.append(frame);\n    await new Promise((loaded) => frame.addEventListener('load', loaded));\n  }\n});", "note": "Um código que roda na página acrescenta dois frames mostrando a mesma loja. `localhost` e `127.0.0.1` chegam ao mesmo servidor, mas o navegador compara origens pelo texto, então o segundo frame é de outra origem."}, {"code": "\nconst inside = await page.evaluate(() =>\n  [...document.querySelectorAll('iframe')].map((frame) => {\n    try {\n      return `${frame.src}  ${frame.contentWindow.document.title}`;\n    } catch (error) {\n      return `${frame.src}  ${error.name}: ${error.message}`;\n    }\n  }));\nconsole.log('asked from inside the page:');\nfor (const line of inside) console.log('  ' + line);", "note": "Ainda dentro da página, o código lê o título de cada frame, do jeito que um teste do Cypress lê qualquer coisa: como um script na página. Um erro é impresso em vez de lançado, para que um frame não esconda o outro."}, {"code": "\nconsole.log('asked from outside, through the driver:');\nfor (const frame of page.frames().slice(1)) {\n  console.log(`  ${frame.url()}  ${await frame.title()}`);\n}\nawait browser.close();", "note": "Depois o Playwright lê os mesmos dois títulos do seu próprio processo, pelo protocolo de depuração do navegador e não pela página."}]}
```

Com a loja iniciada:

```
%%CAP origins%%
```

**O mesmo servidor, a mesma pergunta, respondida uma vez e recusada outra.** De dentro da página, o
frame em `127.0.0.1` é outra origem, e o navegador barra o script com um `SecurityError`. De fora, o
Playwright lê os dois títulos, porque não é um script na página e a regra não é sobre ele. Um teste
do Cypress fica onde a primeira pergunta foi feita.

O Cypress contorna a regra de dois jeitos. O servidor dele entrega o executor no próprio endereço da
aplicação, de modo que o executor e a aplicação compartilham uma origem, e é por isso que testes
comuns nunca esbarram na regra. E quando um teste precisa passar para uma segunda origem, o caso
típico sendo uma página de login em outro domínio, ele envolve esses passos em `cy.origin`:

```javascript
it('opens the shop at a second origin', () => {
  cy.visit('/');
  cy.origin('http://127.0.0.1:3000', () => {
    cy.visit('/');
    cy.get('#products li').should('have.length', 8);
  });
});
```

Os comandos dentro da função rodam naquela origem. **A função é enviada para lá como texto**, então
não pode usar uma variável do teste em volta; um valor de que ela precise tem de entrar pela opção
`args`, que as definições de tipos mostram. É uma regra estranha para JavaScript, e é a política de
mesma origem outra vez, vista de dentro.

## Uma aba, e frames

Um teste do Cypress conduz uma aba. Um link que abre uma aba nova, `target="_blank"`, não abre nada
que o teste possa seguir, e a documentação diz com todas as letras que conduzir várias abas não é
suportado. A resposta comum é verificar para onde o link aponta, ou remover o atributo e segui-lo na
mesma aba. Dois usuários ao mesmo tempo, cada um no seu navegador, fica fora de alcance pelo mesmo
motivo; a aula 10 mostra o Playwright fazendo isso com dois contextos.

Frames ficam parcialmente ao alcance. Não há comando que entre num frame; um teste chega ao
documento de um frame da mesma origem pelo elemento, com `.its('0.contentDocument.body')`, e o frame
de outra origem fica fechado para ele, como a captura acima mostrou para qualquer script.

## Os navegadores que ele conduz

`npx cypress run` usa o **Electron**, que vem dentro do binário, a menos que se diga outra coisa.
`--browser` escolhe um instalado pelo nome: a documentação lista a família do Chrome (Chrome,
Chromium, Edge) e o Firefox. **O Safari não está na lista.** As definições de tipos trazem uma
configuração `experimentalWebKitSupport`, um experimento com o WebKit, o motor por baixo do Safari,
que não é o próprio Safari. O Playwright da aula 10 conduz Chromium, Firefox e WebKit em pé de
igualdade, e a aula 7 de `manual-testing` explica por que o navegador importa. Os testes em si são
JavaScript ou TypeScript; não existe Cypress para Python ou Java.

## Quanto custa

O executor é gratuito: o pacote tem licença MIT, e o próprio `package.json` dele diz isso. A parte
paga é o **Cypress Cloud**, um serviço para onde o executor pode mandar os resultados. Duas opções
do `cypress run` levam até lá, e o texto de ajuda do pacote, que roda sem o binário, diz para que
servem:

```
%%CAP run-help%%
```

`--record` manda a execução para o Cloud, e `--parallel`, que divide os specs entre várias máquinas,
funciona pelo mesmo serviço. Nada neste curso precisa de nenhuma das duas. A aula 19 divide uma
suíte entre workers com o Playwright, que faz isso numa máquina só, sem serviço nenhum. Os preços e a
cota gratuita são a Cypress que define e muda, então não são citados aqui.
