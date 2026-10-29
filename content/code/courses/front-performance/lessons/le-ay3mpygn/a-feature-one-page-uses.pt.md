---
title: Um recurso que só uma página usa
version: 1
---

**O planner ganha um gráfico dos minutos estudados em cada semana**, numa página própria em `/stats`. O
gráfico é desenhado pelo **Chart.js**, uma biblioteca popular que desenha gráficos num canvas. Ela roda no
navegador do visitante, então é uma dependência do app, como o `web-vitals`:

```
ana@dev:~/planner$ npm install --save-exact chart.js@4.5.1

added 2 packages, and audited 148 packages in 684ms

34 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

O `src/chart.ts` desenha o gráfico no canvas da página. Ele importa o Chart.js do jeito que a documentação
dele começa, de `chart.js/auto`, que registra todo tipo de gráfico que a biblioteca tem. E marca quando
desenhou, como o `data-hydrated` faz, para uma ferramenta ler depois. Salve-o em `src/`:

```typescript
// src/chart.ts: the minutes of each week as a bar chart, drawn by Chart.js.
import { Chart } from "chart.js/auto";
import { weeks, weekTotal, type Plan } from "./planner.ts";

let chart: Chart | undefined;
export function showChart(plan: Plan): void {
  const labels = weeks(plan.sessions);
  chart?.destroy();
  chart = new Chart(document.querySelector<HTMLCanvasElement>("#chart")!, {
    type: "bar",
    data: { labels, datasets: [{ label: "minutes", data: labels.map((m) => weekTotal(plan.sessions, m)) }] },
    options: { animation: false },
  });
  // When it was drawn, for a tool to read, as data-hydrated says when the page was taken over.
  document.documentElement.dataset.chart = String(Math.round(performance.now()));
}
```

## A página

No `src/view.ts`, a página de estatísticas mostra um canvas e, embaixo dele, os mesmos totais como lista,
que é o que um leitor de tela lê e o que uma página sem o script mostra. Acrescente-a logo antes do
comentário que começa com `// The page an address names`:

```typescript
// The minutes of every week: the list, and a canvas the chart is drawn on in the browser.
export function statsPage(plan: Plan): string {
  const totals = weeks(plan.sessions).map((monday) => `<li>Week of ${monday}: ${weekTotal(plan.sessions, monday)} min</li>`);
  return `<p><a href="/">All courses</a></p>
<h1>Minutes per week</h1>
<canvas id="chart" width="640" height="320" role="img" aria-label="The minutes of each week, as bars"></canvas>
<ul class="weeks">${totals.join("")}</ul>`;
}
```

O `page` aprende o endereço novo. Troque-o, com o comentário, por:

```typescript
// The page an address names: /courses/<slug> is one course, /stats the weeks, anything else the list.
export function page(plan: Plan, path: string): string {
  const m = path.match(/^\/courses\/([a-z0-9-]+)$/);
  return m ? coursePage(plan, m[1]) : path === "/stats" ? statsPage(plan) : homePage(plan);
}
```

A página inicial aponta para ela. Troque a linha `<h2>Weeks</h2>` do `homePage` por:

```html
<h2>Weeks</h2>
<p><a href="/stats">Minutes per week</a></p>
```

## Desenhando depois de cada desenho

Um gráfico não é HTML: ele é desenhado por um script depois da página. Então o `mount` recebe um terceiro
argumento, uma função que ele chama toda vez que desenha a página. Troque as três primeiras linhas dele, até
a que define o `draw`, inclusive, por:

```typescript
export function mount(root: HTMLElement, start: Plan, drawn: (plan: Plan) => void = () => {}): void {
  let plan = start;
  // drawn is told every time the page has been drawn, so it can add what HTML cannot, such as a chart.
  const draw = () => { root.innerHTML = page(plan, location.pathname); drawn(plan); };
```

e as linhas do fim dele, de `if (!root.firstElementChild) {` até a que define o `data-hydrated`, por estas,
que também avisam o `drawn` quando a página do servidor estava certa do jeito que veio:

```typescript
  if (!root.firstElementChild) {
    draw();
  } else if (!same(root, page(plan, location.pathname))) {
    console.warn("hydration mismatch: the page the server sent is not the page this script draws; drawing again");
    draw();
  } else {
    drawn(plan);
  }
  document.documentElement.dataset.hydrated = String(Math.round(performance.now()));
```

Por fim, o `src/main.ts` passa essa função. Acrescente o import depois do de `view.ts`:

```typescript
import { showChart } from "./chart.ts";
```

e troque a chamada ao `mount` por:

```typescript
mount(document.querySelector<HTMLElement>("#app")!, plan, (p) => {
  if (location.pathname === "/stats") showChart(p);
});
```

## O que isso custou a toda página

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 9 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                  0.69 kB │ gzip: 0.35 kB
dist/assets/index-gserWk4t.css   0.76 kB │ gzip: 0.41 kB
dist/assets/index-yh2nfJj3.js   18.08 kB │ gzip: 6.95 kB

✓ built in 192ms
```

**De dezoito kilobytes para mais de duzentos**, e toda página paga. Faça o build, reinicie o `server.ts` e
pergunte a cobertura das duas páginas:

```
ana@dev:~/planner$ node tools/unused.ts http://localhost:3000/courses/git
/assets/index-yh2nfJj3.js       17.7 KB, ran   8.2 KB (46%)
```

**A página de curso roda cerca de um oitavo do que baixa.** Ela nunca desenha um gráfico, e baixou,
interpretou e compilou o Chart.js inteiro mesmo assim. Até a página de estatísticas roda menos da metade,
porque o `chart.js/auto` trouxe todo tipo de gráfico e esta página desenha um.
