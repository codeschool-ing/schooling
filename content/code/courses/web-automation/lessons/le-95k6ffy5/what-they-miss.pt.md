---
title: O que uma página sem layout não consegue dizer
version: 1
---

A suposição fácil é que um navegador simulado responde a menos perguntas e avisa quando não sabe
responder uma. **Ele responde a quase todas, e as respostas às que não consegue tratar são zeros,
valores padrão e silêncio.** Uma verificação escrita para o Chromium e levada para o jsdom continua
rodando, continua passando, e deixa de significar alguma coisa. Esta seção leva quatro dessas
perguntas à loja e registra as respostas.

## Tamanho e posição

A aula 7 descobriu que a página inicial tem 400 pixels de largura numa janela de 360, por causa de
uma linha do `style.css`, e escreveu um teste que compara `document.documentElement.scrollWidth`
com a largura da janela. A aula 11 disse numa frase que essa cesta é invisível para o jsdom; esta
é a medida. Os mesmos números, perguntados ao jsdom, com a comparação da aula 7 no fim e mais
algumas perguntas depois. Salve-o como `simulated/missing.mjs`:

```javascript
// What jsdom leaves out, measured on the shop's home page.
import { open, until } from './shop.mjs';

const window = await open('/');
const { document } = window;
await until(() => document.querySelector('#products').getAttribute('aria-busy') === 'false');

// Layout: the numbers lesson 7 compared, and its check at 360 px.
const basket = document.querySelector('.basket');
const scrollWidth = document.documentElement.scrollWidth;
console.log(`innerWidth: ${window.innerWidth}`);
console.log(`scrollWidth: ${scrollWidth}`);
console.log(`.basket min-width: ${window.getComputedStyle(basket).minWidth}`);
console.log(`.basket width: ${basket.getBoundingClientRect().width}`);
console.log(`lesson 7's check at 360 px: ${scrollWidth <= 360 ? 'passes' : 'fails'}`);

// Interfaces a page may call.
for (const name of ['matchMedia', 'IntersectionObserver', 'ResizeObserver']) {
  console.log(`${name}: ${typeof window[name]}`);
}
console.log(`innerText: ${typeof document.body.innerText}`);

// Navigation: follow the Search link.
document.querySelector('a[href="/search.html"]').click();
await new Promise((resolve) => setTimeout(resolve, 200));
console.log(`after clicking Search: ${window.location.pathname}`);
window.close();
```

```
ana@laptop:~/quitanda$ node simulated/missing.mjs
innerWidth: 1024
scrollWidth: 0
.basket min-width: 384px
.basket width: 0
lesson 7's check at 360 px: passes
matchMedia: undefined
IntersectionObserver: undefined
ResizeObserver: undefined
innerText: undefined
Not implemented: navigation to another Document
after clicking Search: /
```

Leia as cinco primeiras linhas juntas. **O jsdom conhece a regra e não consegue aplicá-la**: ele
casou `min-width: 24rem` com a cesta e até converteu para 384px, e depois informa a cesta com 0 de
largura e a página com 0 de largura. O `innerWidth` é 1024 porque é o número que o jsdom sempre
informa, não porque alguma coisa foi diagramada nele. Então a verificação da aula 7 passa: 0 não é
mais que 360. A mesma página falhou nela no Chromium, com 400.

**É o pior resultado que um teste pode dar: verde numa página quebrada.** Nada na saída avisa.
Toda verificação responsiva, todo "isto está dentro da janela", todo `toBeInViewport` pertence a
um navegador de verdade.

## Interfaces que não existem

`matchMedia` é como um script faz a pergunta que uma media query faz; `IntersectionObserver` é como
uma página sabe que algo entrou na área visível ao rolar, o jeito comum de carregar imagens mais
tarde; `ResizeObserver` observa um elemento mudar de tamanho. Os três são `undefined` no jsdom
30.1.2, então uma página que chama um deles lança um erro, como o `app.js` lançou no `fetch` na
seção anterior. O `innerText` também falta, e pelo mesmo motivo dos zeros: o que ele devolve
depende do que está visível, e a visibilidade depende do layout. O `textContent`, que ignora os
estilos, está lá.

**A navegação é a outra grande ausência.** O link Search foi clicado, o jsdom imprimiu
`Not implemented: navigation to another Document`, e o endereço continuou `/`. O README do jsdom
cita navegação e layout como as duas funcionalidades fora do escopo dele. Uma jornada por várias
páginas, aquilo para que um teste ponta a ponta existe, precisa ser montada com um `JSDOM` por
página.

## Visibilidade e cliques de verdade

Acima de 600 pixels a loja esconde o botão Menu com `display: none`. Uma pessoa não consegue
apertá-lo, e a aula 10 mostrou que o Playwright espera um elemento ficar visível antes de clicar.
O jsdom e o Chromium, chamados a apertá-lo. Salve-o como `simulated/hidden.mjs`:

```javascript
// The Menu button is display: none in a wide window. Who can press it?
import { chromium } from '@playwright/test';
import { address, open, until } from './shop.mjs';

