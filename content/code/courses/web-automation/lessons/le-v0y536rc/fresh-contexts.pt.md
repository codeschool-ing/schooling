---
title: Por que os seus testes nunca a encontram
version: 1
---

O teste óbvio para a página da oferta define uma oferta nova e verifica que a página a mostra.
**Ele passa, e a falha continua lá.** Não é sorte, nem asserção fraca: é como o Playwright roda todo
teste, e vale entender isso antes de decidir se muda.

## Um navegador novo para cada teste

Um **contexto de navegador** é um perfil de navegador: seus próprios cookies, seu próprio
armazenamento e seu próprio cache HTTP, isolados de todo outro contexto no mesmo navegador. A
referência do Playwright diz isso numa linha: um contexto novo *won't share cookies/cache with other
browser contexts*, não divide cookies nem cache com outros. A `page` que um teste recebe vive num
contexto feito para aquele teste e descartado depois, então **todo teste é um cliente na primeira
visita**, sem nada guardado de teste anterior. A aula 10 trata de contextos em geral; aqui só o cache
importa.

Eis o teste óbvio. O `beforeEach` reinicia a loja antes de cada teste, então a oferta sempre começa
como a manga; o teste a muda e abre a página. Salve-o como `tests/cache.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a new offer reaches the page', async ({ page, request }) => {
  await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Banana');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/cache.spec.js

Running 1 test using 1 worker

  ✓  1 tests/cache.spec.js:7:1 › a new offer reaches the page (188ms)

  1 passed (1.6s)
```

Um teste, verde. Ele prova que o servidor entrega a oferta nova a um visitante novo, o que é verdade
e vale saber. Não diz nada sobre o cliente que já estava com a página aberta, porque nenhum teste
deste arquivo jamais foi esse cliente.

**Essa é a troca.** Um cache vazio torna o teste repetível: ele não passa por causa de algo que um
teste anterior deixou, nem falha por isso, e a aula 15 faz disso a regra para todos os dados de
teste. O preço é que todo teste encontra a loja como só um visitante de primeira vez encontra, e um
defeito que precisa de uma segunda visita fica invisível para a suíte inteira.

## Escrevendo o cliente que volta

Para encontrar a falha, um teste tem de ser um cliente que volta **de propósito**: visitar, mudar,
visitar de novo, tudo num contexto só. Acrescente este teste no fim de `tests/cache.spec.js`:

```javascript
test('a returning customer sees the new offer', async ({ page, request }) => {
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Mango');
  await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Banana');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/cache.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/cache.spec.js:7:1 › a new offer reaches the page (201ms)
  ✘  2 tests/cache.spec.js:13:1 › a returning customer sees the new offer (5.2s)


  1) tests/cache.spec.js:13:1 › a returning customer sees the new offer ────────────────────────────

    Error: expect(locator).toContainText(expected) failed

    Locator: locator('#offer')
    Expected substring: "Banana"
    Received string:    "Mango for R$ 3,90"
    Timeout: 5000ms

    Call log:
      - Expect "toContainText" with timeout 5000ms
      - waiting for locator('#offer')
        9 × locator resolved to <p id="offer">Mango for R$ 3,90</p>
          - unexpected value "Mango for R$ 3,90"


      16 |   await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
      17 |   await page.goto('/offer.html');
    > 18 |   await expect(page.locator('#offer')).toContainText('Banana');
         |                                        ^
      19 | });
      20 |
        at /home/ana/quitanda/tests/cache.spec.js:18:40

    Error Context: test-results/cache-a-returning-customer-sees-the-new-offer/error-context.md

  1 failed
    tests/cache.spec.js:13:1 › a returning customer sees the new offer ─────────────────────────────
  1 passed (6.9s)
```

O segundo teste falhou, e o relatório diz por que em duas linhas: esperava `Banana` e recebeu
`Mango for R$ 3,90`, nove vezes em cinco segundos. **É a falha, achada por um teste** pela primeira
vez, e bastou uma decisão: abrir a página duas vezes no mesmo contexto em vez de uma. A suíte não
pode ficar vermelha por uma falha que está lá de propósito, e a próxima seção transforma este teste
num que diz isso; deixe-o falhando até lá.

## Outras maneiras de voltar

A mesma página visitada duas vezes é um cliente que volta. Há outros, e nem todos guardam o cache.
Este script muda a oferta uma vez e manda cinco visitantes de volta à página, cada um feito de um
jeito, com a loja rodando. Um deles usa `launchPersistentContext`, que guarda o perfil numa pasta,
aqui `profile`, como um navegador comum guarda o seu entre uma abertura e outra. Salve-o como
`visitors.mjs`:

```javascript
// The offer changes once; five visitors come back, and each says what it
// was shown.
import { chromium } from '@playwright/test';
import { rm } from 'node:fs/promises';

const shop = 'http://localhost:3000';
const post = (path, body) => fetch(shop + path, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
});
async function visit(who, page) {
  await page.goto(shop + '/offer.html');
  const text = await page.locator('#offer', { hasNotText: '…' }).textContent();
  console.log(who.padEnd(28), text);
}

await post('/api/reset', {});
await rm('profile', { recursive: true, force: true });
const browser = await chromium.launch();
const context = await browser.newContext();
const page = await context.newPage();
await visit('before the change', page);
let kept = await chromium.launchPersistentContext('profile');
await visit('before, in a kept profile', await kept.newPage());
await kept.close();

await post('/api/offer', { id: 'banana', price: 290 });

await visit('the same page', page);
await visit('a new page, same context', await context.newPage());
const saved = await browser.newContext({ storageState: await context.storageState() });
await visit('a new context, saved state', await saved.newPage());
await visit('a new context', await (await browser.newContext()).newPage());
kept = await chromium.launchPersistentContext('profile');
await visit('the kept profile, reopened', await kept.newPage());

await kept.close();
await browser.close();
```

```
ana@laptop:~/quitanda$ node visitors.mjs
before the change            Mango for R$ 3,90
before, in a kept profile    Mango for R$ 3,90
the same page                Mango for R$ 3,90
a new page, same context     Mango for R$ 3,90
a new context, saved state   Banana for R$ 2,90
a new context                Banana for R$ 2,90
the kept profile, reopened   Mango for R$ 3,90
```

Três dos cinco voltaram à oferta antiga, e o que eles têm em comum é o cache, não os passos:

- **a mesma página** e **uma página nova no mesmo contexto**: um contexto tem um cache só, seja qual
  for a página que pergunta;
- **um perfil guardado, reaberto**: o `launchPersistentContext` grava o cache na pasta junto com o
  resto, e a segunda abertura o leu de volta. É o mais perto que um script chega de uma pessoa que
  fecha o navegador e o abre amanhã. Apague a pasta `profile` depois da execução;
- **um contexto novo feito do estado salvo** viu a oferta nova. O `storageState` leva cookies e
  armazenamento local, que é o que uma sessão logada precisa, e **não o cache HTTP**. Uma suíte que
  faz login uma vez e reaproveita o estado em todo teste ainda roda cada teste como primeira visita,
  no que diz respeito ao cache.

Então um cliente que volta, num teste, é ou duas visitas dentro de um teste, ou um contexto
persistente mantido entre execuções. A primeira é a base da próxima seção, porque não precisa de
pasta e não deixa nada para trás.
