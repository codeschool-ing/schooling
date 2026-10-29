---
title: Ícones
version: 1
---

**Um app instalado é desenhado pelo ícone**, em lugares que a página nunca vê: a tela inicial, a lista de
aplicativos, o seletor de janelas, a tela de abertura enquanto ele abre. O manifesto cita três, e o
`tools/icons.ts` os desenha com o sharp a partir de um SVG pequeno: uma página com três linhas e um tique, no azul
do planner. Salve-o em `tools/`:

```typescript
// tools/icons.ts: draw the planner's app icons: one at 192 and one at 512 pixels for
// ordinary use, and one maskable, whose drawing stays inside the circle every system's
// mask keeps.
//
//   node tools/icons.ts
import sharp from "sharp";
import { mkdir } from "node:fs/promises";

// A page with three lines and a tick, drawn on a square of 100 by 100, scaled by `size`
// around the centre: 1 fills the square, 0.6 keeps it inside the maskable safe zone.
const mark = (size: number) => `<g transform="translate(50 50) scale(${size}) translate(-50 -50)">
  <rect x="22" y="14" width="56" height="72" rx="6" fill="#ffffff"/>
  <rect x="32" y="30" width="36" height="5" rx="2.5" fill="#93c5fd"/>
  <rect x="32" y="42" width="36" height="5" rx="2.5" fill="#93c5fd"/>
  <rect x="32" y="54" width="22" height="5" rx="2.5" fill="#93c5fd"/>
  <path d="M40 69 l7 7 l14 -16" stroke="#1d4ed8" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
</g>`;
const icon = (rounded: boolean, size: number) => Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" rx="${rounded ? 18 : 0}" fill="#1d4ed8"/>${mark(size)}</svg>`);

await mkdir("public/icons", { recursive: true });
for (const [file, svg, px] of [
  ["icon-192.png", icon(true, 0.9), 192],
  ["icon-512.png", icon(true, 0.9), 512],
  // A mask may cut away everything outside a circle of 80% of the width, so the drawing
  // shrinks to fit inside it and the square is filled edge to edge.
  ["maskable-512.png", icon(false, 0.6), 512],
] as const) {
  const info = await sharp(svg, { density: 72 * px / 100 }).resize(px, px).png().toFile(`public/icons/${file}`);
  console.log(`public/icons/${file} ${info.width}x${info.height} ${info.size} B`);
}
```

```
ana@dev:~/planner$ node tools/icons.ts
public/icons/icon-192.png 192x192 3602 B
public/icons/icon-512.png 512x512 13522 B
public/icons/maskable-512.png 512x512 9843 B
```

## Dois tamanhos e uma máscara

- **192 e 512 pixels** são os dois tamanhos que o Chromium mais usa: o primeiro na tela inicial, o segundo na tela
  de abertura que aparece enquanto o app abre. Um sistema que precisa de outro tamanho escala o mais próximo.
- **`"purpose": "maskable"`** marca um ícone desenhado para um sistema que corta os ícones no próprio formato, um
  círculo, um quadrado arredondado, uma gota. Um sistema desses pode manter só o círculo do meio, 80 por cento da
  largura, então um ícone maskable enche o quadrado inteiro com o fundo e mantém o desenho dentro desse círculo. Os
  ícones comuns têm os próprios cantos arredondados; o maskable não tem nenhum, porque a máscara faz os cantos.

Um ícone sem `maskable` é mostrado como é, dentro de uma placa que o sistema desenha, e por isso os dois tipos são
arquivos separados. Faça o build, reinicie e pergunte de novo:

```
ana@dev:~/planner$ node tools/installable.ts http://localhost:3000/
manifest: http://localhost:3000/manifest.webmanifest
not installable: no-acceptable-icon (minimum-icon-size-in-pixels=144)
```

**Instalável.** No Chrome ou no Edge do seu próprio computador, a barra de endereço agora mostra um ícone de
instalação para `localhost:3000`, e o painel **Application** das ferramentas de desenvolvedor mostra o manifesto
como o navegador o leu, com cada ícone e cada problema que encontrou.