const window = await open('/');
const menu = window.document.querySelector('.menu-toggle');
await until(() => window.document.readyState === 'complete');
console.log(`jsdom: display is ${window.getComputedStyle(menu).display}`);
menu.click();
console.log(`jsdom: aria-expanded is ${menu.getAttribute('aria-expanded')} after click()`);
window.close();

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
await page.goto(address + '/');
const button = page.locator('.menu-toggle');
try {
  await button.click({ timeout: 2000 });
} catch (error) {
  console.log(error.message);
}
console.log(`chromium: aria-expanded is ${await button.getAttribute('aria-expanded')}`);
await browser.close();
```

```
ana@laptop:~/quitanda$ node simulated/hidden.mjs
jsdom: display is none
jsdom: aria-expanded is true after click()
locator.click: Timeout 2000ms exceeded.
Call log:
  - waiting for locator('.menu-toggle')
    - locator resolved to <button type="button" class="menu-toggle" aria-expanded="false">Menu</button>
  - attempting click action
    2 × waiting for element to be visible, enabled and stable
      - element is not visible
    - retrying click action
    - waiting 20ms
    2 × waiting for element to be visible, enabled and stable
      - element is not visible
    - retrying click action
      - waiting 100ms
    4 × waiting for element to be visible, enabled and stable
      - element is not visible
    - retrying click action
      - waiting 500ms

chromium: aria-expanded is false
```

**O jsdom sabia que o botão estava escondido e clicou mesmo assim.** O `click()` dele é o método do
próprio DOM: manda um evento de clique para aquele elemento, e o listener do elemento roda. Não há
ponteiro, então nada pergunta se o botão está na tela, coberto por outra coisa ou com zero pixels de
largura. O Chromium, conduzido pelo Playwright, conferiu essas coisas por dois segundos, disse por
que não clicaria e deixou o `aria-expanded` como estava. O clique de um usuário cai no que estiver
desenhado num ponto; só algo que desenha consegue dizer que elemento é esse.

## A lista curta

Em que não se pode confiar num navegador simulado, com o caso desta aula:

| pergunta | o que aconteceu aqui |
|---|---|
| qual o tamanho, onde fica, cabe | `scrollWidth` 0, a verificação da aula 7 passou numa página quebrada |
| uma pessoa consegue ver ou alcançar | um botão com `display: none` foi clicado |
| um link leva a algum lugar | `Not implemented: navigation to another Document` |
| o JavaScript da página roda | o jsdom não tinha `fetch`; o Rhino do HtmlUnit parou no `async` |
| funciona no navegador do usuário | um motor simulado é um que nenhum usuário tem |

Nada disso é defeito do jsdom. Os autores dele listam layout e navegação como fora do escopo, e as
interfaces que faltam como faltando. O defeito seria um teste que faz uma dessas perguntas ali e
acredita na resposta.
