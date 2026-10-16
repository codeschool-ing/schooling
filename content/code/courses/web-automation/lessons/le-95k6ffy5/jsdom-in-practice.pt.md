---
title: O jsdom, rodando contra a loja
version: 1
---

**O jsdom é o DOM e o padrão HTML, implementados em JavaScript para o Node.** Não há navegador
por trás dele. É o único navegador simulado em uso amplo hoje, e a maioria das pessoas o roda de
segunda mão: o ambiente de testes `jsdom` do Jest é um pacote, `jest-environment-jsdom`, construído
sobre ele.

```
ana@laptop:~/quitanda$ npm view jest-environment-jsdom version dependencies.jsdom
version = '30.5.2'
dependencies.jsdom = '^26.1.0'
```

Ou seja, quem usa o Jest hoje roda o jsdom 26, seja qual for a versão mais nova. Esta seção instala
o próprio jsdom, na 30.1.2, e aponta para a loja.

## Instalando

O `package.json` do projeto ganha uma linha. Salve-o como `package.json`:

```json
{
  "name": "quitanda",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node app/server.js",
    "test": "playwright test"
  },
  "devDependencies": {
    "@playwright/test": "1.56.0",
    "cypress": "16.1.1",
    "jsdom": "30.1.2",
    "puppeteer": "25.13.0",
    "selenium-webdriver": "4.51.0"
  }
}
```

```
ana@laptop:~/quitanda$ npm install
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: 'jsdom@30.1.2',
npm warn EBADENGINE   required: { node: '^22.22.2 || ^24.15.0 || >=26.0.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@asamuzakjp/css-color@7.1.5',
npm warn EBADENGINE   required: { node: '^22.22.2 || ^24.15.0 || >=26.0.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@asamuzakjp/dom-selector@9.2.4',
npm warn EBADENGINE   required: { node: '^22.22.2 || ^24.15.0 || >=26.0.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: 'w3c-xmlserializer@6.0.0',
npm warn EBADENGINE   required: { node: '^22.22.2 || ^24.15.0 || >=26.0.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }

added 248 packages, and audited 249 packages in 9s

64 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

**Leia os avisos antes da última linha.** O jsdom 30.1.2 declara quais versões do Node suporta, e
o Node da aula 1 fica logo abaixo delas:

```
ana@laptop:~/quitanda$ npm view jsdom@30.1.2 engines
{ node: '^22.22.2 || ^24.15.0 || >=26.0.0' }
```

O 22.22.0 está a duas versões de correção do 22.22.2. O npm avisa e instala mesmo assim, e tudo
nesta aula rodou no 22.22.0 sem nenhum erro do jsdom. Um aviso desses ainda é uma afirmação dos
autores de que não testam mais a sua combinação, então na sua máquina a solução é atualizar o Node
dentro da linha 22.

## A página inicial, aberta como um navegador abriria

Crie uma pasta `simulated` para os scripts desta aula. O primeiro abre a página inicial, espera um
segundo pelo `app.js` e conta os cards. Salve-o como `simulated/home.mjs`:

```javascript
// The shop's home page in jsdom: no browser, only Node.
import { JSDOM } from 'jsdom';

const dom = await JSDOM.fromURL('http://localhost:3000/', {
  runScripts: 'dangerously',
  resources: 'usable',
});
const { document } = dom.window;

await new Promise((resolve) => setTimeout(resolve, 1000));
console.log(`cards: ${document.querySelectorAll('#products li').length}`);
dom.window.close();
```

**As duas opções vêm desligadas, e os nomes delas são um aviso.** Por padrão o jsdom analisa o HTML
e não faz mais nada: nenhum `<script>` roda e nada que a página referencia é buscado.

- `runScripts: 'dangerously'` roda os scripts da página. O README do jsdom explica o advérbio,
  "perigosamente": a caixa de areia dele "is not foolproof", não é à prova de falhas, e um script
  que se esforce consegue chegar ao Node, e do Node ao resto da sua máquina. Um navegador de verdade
  mantém a página longe dos seus arquivos; o jsdom não consegue prometer isso. Aqui é seguro porque
  a página é a sua própria loja em `localhost`. Apontado para uma página que outra pessoa controla,
  é rodar o código dela com as suas permissões.
- `resources: 'usable'` deixa o jsdom buscar o que a página referencia: scripts em
  `<script src>`, folhas de estilo em `<link rel="stylesheet">`, frames. Sem isso, o `app.js` nem
  chega a ser baixado. Imagens pedem um pacote a mais, o `canvas`, que esta aula não instala.

O `fromURL` busca a página e diz ao jsdom o endereço dela, para que `/app.js` e `/style.css` sejam
resolvidos a partir de `http://localhost:3000`. Com a loja rodando:

