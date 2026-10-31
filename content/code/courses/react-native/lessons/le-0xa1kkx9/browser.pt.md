---
title: Três navegadores, três respostas
version: 1
---

Na web o módulo pergunta ao `Intl`, e uma página do Playwright pode ser aberta em qualquer locale. Salve o
`note.mjs`:

```javascript
// note.mjs: open the planner in a browser set to a locale, and print what it says about the week.
//
//   node note.mjs URL LOCALE
import { chromium } from "playwright";

const [url, locale] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage({ locale });
await page.goto(url);
console.log(`${locale}:`, await page.getByText(/^Your phone's calendar/).innerText());
await browser.close();
```

Suba o servidor, exporte, e sirva com o `static.mjs`, depois abra o planner em português do Brasil, inglês
britânico e português europeu:

```
ana@dev:~/planner$ node note.mjs 'http://localhost:8082/?today=2026-10-21' pt-BR
pt-BR: Your phone's calendar starts the week on Sunday; the planner's weeks start on Monday.
ana@dev:~/planner$ node note.mjs 'http://localhost:8082/?today=2026-10-21' en-GB
en-GB: Your phone's calendar starts the week on Monday; the planner's weeks start on Monday.
ana@dev:~/planner$ node note.mjs 'http://localhost:8082/?today=2026-10-21' pt-PT
pt-PT: Your phone's calendar starts the week on Sunday; the planner's weeks start on Monday.
```

**O Brasil diz domingo, o Reino Unido segunda, e Portugal domingo**, a mesma resposta que a JVM deu. Três
implementações, o calendário do Java, o `Intl` do Chromium e, num celular, o do Android ou o da Apple,
concordam porque leem os mesmos dados do CLDR. Quando o módulo e o navegador discordam do que você esperava,
confira os dados antes do código.
