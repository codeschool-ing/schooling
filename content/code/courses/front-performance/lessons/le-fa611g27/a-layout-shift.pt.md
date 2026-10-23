---
title: Um deslocamento de layout, criado e removido
version: 1
---

**O aviso chega depois de a página ser pintada, e empurra tudo embaixo dele para baixo.** Numa janela
de computador, com tudo num computador só, isso acontece cedo demais para se ver. Numa janela do
tamanho de um celular, com cada requisição 300 milissegundos mais lenta, é uma página que pula:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/courses/git --phone --slow
[vitals] LCP 972 ms good #notice
[vitals] CLS 0.031 good #app
```

**Duas métricas se mexeram por um motivo só.** O CLS não é mais zero, e o elemento que se deslocou foi
o `#app`, a página inteira embaixo do aviso. E o elemento do LCP é o próprio `#notice`: num celular as
duas linhas do aviso são o maior bloco de texto da página de curso, então o maior conteúdo chegou por
último, com um fetch que só começou depois de o script rodar. **Um elemento atrasado pode ser ao mesmo
tempo o deslocamento e a maior pintura**, e corrigir um não corrige o outro, como os dois passos abaixo
mostram.

O CLS está abaixo da linha de 0,1. Ainda é uma página cujo conteúdo se mexe embaixo do dedo de quem
lê, e um segundo elemento atrasado, uma imagem de banner, ou uma tela menor a empurraria para cima.

## Passo um: guardar o espaço

O deslocamento acontece porque o parágrafo vazio não ocupava espaço. Se ele ocupar o espaço de que o
aviso vai precisar, nada se mexe quando o texto chega. Mude a segunda regra do `src/style.css`:

```css
.notice:empty { min-height: 3rem; }
```

Três rems são duas linhas de texto neste tamanho, que é o que o aviso ocupa num celular. Build,
reinício, medida:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/courses/git --phone --slow
[vitals] LCP 956 ms good #notice
[vitals] CLS 0.000 good 
```

**O CLS é zero e o LCP não se mexeu.** Nada se desloca, porque a caixa estava lá; o maior texto ainda
chega por último, porque o texto ainda é buscado pelo script. Guardar espaço é a correção certa para
um conteúdo cujo tamanho você conhece e cuja chegada você não consegue apressar, como um anúncio. Ela
também é um palpite: um aviso de três linhas num celular estreito ainda empurraria a página uma linha.

## Passo dois: mandá-lo com a página

O aviso é igual para todo mundo e é um arquivo no servidor. Não há motivo para o navegador buscá-lo.
O `server.ts` consegue lê-lo e escrevê-lo no parágrafo, como já faz com o plano, e o `main.ts` então
acha o parágrafo cheio e não busca nada. Substitua o `server.ts`:

```typescript
// server.ts: the same planner, with each page drawn here before it is sent.
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join } from "node:path";
import type { Plan } from "./src/planner.ts";
import { page } from "./src/view.ts";

const dist = join(import.meta.dirname, "dist");
const types: Record<string, string> = {
  ".js": "text/javascript", ".css": "text/css", ".json": "application/json", ".svg": "image/svg+xml",
};
const shell = await readFile(join(dist, "index.html"), "utf8");
const esc = (s: string) => s.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);

createServer(async (req, res) => {
  const { pathname } = new URL(req.url ?? "/", "http://localhost");
  if (extname(pathname)) {
    // A file the build wrote: a script, a stylesheet, the data.
    try {
      const body = await readFile(join(dist, pathname));
      res.writeHead(200, { "content-type": types[extname(pathname)] ?? "application/octet-stream" });
      res.end(body);
    } catch {
      res.writeHead(404).end();
    }
    return;
  }
  // A page: read the plan and the notice, and draw both into the shell the build wrote.
  const plan: Plan = JSON.parse(await readFile(join(dist, "courses.json"), "utf8"));
  const notice: { text: string } = JSON.parse(await readFile(join(dist, "notice.json"), "utf8"));
  // The plan goes into the page as data, so the browser does not fetch it again. A "<" is
  // written as \u003c, so no title can close the script element early.
  const data = JSON.stringify(plan).replace(/</g, "\\u003c");
  const html = shell
    .replace('<p class="notice" id="notice"></p>', `<p class="notice" id="notice">${esc(notice.text)}</p>`)
    .replace('<main id="app"></main>',
      `<main id="app">${page(plan, pathname)}</main><script type="application/json" id="plan">${data}</script>`);
  res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
  res.end(html);
}).listen(3000, () => console.log("planner on http://localhost:3000"));
```

O aviso passa pelo `esc`, porque é texto, exatamente como todo título do `view.ts`. Reinicie, e meça
de novo:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/courses/git --phone --slow
[vitals] LCP 648 ms good #notice
[vitals] CLS 0.000 good 
```

**O LCP veio para a frente uns trezentos milissegundos**, uma ida e volta, e o CLS ficou em zero. O
maior texto agora chega com o HTML, então é pintado com a primeira pintura. É o argumento da aula 1 a
favor da renderização no servidor, achado de novo pela outra ponta: o que quer que a página precise
para parecer pronta pertence à primeira resposta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Três medidas da página de curso numa janela do tamanho de um celular, com cada requisição 300 ms mais lenta. Como estava: LCP 972 ms e CLS 0.031. Com espaço guardado para o aviso: LCP 956 ms e CLS 0.000. Com o aviso mandado pelo servidor: LCP 648 ms e CLS 0.000.\"><text x=\"188\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">como estava</text><rect x=\"200\" y=\"40\" width=\"320.76\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"528.76\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">LCP 972 ms · CLS 0.031</text><text x=\"188\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">espaço guardado</text><rect x=\"200\" y=\"96\" width=\"315.48\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"523.48\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">LCP 956 ms · CLS 0.000</text><text x=\"188\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mandado pelo servidor</text><rect x=\"200\" y=\"152\" width=\"213.84\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"421.84000000000003\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">LCP 648 ms · CLS 0.000</text><text x=\"200\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">LCP, a barra; CLS ao lado</text></svg>", "caption": "Guardar espaço parou o movimento; mandar o aviso com a página o trouxe para a frente."}
```
