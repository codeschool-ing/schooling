---
title: Medindo o planner
version: 1
---

**A biblioteca `web-vitals` mede as três métricas dentro da página, exatamente como as próprias
ferramentas do Google**, a partir das mesmas APIs do navegador, e chama uma função com cada valor. Ela
é do Google, é pequena, e é a que este curso usa. Instale-a no planner, como dependência do app desta
vez e não como ferramenta, porque ela roda no navegador de cada visitante:

```
ana@dev:~/planner$ npm install --save-exact web-vitals@6.2.3

added 1 package, and audited 22 packages in 471ms

9 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

## Informando a partir da página

O `src/vitals.ts` pede as três e imprime cada uma no console conforme muda. Ele usa a versão de
**attribution** da biblioteca, que acrescenta a cada valor o elemento ou a interação que o causou, e
para o INP as três partes da seção "INP: quanto um toque espera". O `reportAllChanges` faz ela informar
cada valor novo em vez de só o final, que é o que você quer enquanto observa:

```typescript
// src/vitals.ts: measure the three Core Web Vitals of this page, as a visitor's
// browser lives through them, and say each one on the console as it changes.
import { onCLS, onINP, onLCP } from "web-vitals/attribution";

onLCP((m) => console.log(`[vitals] LCP ${Math.round(m.value)} ms ${m.rating} ${m.attribution.target ?? ""}`),
  { reportAllChanges: true });
onINP((m) => {
  const a = m.attribution;
  const parts = [a.inputDelay, a.processingDuration, a.presentationDelay].map(Math.round);
  console.log(`[vitals] INP ${Math.round(m.value)} ms ${m.rating} ${a.interactionTarget ?? ""}`
    + ` (input ${parts[0]}, processing ${parts[1]}, presentation ${parts[2]})`);
}, { reportAllChanges: true });
onCLS((m) => console.log(`[vitals] CLS ${m.value.toFixed(3)} ${m.rating} ${m.attribution.largestShiftTarget ?? ""}`),
  { reportAllChanges: true });
```

## Algo de verdade para medir

Uma página de verdade tem algo que chega no seu próprio tempo. O planner ganha **um aviso da semana**,
de um arquivo que o servidor entrega, mostrado acima da página. Salve como `public/notice.json`:

```json
{ "text": "New this week: every course page shows the day of each session." }
```

O `index.html` ganha um lugar para ele, um parágrafo acima do `<main>`; acrescente esta linha logo
antes de `<main id="app"></main>`:

```html
    <p class="notice" id="notice"></p>
```

E duas regras no fim do `src/style.css`, uma para o aviso e uma que impede o parágrafo vazio de ocupar
espaço:

```css
.notice { margin: 0 0 1rem; padding: 0.75rem 1rem; background: #fef3c7; border-radius: 0.5rem; }
.notice:empty { padding: 0; margin: 0; }
```

O `src/main.ts` carrega o `vitals.ts` primeiro, para a medida começar antes de todo o resto, e
preenche o aviso no final. Ele está escrito para a seção depois da próxima, que faz o servidor
preencher o aviso, então o script só o busca quando o parágrafo ainda está vazio:

```typescript
// src/main.ts: take the plan the server put in the page, or fetch it, and hand it to the view.
import "./style.css";
import "./vitals.ts";
import type { Plan } from "./planner.ts";
import { mount } from "./view.ts";

const embedded = document.getElementById("plan");
const plan: Plan = embedded
  ? JSON.parse(embedded.textContent!)
  : await (await fetch("/courses.json")).json();
mount(document.querySelector<HTMLElement>("#app")!, plan);

// This week's notice: written by the server when it can, fetched here when it was not.
const box = document.getElementById("notice")!;
if (!box.textContent) {
  const notice: { text: string } = await (await fetch("/notice.json")).json();
  box.textContent = notice.text;
}
```

`textContent` e não `innerHTML`, porque o aviso é texto vindo de um servidor e não deve ser lido como
HTML.

## A ferramenta

O `tools/vitals.ts` abre uma página, se quiser como celular, com a rede ou o processador mais lentos,
e com um clique; depois imprime o último valor que a página informou para cada métrica. Salve em
`tools/`:

```typescript
// tools/vitals.ts: open a page in Chromium and print the last value the page's
// own web-vitals code reported for each metric.
//
//   node tools/vitals.ts URL [--phone] [--slow] [--cpu N] [--click SELECTOR]
//
// --phone      a window 390 pixels wide and 844 high, the size of a common phone
// --slow       every request waits 300 ms longer, as in look.ts
// --cpu N      the processor runs N times slower, as in cpu.ts
// --click SEL  one second after loading, click the element SEL, as a person would
import { chromium } from "playwright";

const [url, ...rest] = process.argv.slice(2);
const option = (name: string) => (rest.includes(name) ? rest[rest.indexOf(name) + 1] : null);
const browser = await chromium.launch();
const page = await browser.newPage(
  rest.includes("--phone") ? { viewport: { width: 390, height: 844 } } : {});
const cdp = await page.context().newCDPSession(page);
if (rest.includes("--slow")) {
  await cdp.send("Network.emulateNetworkConditions", {
    offline: false, latency: 300, downloadThroughput: -1, uploadThroughput: -1,
  });
}
if (option("--cpu")) await cdp.send("Emulation.setCPUThrottlingRate", { rate: Number(option("--cpu")) });
const last = new Map<string, string>();
page.on("console", (m) => {
  const [tag, name] = m.text().split(" ");
  if (tag === "[vitals]") last.set(name, m.text());
});
await page.goto(url, { waitUntil: "networkidle" });
await page.waitForTimeout(1000);
if (option("--click")) {
  await page.click(option("--click")!);
  await page.waitForTimeout(1000);
}
for (const line of last.values()) console.log(line);
// Leaving the page is what makes a page send its final values, as a visitor's would.
await page.goto("about:blank");
await browser.close();
```

Faça o build, reinicie o `server.ts` com `TZ=UTC` como na aula 4, e meça uma página de curso numa
janela do tamanho de um computador, sem nada mais lento:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/courses/git
[vitals] LCP 100 ms good #notice
[vitals] CLS 0.007 good #app
```

Tudo bom, e nada a aprender: está tudo num computador só. As próximas duas seções deixam as coisas
mais lentas até cada métrica ter algo a dizer.
