---
title: Renderização no cliente, medida
version: 1
---

**O planner do jeito que você o construiu é renderizado no cliente: o servidor manda uma página
sem nada dentro, e o script desenha tudo.** É assim que todo app de página única feito com um
bundler começa, qualquer que seja o framework, e vale a pena ver exatamente o que ele manda antes
de decidir se isso é um problema.

## O build

O servidor de desenvolvimento da seção anterior refaz o build enquanto você edita, e por isso é a
coisa errada para medir. `npm run build` escreve em `dist/` o site que uma hospedagem serviria, e
`npm run preview` serve essa pasta exatamente como está. Pare o `npm run dev` com `Ctrl-C` antes:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 7 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                 0.46 kB │ gzip: 0.29 kB
dist/assets/index-1yLCgpWc.css  0.25 kB │ gzip: 0.20 kB
dist/assets/index-Dv4jVJdV.js   2.87 kB │ gzip: 1.37 kB

✓ built in 161ms
```

Três arquivos e os dados. O `tsc` conferiu os tipos, e o `vite build` juntou os três arquivos
TypeScript num script só e deu a ele um nome feito do seu conteúdo, `index-` e um hash. A aula 9 é
sobre por que o nome muda quando o conteúdo muda. Agora sirva o resultado, no segundo terminal:

```
ana@dev:~/planner$ npm run preview

> planner@0.0.0 preview
> vite preview

  ➜  Local:   http://localhost:4173/
  ➜  Network: use --host to expose
```

## O que a primeira resposta carrega

Peça a página inicial do jeito que um programa que não roda scripts pediria, com o `curl`:

```
ana@dev:~/planner$ curl -s http://localhost:4173/
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner</title>
    <script type="module" crossorigin src="/assets/index-Dv4jVJdV.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-1yLCgpWc.css">
  </head>
  <body>
    <main id="app"></main>
  </body>
</html>
```

**Não há curso nenhum nela.** O `<main>` está vazio, e o único jeito de preenchê-lo é rodar o
`/assets/index-…js`, que busca o `/courses.json` e só então desenha. O Vite moveu o `<script>`
para o `<head>` e o marcou como `type="module"`, o que faz o navegador buscá-lo sem parar para
esperar, e rodá-lo depois de ler a página.

## O que um navegador vê

O `curl` lê uma resposta. Um navegador lê essa resposta, busca o que ela nomeia, roda o script e
desenha, e o único jeito de saber o que uma pessoa veria é perguntar a um navegador.
`tools/look.ts` abre uma página no Chromium que o Playwright instalou, espera a rede ficar quieta
por meio segundo, e imprime o que ele pediu, quando o primeiro conteúdo foi pintado e o texto na
tela. Salve em `tools/look.ts`:

```typescript
// tools/look.ts: open a page in Chromium and say what a person would see.
//
//   node tools/look.ts URL [--no-js] [--slow]
//
// --no-js  the browser runs no JavaScript at all, as a simple crawler does
// --slow   every request waits 300 ms longer, as on a phone far from the server
import { chromium } from "playwright";

