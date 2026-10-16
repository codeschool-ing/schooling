---
title: Montando a loja
version: 1
---

A aplicação que todas as aulas testam é a **quitanda**, uma pequena feira virtual. Ela lista oito
frutas, põe frutas numa cesta e mostra o total em reais. É um programa Node sem dependências,
escrito para este curso e pequeno o bastante para ser lido inteiro, e esta seção e a próxima o
montam.

**Ela tem falhas, de propósito, e cada uma está marcada no código com as palavras *a known flaw,
on purpose*** (uma falha conhecida, de propósito). Uma aplicação que nunca se comporta mal não
ensina nada sobre automação: as aulas sobre localizadores, espera, cache e testes intermitentes
precisam, cada uma, de algo que dê errado de um jeito específico, sempre, para você ver um teste
encontrar o problema. As aulas 3 a 7 acrescentam páginas com as falhas de que tratam.

**E ela reinicia.** Tudo o que a loja sabe fica em memória, e uma requisição a devolve ao estado
inicial. É isso que permite a um teste começar de um estado conhecido, e a aula 15 mostra por que
isso importa mais do que parece.

**Copie cada arquivo com o botão do bloco** em vez de redigitá-lo. Todo arquivo abaixo é salvo
em relação à pasta do projeto.

## As pastas

```sh
mkdir -p ~/quitanda/app/routes ~/quitanda/app/public ~/quitanda/tests
cd ~/quitanda
```

No Windows, no PowerShell, o `mkdir` cria uma pasta por vez e cria as pastas-mãe de que precisa:
rode-o uma vez para cada um dos três caminhos.

## Como o projeto se descreve

O `package.json` é o que o npm lê. Ele dá nome ao projeto, diz que os arquivos JavaScript são
**módulos ES** (a sintaxe `import`, assunto da aula 9 de `javascript`), dá significado a
`npm start` e `npm test` e fixa numa versão exata a única ferramenta que os testes usam, para que as
suas execuções imprimam o que estas aulas imprimem. Salve-o como `package.json`:

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
    "@playwright/test": "1.56.0"
  }
}
```

A configuração que o Playwright lê quando você roda os testes. Ela procura testes em `tests/`,
deixa um teste escrever `page.goto('/')` em vez do endereço inteiro e inicia a própria loja antes
de rodar qualquer coisa, o que poupa um terminal. A aula 10 explica todas as opções do Playwright;
estas são as três de que o curso precisa primeiro. Salve-a como `playwright.config.js`:

```javascript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: 'tests',
  reporter: 'list',
  use: { baseURL: 'http://localhost:3000' },
  // Playwright starts the shop before the tests and stops it after.
  webServer: {
    command: 'npm start',
    url: 'http://localhost:3000/api/products',
    reuseExistingServer: !process.env.CI,
  },
});
```

## O servidor

Dois pequenos ajudantes que toda rota usa: um envia uma resposta, o outro espera alguns
milissegundos, que é como as páginas lentas da loja ficam lentas. Salve-o como `app/http.js`:

```javascript
// What every route needs to answer.
export function send(res, status, body, headers = {}) {
  const json = typeof body !== 'string';
  res.writeHead(status, {
    'Content-Type': json ? 'application/json' : 'text/plain; charset=utf-8',
    ...headers,
  });
  res.end(json ? JSON.stringify(body) : body);
}

export const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
```

Tudo o que a loja sabe, e o `reset()` que a devolve ao início. Os preços são **inteiros em
centavos**, então 590 é R$ 5,90; um preço guardado como fração decimal arredondaria errado em algum
lugar. A `offer` e os `users` são usados pelas aulas 4 e 15. Salve-o como `app/store.js`:

```javascript
// Everything the shop knows lives here, in memory. reset() puts it back the
// way it started, which is what lets a test begin from a known state.
const products = [
  { id: 'banana', name: 'Banana', price: 590, unit: 'dozen' },
  { id: 'mango', name: 'Mango', price: 450, unit: 'each' },
  { id: 'papaya', name: 'Papaya', price: 790, unit: 'each' },
  { id: 'guava', name: 'Guava', price: 1290, unit: 'kg' },
  { id: 'cashew', name: 'Cashew fruit', price: 1590, unit: 'kg' },
  { id: 'passion', name: 'Passion fruit', price: 990, unit: 'kg' },
  { id: 'acerola', name: 'Acerola', price: 1890, unit: 'kg' },
  { id: 'pineapple', name: 'Pineapple', price: 690, unit: 'each' },
];

export const store = {};

export function reset() {
  store.products = products.map((p) => ({ ...p }));
  store.basket = [];
  store.offer = { id: 'mango', price: 390 };
  store.users = new Set();
}

reset();

