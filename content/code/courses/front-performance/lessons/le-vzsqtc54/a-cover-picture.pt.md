---
title: Uma capa, do jeito que foi entregue
version: 1
---

**Todo curso do planner ganha uma imagem de capa**, no alto da página. Imagens chegam aos projetos do
jeito que esta vai chegar: como o arquivo que o designer exportou, no tamanho da tela dele, no formato
que a ferramenta dele salva por padrão.

A ferramenta que esta aula usa para imagens é o **sharp**, uma biblioteca Node em volta da libvips, uma
biblioteca de imagens escrita em C. Ela lê e escreve PNG, JPEG, WebP e AVIF, redimensiona, e é rápida.
Instale-a no planner como ferramenta de desenvolvimento:

```
ana@dev:~/planner$ npm install --save-exact --save-dev sharp@0.35.5

added 7 packages, and audited 143 packages in 2s

31 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

O sharp vem com a libvips já compilada para Linux, macOS e Windows, então a instalação a baixa e não
compila nada; se ela reclamar, o erro diz para que plataforma não achou um build.

## Desenhando as capas

O planner não tem designer, então o `tools/covers.ts` desenha as capas: um céu, um sol e três colinas
numa cor própria de cada curso, com o grão de uma fotografia por cima, salvos como PNG de 2400 por 1200
pixels. O grão importa: um desenho chapado se comprime a quase nada, e uma fotografia não. Salve-o em
`tools/`:

```typescript
// tools/covers.ts: draw a cover picture for each course, the way a designer
// would hand one over: one large PNG, 2400 by 1200, with a photograph's grain.
//
//   node tools/covers.ts
import sharp from "sharp";
import { mkdir, readFile } from "node:fs/promises";

const plan = JSON.parse(await readFile("public/courses.json", "utf8"));
const [w, h] = [2400, 1200];
await mkdir("public/covers", { recursive: true });
for (const [i, course] of plan.courses.entries()) {
  // A sky, a sun and three hills, in a colour of each course's own.
  const hue = (i * 137) % 360;
  const hill = (y: number, light: number) =>
    `<path d="M0 ${y} C ${w * 0.3} ${y - 220}, ${w * 0.6} ${y + 160}, ${w} ${y - 80} V ${h} H 0 Z" fill="hsl(${hue} 45% ${light}%)"/>`;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">
    <defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="hsl(${hue} 70% 82%)"/><stop offset="1" stop-color="hsl(${(hue + 40) % 360} 60% 60%)"/>
    </linearGradient></defs>
    <rect width="${w}" height="${h}" fill="url(#sky)"/>
    <circle cx="${w * 0.72}" cy="${h * 0.3}" r="150" fill="hsl(45 95% 70%)"/>
    ${hill(h * 0.62, 55)}${hill(h * 0.75, 42)}${hill(h * 0.88, 30)}
  </svg>`;
  // The grain: a photograph's texture, coarse enough to survive being made smaller.
  const grain = await sharp({ create: { width: w / 4, height: h / 4, channels: 3, noise: { type: "gaussian", mean: 128, sigma: 24 } } })
    .resize(w, h).png().toBuffer();
  const file = `public/covers/${course.slug}.png`;
  const info = await sharp(Buffer.from(svg)).composite([{ input: grain, blend: "overlay" }]).png().toFile(file);
  console.log(`${file} ${info.width}x${info.height} ${info.size} B`);
}
```

```
ana@dev:~/planner$ node tools/covers.ts
public/covers/html-css.png 2400x1200 7838807 B
public/covers/javascript.png 2400x1200 7909342 B
public/covers/git.png 2400x1200 7886740 B
```

**Oito megabytes cada.** O PNG guarda cada pixel exatamente, o que é certo para uma captura de tela ou
um logotipo e errado para uma fotografia, cujo grão é justamente o detalhe de que ninguém sentiria falta.

## Na página

No `src/view.ts`, a página de curso mostra a capa embaixo do título. Troque a linha que desenha o título
no `coursePage` por estas duas:

```typescript
<h1>${esc(course.title)}</h1>
<img class="cover" src="/covers/${esc(course.slug)}.png" alt="">
```

O `alt` é vazio de propósito: a imagem é decoração, e um leitor de tela deve pulá-la em vez de anunciar
um céu. E uma regra no fim do `src/style.css`, para a imagem ter a largura do texto e não mais:

```css
.cover { width: 100%; height: auto; border-radius: 0.5rem; }
```

O Vite copia tudo o que está em `public/` para `dist/`, então um build põe as capas onde o `server.ts` as
serve. Faça o build, reinicie o `server.ts` e pergunte ao Lighthouse, com o método padrão:

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json
performance 74, throttling simulate
  FCP  0.9 s    weight 10
  LCP  39.8 s   weight 25
  TBT  0 ms     weight 30
  CLS  0.061    weight 25
  SI   0.9 s    weight 10
  insight: Use efficient cache lifetimes, Est savings of 7,712 KiB
  insight: Improve image delivery, Est savings of 7,690 KiB
  insight: LCP request discovery
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 150 ms
  request /courses/git                 done at    20 ms, 997 B
  request /assets/index-DuClgeFY.js    done at    38 ms, 6931 B
  request /assets/index-DmgXiBYI.css   done at    40 ms, 495 B
  request /covers/git.png              done at   258 ms, 7889204 B
  request /favicon.svg                 done at   281 ms, 1709 B
```

**Um LCP de quase quarenta segundos**, no celular simulado e o seu 1,6 megabit por segundo. O LCP agora
é a imagem, e a imagem tem oito megabytes. Três insights a apontam:

- **Improve image delivery** estima a economia em quase o arquivo inteiro: o formato errado, e muito mais
  pixels do que o celular desenha;
- **LCP request discovery** diz que a imagem foi achada no HTML, o que é bom, e não foi marcada como a
  requisição mais importante, o que a seção "A imagem do LCP" corrige;
- o **CLS** não é mais zero. A imagem chegou depois de a página ser pintada, e o formulário embaixo dela
  desceu quando ela chegou, porque nada dizia qual seria a altura dela.

As próximas três seções tratam disso, em ordem.