```
ana@laptop:~/quitanda$ node simulated/home.mjs
http://localhost:3000/app.js:4
  const response = await fetch(url, options);
                   ^

ReferenceError: fetch is not defined
    at getJson (http://localhost:3000/app.js:4:20)
    at load (http://localhost:3000/app.js:38:26)
    at http://localhost:3000/app.js:51:1
    at Script.runInContext (node:vm:149:12)
    at Object.runInContext (node:vm:301:6)
    at processJavaScript (/home/ana/quitanda/node_modules/jsdom/lib/jsdom/living/nodes/HTMLScriptElement-impl.js:274:10)
    at HTMLScriptElementImpl._innerEval (/home/ana/quitanda/node_modules/jsdom/lib/jsdom/living/nodes/HTMLScriptElement-impl.js:207:5)
    at onLoadExternalScript (/home/ana/quitanda/node_modules/jsdom/lib/jsdom/living/nodes/HTMLScriptElement-impl.js:107:12)
    at onLoadWrapped (/home/ana/quitanda/node_modules/jsdom/lib/jsdom/browser/resources/per-document-resource-loader.js:84:33)
    at Object.check (/home/ana/quitanda/node_modules/jsdom/lib/jsdom/browser/resources/resource-queue.js:76:23)

Node.js v22.22.0
```

**O jsdom 30.1.2 não tem `fetch`.** O Node 22 tem um, e todo script deste curso o usou; a janela
que o jsdom monta para a página não tem, então a primeira linha de `getJson` lança um erro. O
programa então termina, e essa parte é coisa do Node: `load()` é uma função `async`, a falha dela
virou uma promise rejeitada que ninguém tratou, e o Node encerra um programa com uma rejeição não
tratada. Um navegador teria registrado o erro no console da aula 1 e seguido desenhando uma loja
vazia.

## Emprestando um fetch à página

O README do jsdom sugere o contorno: uma opção chamada `beforeParse`, uma função que recebe a
janela antes de os scripts da página rodarem, "for example adding shims for web platform APIs jsdom
does not support", por exemplo para acrescentar substitutos de APIs que o jsdom não suporta. Um
**shim** é esse substituto que você escreve para uma API que falta. Este passa as requisições da
página para o `fetch` do Node, depois de transformar um endereço relativo como `/api/products` num
completo. Todo script daqui em diante abre a loja do mesmo jeito, então ele vai num módulo próprio,
com uma pequena espera ao lado. Salve-o como `simulated/shop.mjs`:

```javascript
// Open a page of the shop in jsdom: the HTML parsed, its scripts run,
// and nothing drawn.
import { JSDOM } from 'jsdom';

export const address = 'http://localhost:3000';

export async function open(path) {
  const dom = await JSDOM.fromURL(address + path, {
    runScripts: 'dangerously',
    resources: 'usable',
    // jsdom has no fetch, and app.js needs one: lend the page Node's.
    beforeParse(window) {
      window.fetch = (url, init) => fetch(new URL(url, window.location.href), init);
    },
  });
  return dom.window;
}

// Check fn every 20 ms until it returns true, for at most five seconds.
export async function until(fn) {
  const deadline = Date.now() + 5000;
  while (!fn()) {
    if (Date.now() > deadline) throw new Error('until: still false after 5 s');
    await new Promise((resolve) => setTimeout(resolve, 20));
  }
}
```

**O `until` é uma espera escrita à mão**, como a do Puppeteer na aula 11: o jsdom não espera
sozinho, porque não faz ideia do que você vai conferir. A página inicial o usa duas vezes, para a
lista deixar de estar ocupada e para a contagem mudar depois de um clique. Salve-o como
`simulated/home.mjs`:

```javascript
// The shop's home page in jsdom, with a fetch to draw the cards.
import { address, open, until } from './shop.mjs';

await fetch(address + '/api/reset', { method: 'POST' });
const window = await open('/');
const { document } = window;

const list = document.querySelector('#products');
await until(() => list.getAttribute('aria-busy') === 'false');
console.log(`cards: ${list.children.length}`);

document.querySelector('[data-testid=product-banana] button').click();
const count = document.querySelector('[data-testid=basket-count]');
await until(() => count.textContent === '1');
console.log(`basket: ${count.textContent}, toast: ${document.querySelector('.toast').textContent}`);
window.close();
```

```
ana@laptop:~/quitanda$ node simulated/home.mjs
cards: 8
basket: 1, toast: Added Banana
```

**Oito cards, uma banana na cesta e o texto do aviso**, a partir do mesmo `app.js` que o Chromium
roda. O clique rodou o listener do botão, que mandou `POST /api/basket` pelo shim e escreveu a
resposta no cabeçalho.

Repare no que o shim mudou. As requisições não passam mais por nada que o jsdom escreveu: quem as
manda é o `fetch` do Node, sem os cookies da página e sem nenhuma das regras que um navegador aplica
entre um site e outro. **Uma verificação que passa por um shim testou o shim**, o que serve para
contar cards e não serve para nada sobre como um navegador faz requisições. A próxima seção pergunta
ao jsdom o que ele não consegue responder de jeito nenhum.