export function total(basket) {
  return basket.reduce((sum, line) => {
    const product = store.products.find((p) => p.id === line.id);
    return sum + product.price * line.qty;
  }, 0);
}
```

O servidor em si. Ele responde a uma requisição de um de três jeitos: uma rota de `app/routes/`,
se alguma bater; um arquivo de `app/public/`, se existir; e `404` nos demais casos. Todo arquivo que
ele serve leva um `ETag`, uma impressão digital do conteúdo, e `Cache-Control: no-cache`, que deixa
o navegador guardar uma cópia mas o obriga a perguntar antes de usá-la; a aula 4 trata do que esses
dois cabeçalhos fazem com um teste. Com `QUITANDA_LOG=1`, ele imprime cada requisição que responde.
Salve-o como `app/server.js`:

```javascript
// Quitanda: the shop every lesson of this course tests. No dependencies,
// only what Node itself ships.
import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { send } from './http.js';

const port = Number(process.env.PORT ?? 3000);
const publicDir = path.join(import.meta.dirname, 'public');
const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json',
};

// Every file in routes/ exports a list of routes. A later lesson adds a
// file there; this one never changes.
const routes = [];
const routeDir = path.join(import.meta.dirname, 'routes');
for (const file of (await fs.readdir(routeDir)).sort()) {
  routes.push(...(await import(path.join(routeDir, file))).routes);
}

async function serveFile(req, res, pathname) {
  if (pathname.endsWith('/')) pathname += 'index.html';
  const file = path.join(publicDir, path.normalize(pathname));
  if (!file.startsWith(publicDir)) return send(res, 404, 'not found');
  let body;
  try {
    body = await fs.readFile(file);
  } catch {
    return send(res, 404, 'not found');
  }
  // A static file may be kept, but must be checked with the server first.
  const etag = '"' + crypto.createHash('sha1').update(body).digest('hex').slice(0, 12) + '"';
  const headers = { 'Cache-Control': 'no-cache', ETag: etag };
  if (req.headers['if-none-match'] === etag) {
    res.writeHead(304, headers);
    return res.end();
  }
  headers['Content-Type'] = types[path.extname(file)] ?? 'application/octet-stream';
  res.writeHead(200, headers);
  res.end(body);
}

async function readJson(req) {
  let text = '';
  for await (const chunk of req) text += chunk;
  return text ? JSON.parse(text) : {};
}

http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  // QUITANDA_LOG=1 prints every request the server receives.
  if (process.env.QUITANDA_LOG) {
    res.on('finish', () => console.log(req.method, req.url, res.statusCode));
  }
  const route = routes.find((r) => r.method === req.method && r.path === url.pathname);
  try {
    if (route) return await route.handle({ req, res, url, body: await readJson(req) });
    if (req.method === 'GET') return await serveFile(req, res, url.pathname);
    send(res, 404, 'not found');
  } catch (err) {
    console.error(err);
    send(res, 500, { error: String(err.message) });
  }
}).listen(port, () => console.log(`quitanda is listening on http://localhost:${port}`));
```

**Este arquivo nunca mais muda.** As aulas que ampliam a loja acrescentam um arquivo a
`app/routes/`, e o servidor o encontra na próxima vez que inicia; é por isso que o laço perto do
começo lê a pasta em vez de nomear os arquivos.

As primeiras rotas da loja: a lista de produtos, a cesta, o acréscimo a ela e o reinício. Salve-o
como `app/routes/shop.js`:

```javascript
import { send } from '../http.js';
import { store, reset, total } from '../store.js';

export const routes = [
  {
    method: 'GET', path: '/api/products',
    handle: ({ res }) => send(res, 200, store.products),
  },
  {
    method: 'GET', path: '/api/basket',
    handle: ({ res }) => send(res, 200, { lines: store.basket, total: total(store.basket) }),
  },
  {
    method: 'POST', path: '/api/basket',
    handle: ({ res, body }) => {
      if (!store.products.some((p) => p.id === body.id)) {
        return send(res, 400, { error: `no product called ${body.id}` });
      }
      const line = store.basket.find((l) => l.id === body.id);
      if (line) line.qty += 1;
      else store.basket.push({ id: body.id, qty: 1 });
      send(res, 200, { lines: store.basket, total: total(store.basket) });
    },
  },
  {
    method: 'POST', path: '/api/reset',
    handle: ({ res }) => {
      reset();
      send(res, 200, { reset: true });
    },
  },
];
```

Repare no que é a cesta: **uma lista só, compartilhada por todo mundo que abre a loja.** Não há
sessão nem login. É a maior falha da loja e ela não está marcada, porque não é uma armadilha
montada para uma aula: é o estado comum de muitos ambientes de teste, e as aulas 15 e 19 a
enfrentam de frente.
