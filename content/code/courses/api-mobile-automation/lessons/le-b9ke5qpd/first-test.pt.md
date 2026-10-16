---
title: Um primeiro teste para o Tickets
version: 1
---

**Um teste é a sessão da seção 04 escrita em código, com verificações entre os passos.** O
WebdriverIO manda as mesmas requisições que o curl mandou, e acrescenta a espera, as mensagens de
erro e um pouco de sintaxe. O executor de testes é o que o Node já traz, o `node:test`, que a lição
12 usa na metade da API. Um teste é uma função, `before` e `after` rodam
em volta, e o `assert` confere um valor.

O teste abre o Tickets no emulador, espera a lista, toca no terceiro espetáculo e confere que a tela
do espetáculo diz quantos lugares restam. Esse número não está escrito no teste. **Ele pergunta ao
boxoffice**, porque os lugares do `sh-103` dependem do que testes anteriores compraram. Um teste
que esperasse `4` passaria depois de um reinício e falharia depois de um pedido. A tela e a API
precisam concordar, seja qual for o número, e essa concordância é a razão de ser do teste.

## O que ele precisa

- o boxoffice rodando, como em toda lição desta metade;
- o emulador rodando, sem nada mais conectado, ou o `appium:udid` acrescentado para dizer qual
  aparelho;
- o Tickets compilado. Um Run da lição 14 o compila, e também o `./gradlew assembleDebug` digitado
  na pasta `tickets`, ou o `.\gradlew.bat assembleDebug` no PowerShell. Os dois gravam o APK de debug em
  `tickets/app/build/outputs/apk/debug/app-debug.apk`, que é para onde as capabilities apontam. O
  Appium o instala no aparelho quando a sessão começa;
- o servidor do Appium da seção 03, rodando.

## O teste

Salve como `appium/tickets.test.mjs`:

```js
// appium/tickets.test.mjs: Tickets on the emulator, driven from outside by Appium
import assert from 'node:assert/strict';
import path from 'node:path';
import { after, before, test } from 'node:test';
import { remote } from 'webdriverio';

const ID = 'id=example.tickets:id/';
let driver;

before(async () => {
  driver = await remote({
    hostname: '127.0.0.1',
    port: 4723,
    logLevel: 'warn',
    capabilities: {
      platformName: 'Android',
      'appium:automationName': 'UiAutomator2',
      'appium:app': path.resolve('tickets/app/build/outputs/apk/debug/app-debug.apk'),
    },
  });
});

after(async () => {
  await driver?.deleteSession();
});

test('the third show opens with the seats boxoffice reports', async () => {
  await driver.$(ID + 'title').waitForDisplayed({ timeout: 15000 });
  const titles = await driver.$$(ID + 'title');
  assert.equal(titles.length, 3);
  await titles[2].click();

  const seats = driver.$(ID + 'seats');
  await seats.waitForDisplayed({ timeout: 5000 });
  assert.equal(await driver.$(ID + 'title').getText(), 'O Pagador de Promessas');

  const show = await (await fetch('http://localhost:8080/v1/shows/sh-103')).json();
  assert.equal(await seats.getText(), `${show.seats_left} seats left`);
});
```

```schooling-example
{
 "language": "js",
 "file": "tickets.test.mjs",
 "parts": [
  {
   "code": "const ID = 'id=example.tickets:id/';",
   "note": "O WebdriverIO lê a estratégia no começo da string: `id=` é o resource id. O nome do pacote faz parte do id, como a lição 14 disse, então entra uma vez aqui."
  },
  {
   "code": "before(async () => {\n  driver = await remote({\n    hostname: '127.0.0.1',\n    port: 4723,\n    logLevel: 'warn',",
   "note": "`remote` é o `POST /session` da seção 04. Ele retorna quando o servidor tem uma sessão, o que no Android quer dizer que o app está instalado e aberto. `logLevel: 'warn'` impede o WebdriverIO de imprimir cada requisição."
  },
  {
   "code": "    capabilities: {\n      platformName: 'Android',\n      'appium:automationName': 'UiAutomator2',\n      'appium:app': path.resolve('tickets/app/build/outputs/apk/debug/app-debug.apk'),\n    },\n  });\n});",
   "note": "As capabilities da seção 02. O caminho vira absoluto porque o teste e o servidor podem ter sido iniciados em pastas diferentes."
  },
  {
   "code": "after(async () => {\n  await driver?.deleteSession();\n});",
   "note": "O `DELETE` da seção 04, no `after`, que roda tenha o teste passado ou falhado. O `?.` o pula quando a sessão nem começou."
  },
  {
   "code": "  await driver.$(ID + 'title').waitForDisplayed({ timeout: 15000 });\n  const titles = await driver.$$(ID + 'title');\n  assert.equal(titles.length, 3);\n  await titles[2].click();",
   "note": "Espere até o título da primeira linha estar na tela, depois pegue todos. `$` encontra um elemento, `$$` todos os que correspondem. As linhas contam a partir de 0, então `titles[2]` é o terceiro espetáculo."
  },
  {
   "code": "  const seats = driver.$(ID + 'seats');\n  await seats.waitForDisplayed({ timeout: 5000 });\n  assert.equal(await driver.$(ID + 'title').getText(), 'O Pagador de Promessas');",
   "note": "A tela do espetáculo é uma tela nova, então espere por ela também. O título dela também tem o id `title`, e agora que a lista sumiu, é o único."
  },
  {
   "code": "  const show = await (await fetch('http://localhost:8080/v1/shows/sh-103')).json();\n  assert.equal(await seats.getText(), `${show.seats_left} seats left`);",
   "note": "O texto esperado é montado a partir da resposta do boxoffice, com as palavras do `strings.xml`. O `getText` também é uma requisição: o Appium lê o texto do aparelho naquele momento."
  }
 ]
}
```

