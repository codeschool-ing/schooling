---
title: O painel Network, e um robô que o lê
version: 1
---

A aba **Network** lista cada requisição que a página faz, enquanto o painel está aberto: o
endereço, o **status** com que o servidor respondeu, o **tipo** do que foi pedido, o tamanho, quanto
demorou, e uma barra para cada uma numa linha do tempo comum chamada **waterfall** (cascata). Abra-a,
recarregue a loja, e cinco linhas aparecem.

Para quem testa, esse painel responde à pergunta que a tela não responde: **a página pediu a coisa
certa, e o que voltou?** Uma cesta com o total errado é ou uma página que desenhou errado uma
resposta certa ou um servidor que respondeu errado, e a aba Network diz qual em um clique: selecione
a requisição, e a aba **Response** dela mostra exatamente o que o servidor mandou.

## A mesma lista, impressa

Tudo o que o painel mostra vem do navegador, e um programa que conduz o navegador também pode
pedir. Este script abre a loja num Chromium que ninguém está olhando, imprime uma linha para cada
resposta conforme ela chega e imprime o que a página escreve no console, assunto da próxima seção. É
o primeiro programa deste curso que conduz um navegador, e ele usa a biblioteca do Playwright, não o
executor de testes. Salve-o como `look.mjs`:

```javascript
// What the Network and Console panels show, printed by a browser nobody
// is watching. Run it with the shop started: node look.mjs [address]
import { chromium } from '@playwright/test';

const address = process.argv[2] ?? 'http://localhost:3000/';
const browser = await chromium.launch();
const page = await browser.newPage();
const start = Date.now();
const ms = () => String(Date.now() - start).padStart(5) + ' ms';

page.on('response', (response) => {
  const request = response.request();
  const path = new URL(response.url()).pathname;
  console.log(`${ms()}  ${response.status()} ${request.method()} ${path}  (${request.resourceType()})`);
});
page.on('console', (message) => console.log(`${ms()}  console.${message.type()}: ${message.text()}`));
page.on('pageerror', (error) => console.log(`${ms()}  uncaught error: ${error.message}`));

await page.goto(address);
await page.waitForLoadState('networkidle');
await browser.close();
```

Com a loja iniciada num terminal, rode-o em outro:

```
ana@laptop:~/quitanda$ node look.mjs
   10 ms  200 GET /  (document)
   17 ms  200 GET /style.css  (stylesheet)
   19 ms  200 GET /app.js  (script)
   38 ms  200 GET /api/products  (fetch)
   45 ms  200 GET /api/basket  (fetch)
```

As mesmas cinco linhas que o painel mostra, na ordem em que chegaram, com os milissegundos desde
que o script pediu a página. Os seus tempos vão ser outros; a ordem não, e é a ordem que importa:

- **o documento vem primeiro**, porque nada mais é conhecido até ele chegar;
- **a folha de estilos e o script vêm em seguida, juntos**, porque o navegador encontrou os dois ao
  ler o HTML e pediu os dois de uma vez;
- **as duas requisições `fetch` vêm por último**, porque quem as faz é o `app.js`, e o `app.js` não
  pede nada antes de chegar e rodar.

Esse último intervalo é a aula 3 inteira. A página está na tela, vazia, entre o momento em que o
documento chega e o momento em que `/api/products` responde. Na aba Network, a coluna **Initiator**
diz o mesmo de outro jeito: o documento foi pedido por você, o script pelo documento, e os dois
fetches pelo script.

## O que o servidor viu

O outro lado da conversa é o do servidor. Iniciada com `QUITANDA_LOG=1`, a loja imprime cada
requisição que responde, e este é o terminal dela enquanto o `look.mjs` rodou uma vez:

```
ana@laptop:~/quitanda$ QUITANDA_LOG=1 npm start

> start
> node app/server.js

quitanda is listening on http://localhost:3000
GET / 200
GET /style.css 200
GET /app.js 200
GET /api/products 200
GET /api/basket 200
```

As duas listas batem, e nem sempre vão bater. Uma requisição que o navegador lista e o servidor não
foi respondida pelo próprio navegador, a partir do cache, e a aula 4 faz isso acontecer de
propósito. Uma requisição que o servidor registra e o navegador não mostra veio de outra pessoa, e
com uma cesta só para todos, como mostra a aula 15, isso é um problema.

## Três coisas que vale saber no painel

- **Preserve log** mantém a lista quando a página navega. Sem ele, clicar num link que carrega outra
  página apaga as requisições que levaram até ela, que muitas vezes são as que você queria.
- **Disable cache**, enquanto o painel está aberto, faz o navegador pedir tudo ao servidor. A aula 4
  trata de quando um teste deve fazer o mesmo e quando não deve.
- **Copy as cURL**, no menu do botão direito de uma requisição, entrega a requisição como um comando
  que você roda num terminal, que é como um relato de defeito mostra que foi o servidor, e não a
  página, que respondeu errado. A aula 15 de `manual-testing` trata das evidências que um relato
  precisa.
