---
title: Deixando o navegador escolher
version: 1
---

**A página não conhece a tela; o navegador conhece.** Então o HTML oferece todas as cópias e diz com que
largura a imagem vai ser desenhada, e o navegador escolhe a cópia que serve. Três peças de marcação fazem
isso:

- **`srcset`** lista as cópias com as larguras delas: `/covers/git-400.jpg 400w, /covers/git-800.jpg
  800w, …`. O `w` é a largura do arquivo em pixels, escrita por quem fez os arquivos.
- **`sizes`** diz com que largura a imagem vai ser desenhada, em CSS, para cada tipo de janela. O navegador
  precisa disso antes de ter feito o layout da página, e por isso não consegue medir sozinho.
- **`<picture>`** envolve o `<img>` com um `<source>` por formato, em ordem de preferência. O navegador
  pega o primeiro tipo que consegue ler e ignora o resto, e o `<img>` de dentro é o que mostra um navegador
  que não lê nenhum.

Para o planner, o `sizes` é a coluna: quarenta rems quando a janela é larga o bastante para ter margens em
volta, e senão a janela menos os dois rems de padding. No `src/view.ts`, acrescente esta função logo depois
da linha que define o `day`:

```typescript
// The cover in three widths and three formats. The browser takes the first format it
// can read, and in it the smallest width that fills the space sizes describes.
const cover = (slug: string) => {
  const set = (ext: string) => [400, 800, 1600].map((w) => `/covers/${slug}-${w}.${ext} ${w}w`).join(", ");
  const sizes = "(min-width: 42rem) 40rem, calc(100vw - 2rem)";
  return `<picture>
  <source type="image/avif" srcset="${set("avif")}" sizes="${sizes}">
  <source type="image/webp" srcset="${set("webp")}" sizes="${sizes}">
  <img class="cover" src="/covers/${slug}-800.jpg" srcset="${set("jpg")}" sizes="${sizes}" alt="">
</picture>`;
};
```

e no `coursePage`, troque a linha do `<img>` por uma chamada a ela:

```typescript
${cover(course.slug)}
```

## O que cada tela escolheu

O `tools/chosen.ts` abre a página de curso como quatro tipos de tela e pergunta à página de que arquivo
veio a imagem: o `currentSrc`, o endereço que o navegador escolheu. Salve-o em `tools/`:

```typescript
// tools/chosen.ts: open a page as four kinds of screen and say which file of the
// cover each one downloaded.
//
//   node tools/chosen.ts URL
import { chromium } from "playwright";

const url = process.argv[2];
const screens = [
  { name: "phone", width: 390, height: 844, scale: 3 },
  { name: "older phone", width: 390, height: 844, scale: 1 },
  { name: "laptop", width: 1280, height: 800, scale: 1 },
  { name: "laptop, sharp", width: 1280, height: 800, scale: 2 },
];
const browser = await chromium.launch();
for (const s of screens) {
  // A context of its own for each, so no screen finds the file another one downloaded.
  const context = await browser.newContext({ viewport: { width: s.width, height: s.height }, deviceScaleFactor: s.scale });
  const page = await context.newPage();
  await page.goto(url, { waitUntil: "networkidle" });
  const src = await page.$eval("img.cover", (img) => (img as HTMLImageElement).currentSrc);
  console.log(`${s.name.padEnd(14)} ${String(s.width).padStart(4)} px x${s.scale}  ${new URL(src).pathname}`);
  await context.close();
}
await browser.close();
```

Faça o build, reinicie o `server.ts` e pergunte:

```
ana@dev:~/planner$ node tools/chosen.ts http://localhost:3000/courses/git
phone           390 px x3  /covers/git-1600.avif
older phone     390 px x1  /covers/git-400.avif
laptop         1280 px x1  /covers/git-800.avif
laptop, sharp  1280 px x2  /covers/git-1600.avif
```

**Uma tag, três arquivos diferentes, todos AVIF.** O celular desenha a imagem com uns 360 pixels CSS de
largura, que a três pixels do aparelho cada dão uns mil, então ele pega o de 1600. O celular mais antigo,
um pixel do aparelho cada, pega o de 400. O notebook desenha 640 e pega o de 800, e o notebook nítido
precisa de 1280 e pega o de 1600. A escolha é do navegador, e ele pode pesar coisas que a página não vê:
um navegador pode pegar uma cópia menor numa conexão lenta, ou continuar usando uma maior que já tem.

## E o Lighthouse

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|LCP|CLS|insight'
performance 100, throttling simulate
  LCP  1.3 s    weight 25
  CLS  0        weight 25
  insight: Use efficient cache lifetimes, Est savings of 45 KiB
  insight: Improve image delivery, Est savings of 29 KiB
  insight: LCP request discovery
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 150 ms
```

**De quase quarenta segundos para 1,3.** O celular simulado baixou um AVIF de menos de quarenta
kilobytes em vez de um PNG de oito megabytes. E o CLS voltou a zero, o que é menos boa notícia do que
parece: o arquivo pequeno chegou antes da primeira pintura, num computador sem rede no meio, então nada se
mexeu desta vez. A seção seguinte mede numa rede lenta, onde se mexe.
