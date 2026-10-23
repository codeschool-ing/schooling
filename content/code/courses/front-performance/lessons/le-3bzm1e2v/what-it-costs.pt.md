---
title: Quanto a hidratação custa ao processador
version: 1
---

**A hidratação roda os componentes da página mais uma vez, no navegador, para descobrir o que o
servidor já sabia.** No planner isso é uma chamada de função. Num framework é a árvore inteira de
componentes, reconstruída na memória e percorrida sobre os elementos existentes. Num notebook é rápido
o bastante para não se notar, e os visitantes para quem isso importa estão em celulares, cujos
processadores são várias vezes mais lentos.

O Chromium consegue deixar o próprio processador mais lento. O `tools/cpu.ts` abre uma página com o
processador quatro vezes mais lento, que é mais ou menos um celular intermediário perto do notebook
onde isto foi gravado, e informa dois contadores do próprio Chromium: o tempo rodando JavaScript, e o
tempo de todas as tarefas da thread principal, com interpretação, estilo, layout e pintura incluídos.
Cada número é a mediana de cinco cargas novas, porque uma carga só tem ruído demais. Salve em
`tools/`:

```typescript
// tools/cpu.ts: how much work the browser's main thread did to open a page,
// on a processor slowed four times, as a mid-range phone is next to a laptop.
//
//   node tools/cpu.ts URL...
//
// "script" is time spent running JavaScript; "all" is every task on the main
// thread: parsing, style, layout, painting and the scripts. Both come from
// Chromium's own counters, and each is the median of five fresh loads.
import { chromium } from "playwright";

const browser = await chromium.launch();
const median = (xs: number[]) => xs.sort((a, b) => a - b)[Math.floor(xs.length / 2)];
console.log(" script ms   all ms  address");
for (const url of process.argv.slice(2)) {
  const script: number[] = [], all: number[] = [];
  for (let run = 0; run < 5; run++) {
    const page = await browser.newPage();
    const cdp = await page.context().newCDPSession(page);
    await cdp.send("Emulation.setCPUThrottlingRate", { rate: 4 });
    await cdp.send("Performance.enable");
    await page.goto(url, { waitUntil: "networkidle" });
    const { metrics } = await cdp.send("Performance.getMetrics");
    const ms = (name: string) => Math.round(1000 * metrics.find((m) => m.name === name)!.value);
    script.push(ms("ScriptDuration"));
    all.push(ms("TaskDuration"));
    await page.close();
  }
  console.log(`${String(median(script)).padStart(7)}  ${String(median(all)).padStart(7)}  ${url}`);
}
await browser.close();
```

Com o `server.ts` do planner na 3000 e os quatro servidores da aula 2 da 3001 à 3004, todos com o
build do jeito que a aula 3 os deixou, abra a mesma página de curso em cada um:

```
ana@dev:~/planner$ node tools/cpu.ts http://localhost:3000/courses/git http://localhost:3001/courses/git http://localhost:3002/courses/git http://localhost:3003/courses/git http://localhost:3004/courses/git
 script ms   all ms  address
     47      154  http://localhost:3000/courses/git
    131      557  http://localhost:3001/courses/git
     73      370  http://localhost:3002/courses/git
     51      233  http://localhost:3003/courses/git
     77      307  http://localhost:3004/courses/git
```

## Lendo isso

**O Next.js de novo custa mais e o SvelteKit menos, mas não na proporção do que mandaram.** O
Next.js mandou umas cinco vezes o JavaScript do SvelteKit na aula 2, e rodou umas duas vezes e meia o
tempo de script dele aqui, 131 milissegundos contra 51. E o SvelteKit mediu pouco mais que os 47 do
planner puro, com 89 KB contra 2,8: neste tamanho os contadores medem o que qualquer página com script
custa para começar, tanto quanto o framework, e só a diferença grande fica clara acima disso. Com o que os números concordam é com a
escala: uma página com dois links e duas sessões custa a um processador mais lento dezenas de
milissegundos para ser assumida, e uma página de verdade, com cem componentes, custa
proporcionalmente mais, tudo isso enquanto a página parece pronta.

A aula 5 dá um nome a esse custo, como parte de quão rápido uma página responde a um toque, e a aula
6 abre o mesmo trabalho no painel de performance do Chromium, tarefa por tarefa.
