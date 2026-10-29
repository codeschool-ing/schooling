---
title: Carregando o gráfico sob demanda
version: 1
---

**O `import()`, escrito como função, carrega um módulo quando a linha roda**, e não quando a página carrega.
Ele devolve uma promise do módulo, então `(await import("./chart.ts")).showChart(p)` busca o código do
gráfico na primeira vez que ele é necessário e o chama quando chega. E quando o Vite vê um `import()`, ele dá
àquele módulo, e ao que só ele importa, um arquivo próprio: um **chunk**.

No `src/main.ts`, apague a linha que importa o `showChart` e troque a chamada ao `mount` por:

```typescript
mount(document.querySelector<HTMLElement>("#app")!, plan, async (p) => {
  // The chart's code is fetched the first time a page needs it, and on no other page.
  if (location.pathname === "/stats") (await import("./chart.ts")).showChart(p);
});
```

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

**Três arquivos JavaScript agora.** O arquivo `index`, que toda página carrega, voltou para perto do tamanho
antigo. O chunk `chart` é o Chart.js e o `chart.ts`, e só `/stats` vai pedi-lo. O terceiro, `planner`, de
meio kilobyte, é o `planner.ts`: a entrada e o gráfico o importam, então o Vite o pôs num chunk próprio que os
dois podem dividir, em vez de uma cópia em cada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Os três arquivos do build dividido e que página carrega cada um. O index, 19.85 kilobytes, e o planner, 0.52, são carregados por toda página. O chart, 132.39 kilobytes, só é carregado pela página de estatísticas, quando o código dela o pede.\"><rect x=\"40\" y=\"40\" width=\"63.52000000000001\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"71.76\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">index · 19.85 kB</text><rect x=\"117.52000000000001\" y=\"40\" width=\"34\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"134.52\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">planner · 0.52 kB</text><rect x=\"165.52\" y=\"40\" width=\"423.64799999999997\" height=\"40\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"377.344\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">chart · 132.39 kB</text><text x=\"150\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">toda página: a de curso, a inicial</text><line x1=\"71.76\" y1=\"82\" x2=\"150\" y2=\"116\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"134.52\" y1=\"82\" x2=\"150\" y2=\"116\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"377.344\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">só /stats, depois do import() dela</text><line x1=\"377.344\" y1=\"82\" x2=\"377.344\" y2=\"116\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Antes da divisão, tudo isso era um arquivo, e toda página carregava o gráfico.</text></svg>", "caption": "O código que uma página não usa não é mais dela para baixar."}
```

Faça o build, reinicie o `server.ts` e olhe as duas páginas:

```
ana@dev:~/planner$ node tools/unused.ts http://localhost:3000/courses/git
/assets/index-yh2nfJj3.js       17.7 KB, ran   8.2 KB (46%)
```

**A página de curso não baixa Chart.js nenhum**, e a de estatísticas o baixa quando sabe que precisa. Isso é
toda a divisão de código: o código que uma página não usa não é dela para baixar.

## Onde ele chega

```
ana@dev:~/planner$ node tools/waterfall.ts http://localhost:3000/stats --slow
/stats                         306 ms    1102 B  ######
/fonts/plex-400.woff2          621 ms   22611 B        ######
/fonts/plex-700.woff2          621 ms   22842 B        ######
/assets/index-DKgaS_OS.js      626 ms    7611 B        #######
/assets/planner-BNdUlffC.js    625 ms     321 B        #######
/assets/chart-Cq-hfvCR.js      939 ms   46407 B               ######
```

**O chunk do gráfico chega um degrau depois do resto.** O navegador só descobre que `/stats` precisa dele
quando o `main.ts` roda e chega ao `import()`, o que é depois de o próprio script chegar: uma corrente, como
as cascatas da aula 6 a chamaram. O chunk `planner` não atrasa, porque o Vite escreveu uma linha para ele no
HTML:

```
ana@dev:~/planner$ grep -o '<link rel="modulepreload"[^>]*>' dist/index.html
<link rel="modulepreload" crossorigin href="/assets/planner-BNdUlffC.js">
```

O `modulepreload` é a dica da aula 7 para módulos: a entrada importa o `planner` estaticamente, então o
navegador pode buscar os dois de uma vez em vez de descobrir o segundo dentro do primeiro. Um módulo importado
com `import()` não ganha essa linha, porque se ele é necessário é decidido pelo código na hora de rodar. Esse
degrau a mais é o preço da divisão, e a próxima seção o mede do lado do visitante.
