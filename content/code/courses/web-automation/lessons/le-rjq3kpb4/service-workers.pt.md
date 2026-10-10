---
title: Service workers, e a página que abre sem rede
version: 1
---

Um **progressive web app**, uma PWA, é um app web que o navegador consegue instalar como um nativo e
que continua funcionando quando a rede não funciona. A crença comum é que se trata de um tipo de
framework, ou de um pacote de loja de aplicativos. Não é nenhum dos dois: é um site comum com três
coisas a mais. É servido por HTTPS, ou de `localhost`, que os navegadores tratam como seguro. Tem um
**manifesto**, o pequeno arquivo JSON que você salvou na primeira seção, que dá ao app instalado o
nome, o endereço em que ele começa e como ele abre. E tem um **service worker**, que é a parte que
muda os testes.

## O que é um service worker

Um service worker é um script que o navegador roda **à parte da página, entre a página e a rede**.
Depois de instalado, toda requisição que uma página do seu escopo faz, `/spa/` e tudo abaixo dele
neste caso, passa primeiro pelo worker, e o worker decide se responde com uma cópia que guarda, se
pergunta à rede, ou as duas coisas. Ele sobrevive à página: continua instalado na próxima vez que o
navegador abre o site, e é isso que permite a um app abrir sem rede nenhuma. O da quitanda é curto:

```schooling-example
{"language": "javascript", "file": "app/public/spa/sw.js", "parts": [{"code": "// The service worker that makes the app open with no network. It keeps a\n// copy of the page, its script and its style, and answers from that copy\n// before asking the server.\nconst SHELL = ['/spa/', '/spa/spa.js', '/style.css'];\n", "note": "O comentário diz para que ele serve. O worker guarda uma cópia de três arquivos, o **shell**: a página, o seu script e a folha de estilos. Não os dados."}, {"code": "self.addEventListener('install', (event) => {\n  event.waitUntil(caches.open('shell-v1').then((cache) => cache.addAll(SHELL)));\n});\n", "note": "Quando o navegador instala o worker, ele busca os três arquivos para um cache chamado `shell-v1`. O `waitUntil` mantém a instalação aberta até eles estarem lá."}, {"code": "self.addEventListener('fetch', (event) => {\n  const url = new URL(event.request.url);\n  if (event.request.method !== 'GET' || url.pathname.startsWith('/api/')) return;\n  event.respondWith(caches.match(event.request).then((hit) => hit ?? fetch(event.request)));\n});", "note": "Toda requisição do escopo passa por aqui. O que não é `GET`, e o que está sob `/api/`, é deixado em paz e vai à rede como sempre. O resto é respondido do cache se estiver lá, e buscado no servidor só se não estiver: **cache primeiro**."}]}
```

Rode `spa-look.mjs` uma segunda vez. O perfil em `.spa-profile` ainda tem o worker que a primeira
execução instalou, então este é um visitante voltando:

```
ana@laptop:~/quitanda$ node spa-look.mjs
   16 ms  document   /spa/  from the service worker
   26 ms  stylesheet /style.css  from the service worker
   31 ms  script     /spa/spa.js  from the service worker
   59 ms  fetch      /api/products  from the server
   79 ms  heading: Fruit
   87 ms  service worker ready; click Basket
  120 ms  fetch      /api/basket  from the server
  124 ms  heading: Basket, address: http://localhost:3000/spa/basket
```

Compare com a primeira execução. O documento, a folha de estilos e o script agora vêm **do service
worker**, e o servidor nem foi consultado sobre eles; os dois `fetch` sob `/api/` ainda vão ao
servidor, porque o worker os deixa passar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três caixas: a página, o service worker e o servidor. As requisições sob /api/, como /api/products e /api/basket, atravessam o worker até o servidor, e sem rede nada as responde. As requisições do shell vão da página para um cache dentro do worker chamado shell-v1, com /spa/, /spa/spa.js e /style.css, que as responde com ou sem rede.\"><rect x=\"20\" y=\"40\" width=\"140\" height=\"170\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"36\" y=\"64\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">a página</text><rect x=\"220\" y=\"40\" width=\"280\" height=\"170\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"236\" y=\"64\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">service worker</text><rect x=\"240\" y=\"120\" width=\"240\" height=\"76\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"256\" y=\"142\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">shell-v1</text><text x=\"256\" y=\"162\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/spa/  /spa/spa.js  /style.css</text><text x=\"256\" y=\"184\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">respondido desta cópia</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"170\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"576\" y=\"64\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">o servidor</text><text x=\"576\" y=\"122\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/api/products</text><text x=\"576\" y=\"140\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/api/basket</text><path d=\"M160 100 L552 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M560 100 L550 94 L550 106 Z\" fill=\"var(--phosphor)\"></path><text x=\"360\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">/api/… segue direto para a rede</text><path d=\"M160 158 L232 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M240 158 L230 152 L230 164 Z\" fill=\"var(--phosphor)\"></path><text x=\"360\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">com ou sem rede, a mesma resposta</text><text x=\"630\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">sem rede: ninguém responde</text></svg>", "caption": "Dois tipos de requisição, duas respostas diferentes. Sem rede, o shell ainda chega e os dados não.", "same": ["service worker"]}
```

## Testando com a rede desligada

`context.setOffline(true)` faz o contexto de navegador do Playwright se comportar como se a rede
tivesse sumido: qualquer requisição que chegue à rede falha. Com um worker instalado, o shell deveria
abrir mesmo assim. O teste abaixo carrega o app uma vez, espera o worker ficar pronto, fica sem rede
e recarrega. Salve-o como `tests/offline.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('the shell opens offline once the worker has it', async ({ page, context }) => {
  await page.goto('/spa/');
  await page.evaluate(() => navigator.serviceWorker.ready);
  await context.setOffline(true);
  const error = page.waitForEvent('pageerror');
  const response = await page.reload();
  expect(response.fromServiceWorker()).toBe(true);
  await expect(page.getByRole('link', { name: 'Basket' })).toBeVisible();
  // The fruit is not in the shell: /api/products goes to the network, and fails.
  expect((await error).message).toContain('Failed to fetch');
  await expect(page.locator('#view')).toBeEmpty();
});

