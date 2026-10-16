---
title: A espera explícita, um laço com relógio
version: 1
---

**Uma espera explícita é um laço escrito no único lugar onde ele faz falta: uma condição, perguntada
de novo e de novo, até ser verdade ou um relógio acabar.** Três números descrevem qualquer uma delas:
quanto pode durar, de quanto em quanto tempo pergunta, e o que pergunta. A espera implícita da seção
anterior fixava o primeiro para a sessão inteira e só sabia fazer uma pergunta, *algo casa com este
localizador?*. Uma espera explícita deixa cada linha do teste escolher os três.

## No Selenium: `driver.wait`

`driver.wait(condition, timeout)` é o mecanismo inteiro. O módulo `until` traz condições prontas,
`elementLocated`, `elementTextIs`, `elementIsVisible`, `titleIs` e mais uma dúzia, e cada uma é uma
função que responde *ainda não* ou um valor. O código-fonte instalado do `selenium-webdriver` 4.51
mostra os padrões:

```
ana@laptop:~/quitanda$ grep -n 'wait(condition, timeout = 0' node_modules/selenium-webdriver/lib/webdriver.js
858:  wait(condition, timeout = 0, message = undefined, pollTimeout = 200) {
```

Dois deles importam. **A espera pergunta a cada 200 ms**, a não ser que você passe um quarto
argumento. E **um tempo limite `0`, o padrão, quer dizer sem limite**:
`driver.wait(until.elementLocated(...))` sem segundo argumento espera para sempre, o que num servidor
de build quer dizer até alguma outra coisa matar o job. Passe sempre o tempo limite.

Este teste é o clique em `/ssr` da seção anterior, feito direito. Ele espera o marcador de pronto,
clica e espera a contagem; a espera implícita fica no padrão, zero. Salve como
`selenium/ssr.test.js`:

```javascript
import { test, before, after } from 'node:test';
import { Builder, By, until } from 'selenium-webdriver';
import chrome from 'selenium-webdriver/chrome.js';

const shop = 'http://localhost:3000';
let driver;

before(async () => {
  const options = new chrome.Options().addArguments('--headless=new');
  driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
});

after(async () => {
  await driver?.quit();
});

test('a click on /ssr counts once the page is ready', async () => {
  await fetch(`${shop}/api/reset`, { method: 'POST' });
  await driver.get(`${shop}/ssr`);
  await driver.wait(until.elementLocated(By.css('body[data-ready="true"]')), 5000);
  await driver.findElement(By.css('[data-testid=product-banana] button')).click();
  const count = await driver.findElement(By.css('[data-testid=basket-count]'));
  await driver.wait(until.elementTextIs(count, '1'), 5000);
});
```

Com a loja rodando:

```
ana@laptop:~/quitanda$ node --test --test-reporter=tap selenium/ssr.test.js
TAP version 13
# Subtest: a click on /ssr counts once the page is ready
ok 1 - a click on /ssr counts once the page is ready
  ---
  duration_ms: 2287.296376
  type: 'test'
  ...
1..1
# tests 1
# suites 0
# pass 1
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 2663.874181
```

O teste não tem `assert`, e não precisa: **uma espera que estoura lança um erro**, e um erro lançado
é um teste que falhou. A última linha é a verificação.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Duas faixas numa linha do tempo da página renderizada no servidor, de 0 a 2000 milissegundos. A espera implícita acha o botão aos 30 ms, porque ele existe desde o início, e o clique, por volta dos 140 ms, se perde. O script da página rodou por volta dos 1500 ms. A espera explícita pergunta pelo marcador de pronto a cada 200 ms, recebe não em toda olhada até os 1400 ms, e sim aos 1600 ms, quando o clique funciona.\"><path d=\"M562.9 30 L562.9 200\" stroke=\"var(--phosphor)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><text x=\"556.9\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" text-anchor=\"end\">o ssr.js já rodou</text><text x=\"20\" y=\"70\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">espera implícita</text><text x=\"20\" y=\"88\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">findElement</text><path d=\"M170.0 66 L690.0 66\" stroke=\"var(--scan)\" stroke-width=\"1\"></path><circle cx=\"177.8\" cy=\"66\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"187.8\" y=\"54\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">achado na hora</text><path d=\"M202.4 76 L212.4 86 M212.4 76 L202.4 86\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"219.4\" y=\"86\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" text-anchor=\"start\">clique perdido</text><text x=\"20\" y=\"150\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" text-anchor=\"start\">espera explícita</text><text x=\"20\" y=\"168\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">driver.wait</text><path d=\"M170.0 146 L690.0 146\" stroke=\"var(--scan)\" stroke-width=\"1\"></path><circle cx=\"170.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"222.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"274.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"326.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"378.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"430.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"482.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"534.0\" cy=\"146\" r=\"4\" fill=\"var(--paper-dim)\"></circle><circle cx=\"586.0\" cy=\"146\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"598.0\" y=\"150\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" text-anchor=\"start\">verdade: agora clica</text><text x=\"170.0\" y=\"176\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\">pergunta a cada 200 ms, por até 5000 ms</text><path d=\"M170 214 L690 214\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M170.0 210 L170.0 218\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"170.0\" y=\"234\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">0 ms</text><path d=\"M300.0 210 L300.0 218\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"300.0\" y=\"234\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">500 ms</text><path d=\"M430.0 210 L430.0 218\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"430.0\" y=\"234\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">1000 ms</text><path d=\"M560.0 210 L560.0 218\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"560.0\" y=\"234\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">1500 ms</text><path d=\"M690.0 210 L690.0 218\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"690.0\" y=\"234\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"middle\">2000 ms</text><text x=\"690\" y=\"256\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"end\">tempo desde que a página carregou</text></svg>", "caption": "A mesma página, duas esperas. A implícita termina quando o botão existe; a explícita, quando a página está pronta. Tempos da execução da seção anterior."}
```

## No Playwright: asserções e `waitFor`

O Playwright escreve o laço por você em dois lugares, e a aula 10 deu nome aos dois. Uma **asserção
web-first**, `expect(locator).toHaveText(...)` e suas parentes, é uma espera explícita cuja condição
é a própria asserção. O tempo limite dela é de cinco segundos por padrão. O intervalo não é um
número fixo. O código instalado confere na hora, depois de novo após 100, 250, 500 e 1000 ms, e
daí a cada segundo: uma resposta rápida é vista rápido, e uma lenta não custa uma consulta a cada
poucos milissegundos. Essa conta é a contagem de todo registro de chamadas: uma
olhada, depois olhadas aos 100, 350 e 850 ms, depois uma por segundo, dá os *9 ×* que a aula 3
imprimiu em cinco segundos.

`locator.waitFor()` é o outro. Ele espera um elemento chegar a um **estado**, `attached`,
`detached`, `visible` ou `hidden`, `visible` se você não disser outro, e não confere nada do texto
nem do valor. Serve para um passo cuja linha seguinte não é uma asserção:

```javascript
await page.locator('body[data-ready="true"]').waitFor({ state: 'attached' });
```

O estado faz diferença aqui: o `<body>` conta como visível, mas um elemento marcador escondido por
CSS nunca seria, e um `waitFor()` sem estado esperaria por ele até estourar.

**Prefira a asserção quando a espera é a verificação, e `waitFor` quando ela é só uma porta antes de
uma ação.** As duas são explícitas, as duas têm tempo limite, as duas param no instante em que a
condição vale. Quando nenhuma condição pronta serve, a próxima seção escreve uma.
