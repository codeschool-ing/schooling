---
title: A mesma página, de quatro jeitos
version: 1
---

**Os quatro mandam a página do curso pronta, na primeira resposta, exatamente como o `server.ts`
fazia na aula 1.** Essa é a parte em que concordam. Onde diferem é em tudo o que vem junto, e as
diferenças são grandes o bastante para medir. Com os quatro servidores de produção rodando, nas
portas 3001 a 3004, e o `server.ts` da aula 1 na porta 3000, peça a cada um o curso de Git e fique
só com o título:

```
ana@dev:~/planner$ for p in 3000 3001 3002 3003 3004; do curl -s http://localhost:$p/courses/git | grep -o '<h1>Git</h1>'; done
<h1>Git</h1>
<h1>Git</h1>
<h1>Git</h1>
<h1>Git</h1>
<h1>Git</h1>
```

Cinco servidores, cinco títulos, cada um no HTML como saiu do servidor. Um crawler e uma prévia de
link leriam todos eles.

## Um curso que não existe

Três das quatro seções antes desta deram à sua página de curso uma linha para um slug desconhecido.
Peça um aos cinco servidores, e imprima só o status:

```
ana@dev:~/planner$ for p in 3000 3001 3002 3003 3004; do curl -s -o /dev/null -w "$p %{http_code}\n" http://localhost:$p/courses/nonsense; done
3000 200
3001 200
3002 404
3003 404
3004 200
ana@dev:~/planner$ curl -s http://localhost:3001/courses/nonsense | grep -o '<meta name="robots"[^>]*>'
<meta name="robots" content="noindex"/>
```

**Dois dos cinco respondem 404, e os três que não respondem erram de três jeitos diferentes.** O
`server.ts` da aula 1 responde 200 porque nunca define um status: a sua página diz *No such course*
e a resposta diz que está tudo bem. O projeto Angular, do jeito que foi escrito aqui, responde 200
com uma página de curso vazia, porque o seu componente não achou nada e não renderizou nada, e um
componente não consegue fazer uma resposta falhar sozinho. O Angular define um status a partir do
servidor por meio de `RESPONSE_INIT`, que esta aula deixa de fora.

**O Next.js chamou `notFound()` e ainda assim respondeu 200**, e esse não é um erro da página. A
rota do curso é pré-renderizada em parte: a sua casca, com a linha de status, já tinha sido mandada
quando o servidor chegou à linha que não achou curso nenhum. O que o Next.js ainda podia fazer, ele
fez: mandou a sua própria página de não encontrado no meio da resposta e acrescentou uma tag que diz
aos buscadores para não guardá-la. Um status não muda depois que uma resposta começou, e a aula 4 é
sobre respostas que começam antes de o servidor saber tudo.

## Quanto cada um custa ao navegador

`tools/weigh.ts` abre cada endereço no Chromium e informa o tamanho do HTML, quantos arquivos de
script a página rodou, quanto JavaScript foi isso e quando o primeiro conteúdo foi pintado. **Os
tamanhos são medidos antes de qualquer compressão**, porque os quatro servidores comprimem de jeitos
diferentes, ou não comprimem, e a comparação deve ser sobre o que cada framework manda e roda, não
sobre como um servidor foi configurado. A própria cobertura do Chromium registra quais scripts
rodaram. Salve em `tools/` do planner, ao lado do `look.ts`:

```typescript
// tools/weigh.ts: what a page costs the browser that opens it.
//
//   node tools/weigh.ts URL...
//
// For each address: the size of the HTML, how many script files the page ran,
// how much JavaScript that was before any compression, and when the first
// content appeared. Sizes are uncompressed, so a server that compresses and
// one that does not are compared on the same footing.
import { chromium } from "playwright";

const browser = await chromium.launch();
console.log("  html KB  files  JS KB run  first paint  address");
for (const url of process.argv.slice(2)) {
  const page = await browser.newPage();
  await page.coverage.startJSCoverage();
  await page.goto(url, { waitUntil: "networkidle" });
  const ran = await page.coverage.stopJSCoverage();
  const r = await page.evaluate(() => {
    const nav = performance.getEntriesByType("navigation")[0] as PerformanceNavigationTiming;
    const fcp = performance.getEntriesByName("first-contentful-paint")[0];
    return { html: nav.decodedBodySize, fcp: fcp ? Math.round(fcp.startTime) : 0 };
  });
  const files = ran.filter((s) => s.url !== url);
  const js = ran.reduce((sum, s) => sum + (s.source?.length ?? 0), 0);
  const kb = (n: number) => (n / 1024).toFixed(1).padStart(9);
  console.log(`${kb(r.html)}  ${String(files.length).padStart(5)}  ${kb(js)}  ${String(r.fcp).padStart(8)} ms  ${url}`);
  await page.close();
}
await browser.close();
```

