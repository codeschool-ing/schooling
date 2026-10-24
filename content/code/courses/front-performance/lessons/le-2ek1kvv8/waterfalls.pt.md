---
title: Cascatas
version: 1
---

**Uma cascata são as requisições de uma página desenhadas como barras ao longo do tempo**, uma linha por
requisição, na ordem em que começaram. O relatório do Lighthouse tem uma, a trilha Network do painel é
uma, e o WebPageTest é conhecido pela dele. É o gráfico que mostra **o que esperou pelo quê**, coisa que
nenhum número sozinho mostra.

O `tools/waterfall.ts` desenha uma no terminal: cada linha é uma requisição, com quando terminou,
quantos bytes vieram pela rede, e uma barra de um `#` a cada 50 milissegundos. Salve-o em `tools/`:

```typescript
// tools/waterfall.ts: load a page in Chromium and draw every request it made as
// a bar along time, the way a waterfall chart does.
//
//   node tools/waterfall.ts URL [--slow]
//
// --slow  every request waits 300 ms longer, as in look.ts
import { chromium } from "playwright";

const [url, ...rest] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
if (rest.includes("--slow")) {
  const cdp = await page.context().newCDPSession(page);
  await cdp.send("Network.emulateNetworkConditions", {
    offline: false, latency: 300, downloadThroughput: -1, uploadThroughput: -1,
  });
}
const rows: { path: string; start: number; end: number; bytes: number }[] = [];
page.on("requestfinished", async (request) => {
  const t = request.timing();
  const sizes = await request.sizes();
  rows.push({ path: new URL(request.url()).pathname, start: t.startTime, end: t.startTime + t.responseEnd,
    bytes: sizes.responseBodySize });
});
await page.goto(url, { waitUntil: "networkidle" });
await browser.close();

// One character for every 50 ms, counted from the start of the first request.
const zero = Math.min(...rows.map((r) => r.start));
for (const r of rows.sort((a, b) => a.start - b.start)) {
  const from = Math.round((r.start - zero) / 50), to = Math.max(from + 1, Math.round((r.end - zero) / 50));
  const bar = " ".repeat(from) + "#".repeat(to - from);
  console.log(`${r.path.padEnd(28)} ${String(Math.round(r.end - zero)).padStart(5)} ms ${String(r.bytes).padStart(7)} B  ${bar}`);
}
```

## Dois planners, uma página

A aula 1 construiu o planner duas vezes: renderizado no navegador, como o `vite preview` o serve, e
renderizado pelo `server.ts`. Inicie o preview num segundo terminal e depois desenhe a página de curso a
partir de cada um, com toda requisição 300 milissegundos mais lenta:

```
ana@dev:~/planner$ npx vite preview --port 4173 --strictPort
  ➜  Local:   http://localhost:4173/
  ➜  Network: use --host to expose
```

```
ana@dev:~/planner$ node tools/waterfall.ts http://localhost:3000/courses/git --slow
/courses/git                   304 ms     753 B  ######
/assets/index-C9VFYfGa.js      621 ms    6689 B        ######
/assets/index-CGM1waBA.css     621 ms     274 B        ######
ana@dev:~/planner$ node tools/waterfall.ts http://localhost:4173/courses/git --slow
/courses/git                   305 ms     515 B  ######
/assets/index-C9VFYfGa.js      623 ms    6694 B        ######
/assets/index-CGM1waBA.css     623 ms     371 B        ######
/courses.json                  928 ms     725 B              #######
/notice.json                  1246 ms      78 B                     ######
```

**Dois degraus para a página do servidor, quatro para a do navegador.** O HTML do servidor cita o script
e a folha de estilo, e o navegador pede os dois de uma vez, então eles dividem um degrau. A página
renderizada no navegador ainda precisa rodar o script antes de saber que precisa do `courses.json`, e
precisa ter o plano antes de pedir o `notice.json`: cada um é uma ida e volta que não podia começar
antes de a anterior terminar. O Lighthouse chamou isso de **network dependency tree**, e é o motivo de uma
página renderizada no navegador ser lenta numa rede lenta seja qual for o tamanho dela: **a latência se
soma ao longo de uma corrente, e banda não a encurta.**

## Lendo uma

- **Uma escada é uma corrente.** Cada degrau que começa onde outro terminou é uma requisição descoberta
  tarde. As correções são pôr o que a página precisa na primeira resposta, como o `server.ts` faz com o
  plano e o aviso, ou avisar o navegador cedo, que a aula 7 faz com `preload`.
- **Uma barra longa é uma resposta grande ou lenta.** Comprimi-la, como esta aula fez, ou diminuí-la
  encurta a barra e não a corrente.
- **Barras lado a lado são paralelas**, e custam uma ida e volta entre elas.

Os bytes também merecem um olhar: o `vite preview` comprime o que manda e o `server.ts`, desde esta
aula, também, então o script tem uns 6,7 kilobytes pela rede nos dois, contra os dezessete que tem no
disco. Pare o preview com Ctrl-C quando terminar.
