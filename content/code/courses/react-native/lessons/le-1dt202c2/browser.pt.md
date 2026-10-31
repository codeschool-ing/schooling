---
title: Uma posição vinda do Playwright
version: 1
---

**Na web, o `expo-location` pergunta ao navegador**, pelo mesmo `navigator.geolocation` que toda página
usa, e um navegador pergunta à pessoa exatamente como um celular. O Playwright pode responder pela pessoa:
um context pode receber a permissão `geolocation` e uma posição, que é do que o teste de um recurso de
localização precisa. Salve o `where.mjs`:

```javascript
// where.mjs: on This week, turn on "Note where I study", mark a session done, and print what the screen
// says. The browser is given a position, as a phone's GPS would give one, unless --deny is passed.
//
//   node where.mjs URL BUTTON [--deny]
import { chromium } from "playwright";

const [url, button, flag] = process.argv.slice(2);
const browser = await chromium.launch();
const context = await browser.newContext(
  flag === "--deny" ? {} : { permissions: ["geolocation"], geolocation: { latitude: -23.561414, longitude: -46.655881 } },
);
const page = await context.newPage();
await page.goto(url);
const toggle = page.getByRole("switch", { name: "Note where I study" });
await toggle.click();
await page.waitForTimeout(1000);
console.log("switch on:", await toggle.isChecked());
const alert = page.getByRole("alert");
if (await alert.count()) console.log("alert:", await alert.innerText());
await page.getByRole("button", { name: button }).click();
await page.getByText(/^Logged on this phone: /).waitFor();
for (const line of await page.getByText(/^Logged on this phone: |^Studied at /).allInnerTexts()) console.log(line);
await browser.close();
```

A posição é uma rua de São Paulo, com seis casas decimais, como um GPS daria. Suba o servidor, exporte e
sirva com o `static.mjs` da aula 14, já que o diário é SQLite:

```
ana@dev:~/planner$ node where.mjs 'http://localhost:8082/week?today=2026-10-21' 'Mark 20 min on 2026-10-21 done'
switch on: true
Logged on this phone: Guitar 20 min
Studied at -23.56, -46.66 (1)
ana@dev:~/planner$ node where.mjs 'http://localhost:8082/week?today=2026-10-21' 'Mark 30 min on 2026-10-22 done' --deny
switch on: false
alert: Without your location, sessions are logged without a place. You can allow it in Settings.
Logged on this phone: Spanish A2 30 min
```

**O primeiro navegador foi permitido e recebeu uma posição; o diário guardou `-23.56, -46.66`**, duas das
seis casas decimais. O segundo nunca recebeu nada, então o navegador recusou quando perguntado, a chave
ficou desligada, o alerta disse o que isso quer dizer, e a sessão foi registrada mesmo assim, sem lugar. É
um navegador novo, então o diário dele tem só essa sessão.

*O que um navegador não mostra é o diálogo do próprio celular, com a escolha entre precisa e aproximada; o
comportamento do planner não depende de qual a pessoa escolhe, e este curso não viu nenhum dos dois
diálogos.*