`JS KB run` conta todo script que a página rodou, os arquivos e os que vêm escritos dentro do HTML.
Rode contra os cinco:

```
ana@dev:~/planner$ node tools/weigh.ts http://localhost:3000/courses/git http://localhost:3001/courses/git http://localhost:3002/courses/git http://localhost:3003/courses/git http://localhost:3004/courses/git
  html KB  files  JS KB run  first paint  address
      0.9      1        2.8        44 ms  http://localhost:3000/courses/git
      6.6      7      459.9        32 ms  http://localhost:3001/courses/git
      2.3      6      195.8        36 ms  http://localhost:3002/courses/git
      4.1     10       89.1        28 ms  http://localhost:3003/courses/git
      2.2      1      264.2        64 ms  http://localhost:3004/courses/git
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um gráfico de barras do JavaScript que a página do Git de cada servidor rodou no Chromium, sem compressão, como o tools/weigh.ts mediu. O planner puro da aula 1: 2,8 KB. SvelteKit: 89,1 KB. Nuxt: 195,8 KB. Angular: 264,2 KB. Next.js: 459,9 KB.\"><text x=\"140\" y=\"42\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">planner puro</text><rect x=\"150\" y=\"30\" width=\"2.922374429223744\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160.92237442922374\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2,8 KB</text><text x=\"140\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SvelteKit</text><rect x=\"150\" y=\"68\" width=\"92.9941291585127\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250.9941291585127\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">89,1 KB</text><text x=\"140\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Nuxt</text><rect x=\"150\" y=\"106\" width=\"204.35746901500326\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"362.3574690150033\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">195,8 KB</text><text x=\"140\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Angular</text><rect x=\"150\" y=\"144\" width=\"275.74690150032615\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"433.74690150032615\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">264,2 KB</text><text x=\"140\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Next.js</text><rect x=\"150\" y=\"182\" width=\"479.99999999999994\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"638.0\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">459,9 KB</text><line x1=\"150\" y1=\"222\" x2=\"640\" y2=\"222\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"150\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">JavaScript rodado pela página do Git, sem compressão</text></svg>", "caption": "A mesma página, com o mesmo HTML na primeira resposta, e cinco quantidades muito diferentes de código para rodar depois que ela chegou.", "same": ["Angular", "Next.js", "Nuxt", "SvelteKit"]}
```

## Lendo esses números com justiça

**Toda primeira pintura fica entre 28 e 64 milissegundos, nesta máquina.** Os servidores estão no
mesmo computador que o navegador, e cada um mandou o conteúdo na primeira resposta, então nada
esperou JavaScript para pintar. As diferenças na última coluna são ruído neste tamanho; a aula 5
mede com a rede mais lenta, onde elas deixam de ser ruído.

**A coluna do JavaScript não é ruído, e é o preço do framework.** O planner puro roda os seus
próprios três arquivos, juntados. Cada um dos quatro roda o seu framework de interface, o seu
roteador e o código que hidrata a página, para uma página que tem dois links e nada para clicar. É
um custo fixo: ele não cresce com o número de páginas, e num app grande o código do próprio app
acaba sendo a maior parte do total. Numa página deste tamanho ele é tudo o que há, e é por isso que
aqui é fácil de ver.

A ordem dos quatro nessa coluna diz algo sobre como cada um foi projetado, e nada sobre qual
escolher. **O SvelteKit, com 89,1 KB, manda menos**: o Svelte compila cada componente no código que o
atualiza, então há pouco runtime genérico para mandar. O Next.js, com 459,9 KB, manda mais: o React
no navegador recebe a descrição da página que o servidor renderizou, o payload da próxima seção, e
mantém a maquinaria para renderizar a partir dela de novo a cada navegação. O Nuxt e o Angular ficam
no meio, com os 264,2 KB do Angular num arquivo só que guarda a sua detecção de mudanças, o seu
roteador e o seu cliente HTTP juntos. **O peso de um meta-framework é uma entrada de uma decisão, e a
aula 8 mostra quanto do JavaScript de qualquer app pode ser adiado** até uma página precisar dele.