Rode com o executor de testes do Node, a partir de `~/boxoffice`. O `--test-reporter=tap` pede o
relatório TAP em texto puro, que é o que as transcrições deste curso imprimem. Sem ele o Node
desenha um relatório próprio com símbolos, e diz as mesmas coisas:

```sh
node --test --test-reporter=tap appium/tickets.test.mjs
```

No seu computador, com o emulador aberto, o app aparece nele e a lista carrega. A terceira
linha é tocada, a tela do espetáculo abre e o executor relata um teste aprovado. **Essa execução não
foi gravada para este curso.** O app nunca foi compilado na máquina de gravação, e a lição 14 mostrou
que nenhum emulador consegue iniciar lá. O que foi gravado é o mesmo comando naquela máquina, onde o Appium
não tinha onde instalar o app:

```
ana@laptop:~/boxoffice$ node --test --test-reporter=tap appium/tickets.test.mjs
TAP version 13
# 2026-10-16T01:20:41.067Z WARN webdriver: WebDriverError: Could not find a connected Android device in 20000ms when running "http://127.0.0.1:4723/session" with method "POST"
# 2026-10-16T01:21:01.613Z WARN webdriver: WebDriverError: Could not find a connected Android device in 20000ms when running "http://127.0.0.1:4723/session" with method "POST"
# 2026-10-16T01:21:22.653Z WARN webdriver: WebDriverError: Could not find a connected Android device in 20000ms when running "http://127.0.0.1:4723/session" with method "POST"
# 2026-10-16T01:21:42.685Z ERROR webdriver: WebDriverError: Could not find a connected Android device in 20000ms when running "http://127.0.0.1:4723/session" with method "POST"
# 2026-10-16T01:21:42.686Z ERROR webdriver: unknown error: WebDriverError: Could not find a connected Android device in 20000ms when running "http://127.0.0.1:4723/session" with method "POST"
#     at FetchRequest._request (file:///home/ana/boxoffice/node_modules/webdriver/build/node.js:2316:19)
#     at process.processTicksAndRejections (node:internal/process/task_queues:105:5)
#     at async startWebDriverSession (file:///home/ana/boxoffice/node_modules/webdriver/build/node.js:1376:16)
#     at async _WebDriver.newSession (file:///home/ana/boxoffice/node_modules/webdriver/build/node.js:1805:41)
#     at async remote (file:///home/ana/boxoffice/node_modules/webdriverio/build/node.js:10947:20)
#     at async TestContext.<anonymous> (file:///home/ana/boxoffice/appium/tickets.test.mjs:11:12)
#     at async TestHook.run (node:internal/test_runner/test:1054:7)
# Subtest: the third show opens with the seats boxoffice reports
not ok 1 - the third show opens with the seats boxoffice reports
  ---
  duration_ms: 84717.075108
  type: 'test'
  location: '/home/ana/boxoffice/appium/tickets.test.mjs:27:1'
  failureType: 'hookFailed'
  error: 'WebDriverError: Could not find a connected Android device in 20000ms when running "http://127.0.0.1:4723/session" with method "POST"'
  code: 'ERR_TEST_FAILURE'
  stack: |-
    startWebDriverSession (file:///home/ana/boxoffice/node_modules/webdriver/build/node.js:1380:11)
    process.processTicksAndRejections (node:internal/process/task_queues:105:5)
    async _WebDriver.newSession (file:///home/ana/boxoffice/node_modules/webdriver/build/node.js:1805:41)
    async remote (file:///home/ana/boxoffice/node_modules/webdriverio/build/node.js:10947:20)
    async TestContext.<anonymous> (file:///home/ana/boxoffice/appium/tickets.test.mjs:11:12)
    async TestHook.run (node:internal/test_runner/test:1054:7)
  ...
1..1
# tests 1
# suites 0
# pass 0
# fail 1
# cancelled 0
# skipped 0
# todo 0
# duration_ms 85108.994189
```

**A falha é da sessão, não do teste**, e o relatório diz isso: `failureType: 'hookFailed'`, o hook
`before` que chama o `remote`. O driver UiAutomator2 pediu um aparelho ao adb e não achou nenhum em
20 segundos. O WebdriverIO repete uma sessão que não consegue iniciar, e tentou mais três vezes.
São as quatro primeiras linhas, com uns vinte segundos entre elas, e o motivo de a execução ter
levado 85 segundos para falhar. Num pipeline, onde ninguém vai ligar o emulador no meio do caminho,
`connectionRetryCount: 0` ao lado do `logLevel` faz o teste falhar na primeira resposta.

**Este também é o primeiro erro que a maioria das pessoas encontra com um aparelho de verdade.** A
causa quase sempre é que o emulador não estava rodando quando o teste começou, ou que o
`adb devices` não lista nada mesmo com ele aberto. A seção de falhas da lição 14 tem a correção para
os dois casos.

## No iOS

O mesmo teste num simulador de iPhone precisa de um Mac, do Xcode e do driver XCUITest do Appium, e
de um app cujos elementos tenham accessibility identifiers. As capabilities mudam e as requisições
não. Isto não foi executado para este curso, que não tem Mac:

```js
capabilities: {
  platformName: 'iOS',
  'appium:automationName': 'XCUITest',
  'appium:deviceName': 'iPhone 16',
  'appium:app': path.resolve('Tickets.app'),
},
```

A lição 18 trata de testar no iOS, e diz quanto custa um Mac.