test.describe('with service workers blocked', () => {
  test.use({ serviceWorkers: 'block' });

  test('the same reload finds nothing to answer it', async ({ page, context }) => {
    const messages = [];
    page.on('console', (message) => messages.push(message.text()));
    await page.goto('/spa/');
    await context.setOffline(true);
    await expect(page.reload()).rejects.toThrow('ERR_INTERNET_DISCONNECTED');
    expect(messages).toContain('Service Worker registration blocked by Playwright');
  });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/offline.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/offline.spec.js:3:1 › the shell opens offline once the worker has it (166ms)
  ✓  2 tests/offline.spec.js:19:3 › with service workers blocked › the same reload finds nothing to answer it (121ms)

  2 passed (1.9s)
```

Os dois passam. O primeiro prova três coisas, em ordem: o recarregamento, sem rede, foi respondido
pelo worker, já que `fromServiceWorker()` é verdadeiro; o cabeçalho e os seus links, que estão no
`index.html` guardado, estão na tela; e a página lançou um `Failed to fetch` não tratado, deixando
`#view` vazio. O segundo roda os mesmos primeiros passos com os workers bloqueados, e ali o
recarregamento lança um erro.

**A segunda linha é a que importa.** O worker se instala em segundo plano depois que a página
carregou, e nada na página diz quando ele terminou. `navigator.serviceWorker.ready` é uma promessa
que o navegador guarda exatamente para isso, e o `page.evaluate` a espera. Eis o mesmo arquivo com
essa linha apagada:

```
ana@laptop:~/quitanda$ npx playwright test tests/offline.spec.js

Running 2 tests using 1 worker

  ✘  1 tests/offline.spec.js:3:1 › the shell opens offline once the worker has it (1.2s)
  ✓  2 tests/offline.spec.js:18:3 › with service workers blocked › the same reload finds nothing to answer it (111ms)


  1) tests/offline.spec.js:3:1 › the shell opens offline once the worker has it ────────────────────

    Error: page.reload: net::ERR_INTERNET_DISCONNECTED
    Call log:
      - waiting for navigation until "load"


       5 |   await context.setOffline(true);
       6 |   const error = page.waitForEvent('pageerror');
    >  7 |   const response = await page.reload();
         |                               ^
       8 |   expect(response.fromServiceWorker()).toBe(true);
       9 |   await expect(page.getByRole('link', { name: 'Basket' })).toBeVisible();
      10 |   // The fruit is not in the shell: /api/products goes to the network, and fails.
        at /home/ana/quitanda/tests/offline.spec.js:7:31

    Error: page.waitForEvent: Test ended.
    =========================== logs ===========================
    waiting for event "pageerror"
    ============================================================

      4 |   await page.goto('/spa/');
      5 |   await context.setOffline(true);
    > 6 |   const error = page.waitForEvent('pageerror');
        |                      ^
      7 |   const response = await page.reload();
      8 |   expect(response.fromServiceWorker()).toBe(true);
      9 |   await expect(page.getByRole('link', { name: 'Basket' })).toBeVisible();
        at /home/ana/quitanda/tests/offline.spec.js:6:22

  1 failed
    tests/offline.spec.js:3:1 › the shell opens offline once the worker has it ─────────────────────
  1 passed (3.5s)
```

O recarregamento falha com `net::ERR_INTERNET_DISCONNECTED`, o erro que o teste bloqueado espera,
porque naquele momento ainda não havia worker para respondê-lo. O segundo erro, embaixo, decorre do
primeiro: o teste terminou enquanto o `waitForEvent('pageerror')` ainda esperava, e o Playwright
relata a promessa deixada para trás. Leia uma falha de cima para baixo.

**E o teste diz o que sem rede significa para este app**: o shell, e mais nada. O worker não guarda
cópia de `/api/products`, então o `fetch` do script falha, o erro não é tratado, e `#view` fica vazio
sob um cabeçalho que parece normal. Se isso é aceitável é uma decisão de produto, e vale uma pergunta
a quem é dono do app: um app instalado que abre numa página em branco sem uma palavra é um defeito
para a maioria das pessoas que o encontram.

## Bloqueando o worker

A maioria dos testes não trata do service worker, e para esses ele é mais uma coisa que pode
responder a uma requisição. A documentação do Playwright diz isso com todas as letras sobre o
`page.route`, a interceptação que o teste de rede lenta da primeira seção usa: ele não vê
requisições que um service worker respondeu, e a documentação recomenda **`serviceWorkers: 'block'`**
quando você intercepta. O segundo teste do arquivo usa essa opção, com `test.use` para o seu próprio
bloco `describe`. Com o worker bloqueado, o console avisa, e o mesmo recarregamento sem rede não tem
quem o responda, então falha do jeito que qualquer página falha sem rede,
`net::ERR_INTERNET_DISCONNECTED`.

Cada teste do Playwright ganha um **contexto de navegador novo**, com armazenamento vazio e nenhum
worker instalado, então um worker instalado por um teste nunca responde a uma requisição no seguinte.
Esse isolamento é justamente o que a pasta `.spa-profile` do `spa-look.mjs` abre mão de propósito.
