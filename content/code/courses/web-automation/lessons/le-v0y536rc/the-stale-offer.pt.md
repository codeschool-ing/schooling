---
title: A oferta que não muda
version: 1
---

A loja ganha uma página com uma linha só, **a oferta do dia**: uma fruta e um preço, que alguém da
loja muda ao longo do dia. A falha está num cabeçalho. O servidor diz ao navegador que ele pode
guardar a oferta por dez minutos **sem perguntar**, então um cliente que abriu a página antes da
mudança continua vendo o preço antigo depois dela, e nada na tela dele avisa.

## A rota e a página

Duas rotas. `GET /api/offer` responde com o nome e o preço da oferta, em centavos, e o cabeçalho
`Cache-Control` marcado como a falha; `POST /api/offer` define uma nova a partir do id de um produto
e de um preço. O `reset()` de `app/store.js` já devolve a oferta a uma manga a 390. Salve-o como
`app/routes/offer.js`:

```javascript
import { send } from '../http.js';
import { store } from '../store.js';

export const routes = [
  {
    method: 'GET', path: '/api/offer',
    handle: ({ res }) => {
      const product = store.products.find((p) => p.id === store.offer.id);
      // A known flaw, on purpose: the browser may keep this answer for ten
      // minutes without asking again, so a new offer goes unseen.
      send(res, 200, { name: product.name, price: store.offer.price },
        { 'Cache-Control': 'max-age=600' });
    },
  },
  {
    method: 'POST', path: '/api/offer',
    handle: ({ res, body }) => {
      store.offer = { id: body.id, price: body.price };
      send(res, 200, store.offer);
    },
  },
];
```

A página pede a oferta depois de carregar e a escreve no parágrafo, com o preço formatado do jeito
que a página inicial da loja faz. Salve-a como `app/public/offer.html`:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Offer · Quitanda</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <main>
    <h1>Today's offer</h1>
    <p id="offer">…</p>
  </main>
  <script>
    const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
    fetch('/api/offer')
      .then((response) => response.json())
      .then((offer) => {
        document.querySelector('#offer').textContent =
          `${offer.name} for ${money.format(offer.price / 100)}`;
      });
  </script>
</body>
</html>
```

O servidor lê `app/routes/` ao iniciar, então **pare a loja e inicie de novo** antes de pedir a rota
nova. Depois, de um segundo terminal:

```
ana@laptop:~/quitanda$ curl -s -i http://localhost:3000/api/offer
HTTP/1.1 200 OK
Content-Type: application/json
Cache-Control: max-age=600
Date: Sat, 10 Oct 2026 19:37:12 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"name":"Mango","price":390}
```

`max-age=600` e nenhum `ETag`: por dez minutos, um navegador que tem essa resposta não tem motivo
para perguntar de novo, e depois disso não tem impressão digital com que perguntar, então busca tudo.

## Um cliente que volta, por script

Este script faz o papel de um cliente que volta. Ele reinicia a loja, abre a página da oferta, muda
a oferta pela API como faria alguém da loja, abre de novo a mesma página no mesmo navegador e a
recarrega. No caminho imprime cada resposta que o navegador informa, como o `look.mjs` da aula 1.
Salve-o como `stale.mjs`:

```javascript
// A returning customer: one browser, the offer page opened twice, and a
// new offer set through the API in between.
import { chromium } from '@playwright/test';

const shop = 'http://localhost:3000';
const post = (path, body) => fetch(shop + path, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
});

await post('/api/reset', {});
const browser = await chromium.launch();
const page = await browser.newPage();
page.on('response', (r) => console.log('  browser got', r.status(), new URL(r.url()).pathname));

async function show() {
  const offer = page.locator('#offer', { hasNotText: '…' });
  console.log('the page says', await offer.textContent());
}

console.log('first visit');
await page.goto(shop + '/offer.html');
await show();

await post('/api/offer', { id: 'banana', price: 290 });
console.log('the offer is now banana, at 290');

console.log('second visit, same browser');
await page.goto(shop + '/offer.html');
await show();

console.log('reload');
await page.reload();
await show();

await browser.close();
```

Inicie a loja com o log ligado, como na aula 1, e rode o script do outro terminal:

```
ana@laptop:~/quitanda$ node stale.mjs
first visit
  browser got 200 /offer.html
  browser got 200 /style.css
  browser got 200 /api/offer
the page says Mango for R$ 3,90
the offer is now banana, at 290
second visit, same browser
  browser got 200 /offer.html
  browser got 304 /style.css
  browser got 200 /api/offer
the page says Mango for R$ 3,90
reload
  browser got 200 /offer.html
  browser got 304 /style.css
  browser got 200 /api/offer