const url = process.argv[2];
const flags = process.argv.slice(3);
const browser = await chromium.launch();
const context = await browser.newContext({ javaScriptEnabled: !flags.includes("--no-js") });
const page = await context.newPage();
if (flags.includes("--slow")) {
  const cdp = await context.newCDPSession(page);
  await cdp.send("Network.emulateNetworkConditions", {
    offline: false, latency: 300, downloadThroughput: -1, uploadThroughput: -1,
  });
}
const requests: string[] = [];
page.on("request", (r) => requests.push(new URL(r.url()).pathname));
await page.goto(url, { waitUntil: "networkidle" });
const paint = await page.evaluate(() => {
  const fcp = performance.getEntriesByName("first-contentful-paint")[0];
  return fcp ? Math.round(fcp.startTime) : null;
});
console.log("requests:", requests.join(" "));
console.log("first contentful paint:", paint === null ? "none" : `${paint} ms`);
console.log("text on the screen:");
console.log((await page.locator("body").innerText()).trim() || "(nothing)");
await browser.close();
```

O Node 22 roda um arquivo `.ts` direto: ele tira os tipos e roda o que sobra, e é por isso que não
há build antes. **First contentful paint**, a primeira pintura com conteúdo, é o momento em que o
navegador desenhou pela primeira vez algum texto ou imagem, como o próprio navegador registra; a
aula 5 a põe ao lado dos três números que o Google lê. Rode com JavaScript, e depois sem:

```
ana@dev:~/planner$ node tools/look.ts http://localhost:4173/
requests: / /assets/index-Dv4jVJdV.js /assets/index-1yLCgpWc.css /courses.json
first contentful paint: 56 ms
text on the screen:
Study planner
HTML and CSS · 2 sessions
JavaScript · 2 sessions
Git · 2 sessions
Weeks
Week of 2026-10-19: 210 min, 105 done
Week of 2026-10-26: 40 min, 0 done
ana@dev:~/planner$ node tools/look.ts http://localhost:4173/ --no-js
requests: / /assets/index-1yLCgpWc.css
first contentful paint: none
text on the screen:
(nothing)
```

Com JavaScript, quatro requisições e a página inteira. Sem ele, **duas requisições e nada**: o
navegador leu o HTML, buscou a folha de estilo que ele nomeia, não tinha script para rodar e
portanto não tinha nada para desenhar, e nunca pintou coisa alguma, e é por isso que a pintura diz
`none`. Essa segunda execução é o que um programa que lê páginas sem rodar scripts recebe de um app
renderizado no cliente, e é também o que uma pessoa vê enquanto o script ainda está a caminho.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A cadeia de uma página renderizada no cliente. O HTML nomeia um script e uma folha de estilo; o script, quando roda, pede o courses.json; só quando ele chega algo é desenhado no main vazio. Cada seta é uma requisição que o navegador não poderia ter feito antes de a resposta anterior chegar.\"><rect x=\"20\" y=\"40\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/</text><text x=\"95\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;main id=\"app\"&gt;</text><rect x=\"230\" y=\"25\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/assets/index-….js</text><rect x=\"230\" y=\"80\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/assets/index-….css</text><line x1=\"170\" y1=\"60\" x2=\"228\" y2=\"45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"228.0,45.0 221.6,49.9 220.1,43.8\" fill=\"var(--paper-dim)\"></polygon><line x1=\"170\" y1=\"80\" x2=\"228\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"228.0,100.0 220.0,100.5 222.0,94.7\" fill=\"var(--paper-dim)\"></polygon><rect x=\"470\" y=\"25\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/courses.json</text><line x1=\"410\" y1=\"45\" x2=\"468\" y2=\"45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"468.0,45.0 460.6,48.1 460.6,41.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"470\" y=\"140\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"585\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a lista é desenhada</text><text x=\"585\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">primeira pintura com conteúdo</text><line x1=\"530\" y1=\"65\" x2=\"560\" y2=\"138\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"560.0,138.0 554.3,132.4 560.1,130.0\" fill=\"var(--phosphor)\"></polygon><text x=\"95\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1ª resposta</text><text x=\"320\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2ª</text><text x=\"530\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3ª</text><text x=\"20\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Sem JavaScript a cadeia para depois da folha de estilo, e nada é desenhado.</text></svg>", "caption": "Três respostas em sequência, cada uma necessária antes de a próxima requisição sequer poder ser feita."}
```

## Por que é popular mesmo assim

Nada acima torna a renderização no cliente errada. Depois da primeira carga, cada clique no planner
é atendido no navegador: o tratador de links em `mount` muda o endereço e redesenha, e nada vai ao
servidor. A hospedagem não precisa de programa, só de arquivos, que é a hospedagem mais barata que
existe. E o servidor nunca vê os dados de ninguém, então não há nada por usuário para proteger
nele. Uma ferramenta usada o dia todo por pessoas logadas, como um cliente de e-mail, uma planilha
ou uma tela de administração, paga uma primeira carga lenta e ganha um app rápido pelo resto do
dia.

O custo fica todo no começo, e cai mais pesado sobre os visitantes com a conexão mais lenta, que
esperam as três idas uma depois da outra. A seção depois da próxima mede exatamente isso.
