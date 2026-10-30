---
title: Quando buscar
version: 1
---

**Código carregado sob demanda é código que alguém espera.** Da página inicial, um clique em *Minutes per
week* desenha a página de estatísticas na hora, a lista e um canvas vazio, e o gráfico uma ida e volta
depois. Quanto isso dura depende da rede, e o `tools/after-click.ts` mede: ele abre uma página, clica e lê a
marca que o `chart.ts` deixa quando desenha. Salve-o em `tools/`:

```typescript
// tools/after-click.ts: open a page, click something, and say how long after the
// click the chart was drawn, by the mark the page itself makes when it draws one.
//
//   node tools/after-click.ts URL SELECTOR [--slow] [--hover MS]
//
// --slow      every request waits 300 ms longer, as in look.ts
// --hover MS  rest the pointer on the element MS milliseconds before the click, as a person does
import { chromium } from "playwright";

const [url, selector, ...rest] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
if (rest.includes("--slow")) {
  const cdp = await page.context().newCDPSession(page);
  await cdp.send("Network.emulateNetworkConditions", {
    offline: false, latency: 300, downloadThroughput: -1, uploadThroughput: -1,
  });
}
await page.goto(url, { waitUntil: "networkidle" });
if (rest.includes("--hover")) {
  await page.hover(selector);
  await page.waitForTimeout(Number(rest[rest.indexOf("--hover") + 1]));
}
const clicked = await page.evaluate(() => performance.now());
await page.click(selector);
await page.waitForFunction(() => document.documentElement.dataset.chart);
const drawn = Number(await page.evaluate(() => document.documentElement.dataset.chart));
console.log(`chart drawn ${Math.round(drawn - clicked)} ms after the click`);
await browser.close();
```

```
ana@dev:~/planner$ node tools/after-click.ts http://localhost:3000/ "text=Minutes per week" --slow
chart drawn 414 ms after the click
```

**Uns quatrocentos milissegundos**, quase todos os 300 que a rede acrescenta à requisição do chunk. Não é um
problema de INP: a página respondeu ao clique na hora, e o gráfico se completou depois. Ainda é uma espera
que alguém vê, e numa rede de celular de verdade ela é uma ida e volta até o servidor, toda primeira vez.

## Buscando um pouco antes

**O ponteiro de uma pessoa chega a um link antes do clique**, por algumas centenas de milissegundos, e um
teclado chega a ele como foco antes do Enter. Os dois são um aviso de que o gráfico pode ser necessário. No
`src/main.ts`, acrescente estas linhas depois da chamada ao `mount`:

```typescript

// A pointer resting on the link, or the keyboard's focus reaching it, is the warning: the
// chart's code is fetched then, and is usually there by the time of the click.
const warm = (e: Event) => {
  if ((e.target as Element).closest?.('a[href="/stats"]')) import("./chart.ts");
};
addEventListener("pointerover", warm);
addEventListener("focusin", warm);
```

O `import()` de um módulo que já está carregando ou carregado devolve a mesma promise, então esquentar duas
vezes, ou esquentar e depois clicar, busca uma vez só. O `import()` do próprio clique encontra então o código
lá, ou a caminho. Faça o build, reinicie e meça dos dois jeitos: clicando na hora, e descansando no link por
300 milissegundos antes, como uma pessoa faz:

```
ana@dev:~/planner$ node tools/after-click.ts http://localhost:3000/ "text=Minutes per week" --slow
chart drawn 406 ms after the click
ana@dev:~/planner$ node tools/after-click.ts http://localhost:3000/ "text=Minutes per week" --slow --hover 300
chart drawn 63 ms after the click
```

**O clique que esperou no link desenhou o gráfico numa fração do tempo**: o chunk foi buscado enquanto o
ponteiro descansava, e o clique o encontrou lá. O clique sem aviso não ficou melhor que antes, e esse é o
limite honesto da ideia.

## Quatro momentos para carregar

| momento | como | para quê |
|---|---|---|
| **quando é usado** | `import()` no tratador, como faz o callback do `mount` | qualquer coisa rara: um diálogo, um editor, uma exportação |
| **num aviso** | `import()` em `pointerover` ou `focusin`, como aqui | o que uma pessoa está para abrir |
| **quando entra na tela** | um `IntersectionObserver` que chama `import()` | as partes mais abaixo numa página longa |
| **quando o navegador está ocioso** | `requestIdleCallback`, ou `<link rel="prefetch">` | o que a maioria dos visitantes vai precisar logo, buscado na menor prioridade |

**Cada momento é uma aposta sobre o visitante.** Carregar no ócio gasta a banda de todo visitante com o que
só alguns vão usar, o que vai bem num desktop e custa num plano de celular medido. Carregar no uso não gasta
nada, e faz quem usa esperar. O aviso fica entre os dois e custa poucas linhas.