the page says Mango for R$ 3,90
```

**Mango três vezes.** A oferta mudou entre a primeira visita e a segunda, e a página nunca mostrou.
Agora o terminal da loja, que imprimiu cada requisição que chegou a ela enquanto o script rodava:

```
ana@laptop:~/quitanda$ QUITANDA_LOG=1 npm start

> start
> node app/server.js

quitanda is listening on http://localhost:3000
POST /api/reset 200
GET /offer.html 200
GET /style.css 200
GET /api/offer 200
POST /api/offer 200
GET /offer.html 304
GET /style.css 304
GET /offer.html 304
GET /style.css 304
```

**Um `GET /api/offer` para três visitas.** O navegador listou a oferta em toda visita, com `200`
toda vez, e duas dessas respostas nunca saíram do navegador: vieram da cópia guardada na primeira
visita. É disso que a aula 1 falava, uma requisição que o navegador lista e o servidor não. A página
e a folha de estilos levam `no-cache`, então o navegador perguntou por elas de novo, e o servidor
respondeu `304` nas duas vezes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Duas linhas do tempo. Em cima, a oferta do servidor: Mango a R$ 3,90 até que um POST para /api/offer a muda para Banana a R$ 2,90. Embaixo, o que a página mostra: a primeira visita pergunta ao servidor e mostra Mango; a segunda, depois da mudança, é respondida pela cópia do navegador e ainda mostra Mango; uma visita depois de 600 segundos pergunta de novo ao servidor e mostra Banana.\"><text x=\"20\" y=\"66\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a oferta do servidor</text><text x=\"20\" y=\"184\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">o que a página mostra</text><rect x=\"150\" y=\"46\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"162\" y=\"68\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Mango, R$ 3,90</text><rect x=\"380\" y=\"46\" width=\"320\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"392\" y=\"68\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Banana, R$ 2,90</text><path d=\"M380 36 L380 90\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"3 3\"></path><text x=\"384\" y=\"30\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">POST /api/offer</text><path d=\"M150 180 L700 180\" stroke=\"var(--wire)\"></path><path d=\"M190 176 L190 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M190 82 L185 92 L195 92 Z\" fill=\"var(--phosphor)\"></path><circle cx=\"190\" cy=\"180\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"196\" y=\"166\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">primeira visita</text><text x=\"190\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Mango</text><rect x=\"410\" y=\"110\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\"></rect><text x=\"450\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a cópia</text><path d=\"M450 176 L450 140\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M450 134 L445 144 L455 144 Z\" fill=\"var(--amber)\"></path><circle cx=\"450\" cy=\"180\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"456\" y=\"166\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">segunda visita</text><text x=\"450\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">Mango</text><path d=\"M630 176 L630 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M630 82 L625 92 L635 92 Z\" fill=\"var(--phosphor)\"></path><circle cx=\"630\" cy=\"180\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"636\" y=\"166\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">após 600 s</text><text x=\"630\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Banana</text><path d=\"M190 222 L190 232 M190 227 L600 227 M600 222 L600 232\" stroke=\"var(--amber)\"></path><text x=\"395\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">por 600 s a cópia é usada sem perguntar</text></svg>", "caption": "O servidor mudou a resposta; o navegador tinha ouvido que não precisava perguntar."}
```

Dois detalhes desse par de transcrições valem guardar.

**Um status informado pelo navegador não é a resposta do servidor.** Para a oferta, o navegador disse
`200` em visitas que o servidor nunca viu: uma cópia aparece com o status com que foi guardada. Para
a própria página ele disse `200` onde o log do servidor diz `304`. Só o `style.css` chegou como o
`304` que era. Quando a pergunta é *isto chegou ao servidor*, a evidência é o log do próprio servidor,
e não a lista do navegador.

**Recarregar não ajudou.** O recarregamento perguntou de novo ao servidor pela página, e o script da
página então pediu a oferta, que o navegador ainda tinha, válida por dez minutos. Um cliente que
desconfia do preço e aperta recarregar recebe o mesmo preço de volta.

## Por que isto é um defeito

A página não está quebrada de nenhum jeito que uma captura de tela mostre. Ela mostra uma oferta
real, bem formatada, vinda do servidor real. **Ela está errada por até dez minutos depois de cada
mudança**, para todo cliente que a carregou antes da mudança, e certa para todos os outros. Se o
preço no caixa é o novo, o cliente viu um preço e pagou outro; a aula 15 de `manual-testing` trata de
relatar isso de modo que alguém consiga reproduzir, e a próxima seção trata de por que os seus testes
não acharam antes.
