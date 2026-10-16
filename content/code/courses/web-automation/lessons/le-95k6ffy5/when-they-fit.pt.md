---
title: Onde um navegador simulado se paga
version: 1
---

O argumento a favor de um navegador simulado sempre foi a velocidade, e ele foi feito quando
iniciar um navegador de verdade levava segundos e pedia uma tela. **Meça antes de acreditar.** A
mesma verificação, abrir a página inicial e esperar os oito cards, dez vezes no jsdom e dez vezes
no Chromium. O Chromium é iniciado uma vez e cada página ganha uma aba nova, perto de como um worker do
Playwright mantém um navegador para muitos testes. Salve-o como `simulated/timing.mjs`:

```javascript
// The same check, ten times in each: open /, wait for eight cards.
import { chromium } from '@playwright/test';
import { address, open, until } from './shop.mjs';

const runs = 10;
const ms = (start) => Math.round(performance.now() - start);

let start = performance.now();
for (let i = 0; i < runs; i++) {
  const window = await open('/');
  await until(() => window.document.querySelectorAll('#products li').length === 8);
  window.close();
}
console.log(`jsdom:    ${runs} pages in ${ms(start)} ms`);

start = performance.now();
const browser = await chromium.launch();
console.log(`chromium: launched in ${ms(start)} ms`);
start = performance.now();
for (let i = 0; i < runs; i++) {
  const page = await browser.newPage();
  await page.goto(address + '/');
  await page.locator('#products li').nth(7).waitFor();
  await page.close();
}
console.log(`chromium: ${runs} pages in ${ms(start)} ms`);
await browser.close();
```

```
ana@laptop:~/quitanda$ node simulated/timing.mjs
jsdom:    10 pages in 729 ms
chromium: launched in 76 ms
chromium: 10 pages in 1643 ms
```

e mais uma vez, para ver o quanto varia:

```
ana@laptop:~/quitanda$ node simulated/timing.mjs
jsdom:    10 pages in 852 ms
chromium: launched in 95 ms
chromium: 10 pages in 1699 ms
```

**O jsdom foi umas duas vezes mais rápido, não dez.** Dez páginas levaram 729 ms no jsdom contra
1643 ms no Chromium, e 852 contra 1699 na segunda vez: uma diferença de menos de um décimo de
segundo por página. O próprio Chromium iniciou em 76 e 95 ms. A partida de vários segundos que os
navegadores simulados foram escritos para evitar não existe mais: nesta máquina, um navegador
headless iniciou em menos de um décimo de segundo. Em quinhentas verificações de página a
diferença daria uns três quartos de minuto, o que vale alguma coisa numa suíte que roda muitas
vezes por dia e não vale nada para uma verificação que não consegue mais falhar.

## Onde ele cabe

**Conferir HTML que o servidor manda completo.** O `/ssr` da aula 6 chega com todos os cards, e a
aula 6 conferiu isso com o fixture `request` do Playwright e `toContain`, um teste sobre o texto da
resposta. O jsdom acrescenta uma coisa: uma árvore analisada para consultar com seletores, então o
teste pode dizer *este card tem este título e este botão* em vez de *este texto aparece em algum
lugar*. Nenhum script precisa rodar, então nenhuma das opções das duas últimas seções está ligada,
e nenhuma das lacunas da seção anterior é atravessada. O executor do próprio Node basta para
rodá-lo. Salve-o como `simulated/ssr.test.mjs`:

```javascript
// Server-rendered HTML, checked with no browser and no scripts at all.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';

const address = 'http://localhost:3000';

test('every product the API lists is a card in the HTML of /ssr', async () => {
  const products = await (await fetch(address + '/api/products')).json();
  const { document } = (await JSDOM.fromURL(address + '/ssr')).window;
  for (const product of products) {
    const card = document.querySelector(`[data-testid=product-${product.id}]`);
    assert.ok(card, `no card for ${product.id}`);
    assert.equal(card.querySelector('h2').textContent, product.name);
    assert.equal(card.querySelector('button').dataset.id, product.id);
  }
});

test('the HTML of / has an empty list, for app.js to fill', async () => {
  const { document } = (await JSDOM.fromURL(address + '/')).window;
  assert.equal(document.querySelectorAll('#products li').length, 0);
});
```

Ele fica fora de `tests/` de propósito, para que o `npx playwright test` não tente rodá-lo. Com a
loja rodando, o `node --test` o roda; `--test-reporter=tap` imprime texto simples em vez de
símbolos:

```
ana@laptop:~/quitanda$ node --test --test-reporter=tap simulated/ssr.test.mjs
TAP version 13
# Subtest: every product the API lists is a card in the HTML of /ssr
ok 1 - every product the API lists is a card in the HTML of /ssr
  ---
  duration_ms: 205.516868
  type: 'test'
  ...
# Subtest: the HTML of / has an empty list, for app.js to fill
ok 2 - the HTML of / has an empty list, for app.js to fill
  ---
  duration_ms: 23.865929
  type: 'test'
  ...
1..2
# tests 2
# suites 0
# pass 2
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 964.790891
```

**Testar código que lê e escreve no DOM, sem uma página em volta.** Uma função que monta um card a
partir de um produto, ou que formata a linha da cesta, pode ser chamada no ambiente `jsdom` do Jest
milhares de vezes por minuto. Isso é um teste unitário, e a aula 11 pôs o Jest ali. O `app.js` da
loja não foi escrito para ser importado, então este curso não consegue mostrar um contra ele; um
projeto cujo código de front-end é dividido em módulos consegue.

## Onde ele não cabe

Tudo o que está na tabela da seção anterior. Se a pergunta é se uma pessoa consegue ver, alcançar,
ler ou usar alguma coisa, ou se ela funciona no navegador que essa pessoa tem, o único instrumento
é um navegador de verdade. Um simulado responde a essas perguntas com zeros e passa.

**Ponha cada um no lugar dele na suíte.** A aula 21 desenha a pirâmide de testes: muitos testes
baratos embaixo, poucos caros em cima, e a aula 1 de `testing-cicd` as camadas que um pipeline
roda. Um teste no jsdom fica embaixo: mais rápido que um teste de navegador, por menos do que diz a
fama, e cego para tudo o que está acima do DOM. Um teste de navegador fica no topo e é o único que
vê a página que o cliente vê. O erro caro é o do meio: fazer à camada barata uma pergunta que só a
de cima sabe responder, e contar o verde dela como evidência.
