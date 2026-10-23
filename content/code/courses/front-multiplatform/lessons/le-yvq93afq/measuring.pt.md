---
title: Medindo o teto antes da loja
version: 1
---

**Um app embrulhado é tão rápido quanto a página dentro dele, no celular onde ela roda**, e os celulares
que as pessoas têm são mais lentos que o computador onde você constrói. O jeito mais barato de ver o teto
chegando é medir o planner no seu próprio computador com o processador desacelerado, como as
ferramentas de desenvolvimento do Chrome oferecem exatamente para isso, e com mais dados do que a
demonstração tem.

O `ceiling.mjs` faz as duas coisas. Ele salva um plano de N sessões onde o planner procura primeiro,
desacelera o processador e mede dois toques, do clique até o quadro seguinte desenhado. Salve-o ao lado
do `look.mjs`:

```javascript
// ceiling.mjs: how long the planner takes to answer a tap when a course has N
// sessions, on a processor slowed down the way DevTools slows it for a phone.
//
//   node ceiling.mjs URL N [SLOWDOWN]
//
// It saves a plan of N sessions where the planner looks first, reloads, and
// times two taps: opening the course, and marking its first session done. A
// tap is timed from the click to the next frame the browser paints.
import { chromium } from "playwright";

const [url, n, slowdown = "4"] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
const cdp = await page.context().newCDPSession(page);
await cdp.send("Emulation.setCPUThrottlingRate", { rate: Number(slowdown) });
await page.goto(url);
await page.evaluate((n) => {
  const plan = { courses: [{ id: "spanish", name: "Spanish A2" }], sessions: [] };
  for (let i = 1; i <= n; i++) {
    plan.sessions.push({ id: `s${i}`, course: "spanish", date: "2026-10-21", minutes: 30, done: false });
  }
  localStorage.setItem("CapacitorStorage.plan", JSON.stringify(plan));
}, Number(n));
await page.reload();
const tap = (name) => page.evaluate(async (name) => {
  const button = [...document.querySelectorAll("button")].find((b) => b.textContent === name);
  const start = performance.now();
  button.click();
  await new Promise((painted) => requestAnimationFrame(() => setTimeout(painted)));
  return Math.round(performance.now() - start);
}, name);
const open = await tap("Spanish A2");
const done = await tap("Mark done");
console.log(`${n} sessions, processor slowed ${slowdown}x: open ${open} ms, mark done ${done} ms`);
await browser.close();
```

Ele mede o site construído e não o servidor de desenvolvimento, que acrescenta trabalho próprio. O `npm
run preview` serve a `dist/` na porta 4173, do jeito que um host estático serviria; inicie-o num
terminal só dele, depois de `npm run build`, e rode a medida em três tamanhos, com o processador quatro
vezes mais lento, e uma vez em velocidade normal:

```
ana@dev:~/planner$ node ceiling.mjs 'http://localhost:4173/?today=2026-10-21' 50
50 sessions, processor slowed 4x: open 56 ms, mark done 20 ms
ana@dev:~/planner$ node ceiling.mjs 'http://localhost:4173/?today=2026-10-21' 500
500 sessions, processor slowed 4x: open 145 ms, mark done 88 ms
ana@dev:~/planner$ node ceiling.mjs 'http://localhost:4173/?today=2026-10-21' 5000
5000 sessions, processor slowed 4x: open 920 ms, mark done 1058 ms
ana@dev:~/planner$ node ceiling.mjs 'http://localhost:4173/?today=2026-10-21' 5000 1
5000 sessions, processor slowed 1x: open 167 ms, mark done 175 ms
```

**O tempo cresce com o número de sessões**: com cinquenta, um toque responde em alguns centésimos de
segundo, e com cinco mil leva cerca de um segundo no processador desacelerado, tempo bastante para uma
pessoa tocar de novo. Em velocidade normal o mesmo toque leva uma fração disso, e é por isso que ele
nunca aparece no computador onde foi escrito.

## De quem é o teto

Esta é a coisa mais útil que a medida diz: **a lentidão é do planner, não da WebView**. O `render()` joga
a tela inteira fora e a constrói de novo a cada mudança, e o `savePlan()` escreve o plano inteiro como
um texto só toda vez. Com cinquenta sessões isso não custa nada; com cinco mil é o custo inteiro. Um app
nativo escrito do mesmo jeito também seria lento.

As soluções são técnicas web: atualizar só o item que mudou, desenhar só as linhas que estão na tela, o
que se chama **virtualizar** uma lista, e guardar dados grandes num arquivo ou num banco em vez de numa
preferência. A `FlatList` do React Native, na aula 8, virtualiza por padrão, que é uma das coisas reais
que o caminho nativo compra. **Meça primeiro, depois decida se é um problema da WebView**: na maioria das
vezes não é, e uma reescrita levaria o mesmo desenho para uma plataforma nova.

O que a medida não consegue mostrar é o próprio celular. Um processador de desktop desacelerado é um
modelo grosseiro de um celular barato, não o celular: a memória, a GPU e a versão da WebView mudam. O
modelo serve para uma coisa, descobrir cedo que um desenho não vai escalar, e **o teste de verdade é um
celular Android barato**, na mão, rodando o build de lançamento.
