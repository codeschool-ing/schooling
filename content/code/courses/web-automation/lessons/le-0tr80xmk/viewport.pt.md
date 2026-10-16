---
title: A viewport, e o que um celular diz de si mesmo
version: 1
---

A primeira ideia comum de testar num celular é uma janela estreita: deixar o navegador com 390
pixels de largura e chamar isso de iPhone. **A largura é uma de seis opções que o Playwright
define para um celular**, e uma das outras decide se a página é sequer montada nessa largura. Esta
seção dá nome a elas, imprime o que o Playwright define para um celular e mede o que a página vê.

## Dois tipos de pixel

Uma folha de estilos é escrita em **pixels CSS**, uma unidade de comprimento que o navegador
decide, e a tela é feita de **pixels do dispositivo**, os pontos no vidro. Num monitor de mesa os
dois costumam ser iguais. Um celular junta vários pixels do dispositivo num pixel CSS, para que o
texto saia nítido e ainda num tamanho legível; a razão entre eles é a **razão de pixels do
dispositivo**. Um iPhone 13 tem 390 pixels CSS de largura com razão 3, o que dá 1170 pontos de um
lado ao outro. Toda largura desta aula, na folha de estilos e nos testes, está em pixels CSS. A
razão importa para uma captura de tela, tema da aula 16, e quase nunca para saber se um botão
funciona.

## A tag viewport

A janela em que a página é montada é a **viewport**. Os celulares chegaram a uma web de páginas
feitas para computadores, então um navegador de celular monta a página como se a janela tivesse
cerca de 980 pixels CSS e depois encolhe o resultado para caber no vidro: está tudo lá, e tudo
minúsculo. Uma página escrita para celulares avisa isso com uma linha no `head`, que o `index.html`
da loja tem desde a aula 1:

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

`width=device-width` pede uma viewport da largura do celular, 390 em vez de 980, e
`initial-scale=1` pede para não encolher. **Sem essa linha, nenhuma regra de estilo escrita para
uma janela estreita vale num celular**, porque a janela que o celular informa não é estreita.

## O que um descritor de dispositivo define

O Playwright traz uma lista de celulares, tablets e computadores chamada `devices`, cada um um
conjunto de opções para um novo contexto de navegador. Imprima um a partir da cópia instalada no
seu projeto em vez de confiar numa tabela de blog, porque a lista muda de uma versão para outra:

```
ana@laptop:~/quitanda$ node -p "require('@playwright/test').devices['iPhone 13']"
{
  userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1',
  viewport: { width: 390, height: 664 },
  screen: { width: 390, height: 844 },
  deviceScaleFactor: 3,
  isMobile: true,
  hasTouch: true,
  defaultBrowserType: 'webkit'
}
```

Seis opções, e cada uma muda uma coisa diferente:

- **`viewport`** é a janela, 390 por 664: os 844 da `screen`, menos as barras do próprio navegador;
- **`userAgent`** é o nome que o navegador dá a todo servidor a quem pede algo, e é só uma string.
  Esta diz iOS 15 e Safari 26 ao mesmo tempo, e nenhum servidor tem como saber;
- **`deviceScaleFactor`** é a razão de pixels do dispositivo;
- **`isMobile`** faz o navegador respeitar a tag viewport, e a falta dela, como um celular faz; um
  navegador de computador ignora a tag por completo;
- **`hasTouch`** liga os eventos de toque e faz a pergunta de CSS `(pointer: coarse)`, *o ponteiro
  é um dedo?*, responder que sim;
- **`defaultBrowserType`** diz que motor o aparelho de verdade roda: o Safari num iPhone é WebKit.

## Medindo o que a página vê

Este script abre uma página em três contextos do Chromium: uma janela de computador com 1280 de
largura, uma janela de computador com 390, e o descritor do iPhone 13 sem o seu
`defaultBrowserType`, por um motivo que a seção sobre páginas adaptativas explica. Em cada um, ele
pergunta à página o que ela mede. Salve-o como `viewport.mjs`:

```javascript
// What a page measures in three browsers that differ only in what they
// say about themselves. Run it with the shop started:
//   node viewport.mjs [path]
import { chromium, devices } from '@playwright/test';

const path = process.argv[2] ?? '/';
// The iPhone 13 descriptor asks for WebKit. This keeps everything else
// it sets and runs it in Chromium.
const { defaultBrowserType, ...iPhone13 } = devices['iPhone 13'];
const browsers = {
  'desktop, 1280 wide': { viewport: { width: 1280, height: 720 } },
  'desktop, 390 wide': { viewport: { width: 390, height: 664 } },
  'iPhone 13': iPhone13,
};

const browser = await chromium.launch();
for (const [name, options] of Object.entries(browsers)) {
  const context = await browser.newContext(options);
  const page = await context.newPage();
  await page.goto('http://localhost:3000' + path);
  const seen = await page.evaluate(() => ({
    screen: screen.width,
    innerWidth,
    scrollWidth: document.documentElement.scrollWidth,
    devicePixelRatio,
    touch: matchMedia('(pointer: coarse)').matches,
    says: document.querySelector('h1 + p')?.textContent,
  }));
  console.log(name.padEnd(19), JSON.stringify(seen));
  await context.close();
}
await browser.close();
```

Com a loja iniciada em outro terminal:

```
ana@laptop:~/quitanda$ node viewport.mjs
desktop, 1280 wide  {"screen":1280,"innerWidth":1280,"scrollWidth":1280,"devicePixelRatio":1,"touch":false}
desktop, 390 wide   {"screen":390,"innerWidth":390,"scrollWidth":400,"devicePixelRatio":1,"touch":false}
iPhone 13           {"screen":390,"innerWidth":400,"scrollWidth":400,"devicePixelRatio":3,"touch":true}
```

A janela estreita de computador e o celular têm a mesma tela, 390, e diferem em todo o resto: três
vezes os pixels, um dedo como ponteiro e uma janela de **400**, mais larga que a tela em que está.
A página tem 400 de largura nos dois. A janela de computador fica em 390 e a página rola para o lado
dentro dela; o celular, respeitando a tag viewport, alarga a janela para caber o que está lá. Mesma
página, mesma tela, duas medidas diferentes, o primeiro sinal de que os dois são testes
diferentes. A seção sobre a rolagem lateral trata de onde vêm esses 400 pixels.

O mesmo script na página de ofertas, que a seção sobre páginas adaptativas acrescenta à loja:

```
ana@laptop:~/quitanda$ node viewport.mjs /deals
desktop, 1280 wide  {"screen":1280,"innerWidth":1280,"scrollWidth":1280,"devicePixelRatio":1,"touch":false,"says":"Weekly deals, in a table."}
desktop, 390 wide   {"screen":390,"innerWidth":390,"scrollWidth":390,"devicePixelRatio":1,"touch":false,"says":"Weekly deals, in a table."}
iPhone 13           {"screen":390,"innerWidth":980,"scrollWidth":980,"devicePixelRatio":3,"touch":true,"says":"Tap a deal to call the shop."}
```

**O celular monta esta página com 980 pixels de largura.** O HTML dela não tem a tag viewport, então
o celular volta a uma janela do tamanho de um computador e a encolhe, enquanto a janela de
computador com 390 de largura a monta com 390. Um teste que só estreitasse uma janela de computador
nunca veria isso, e no celular cada palavra da página sai com cerca de dois quintos do tamanho
pretendido, 390 sobre 980.
