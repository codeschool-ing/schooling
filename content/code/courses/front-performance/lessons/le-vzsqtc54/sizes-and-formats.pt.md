---
title: Tamanhos e formatos
version: 1
---

**Uma imagem tem dois tamanhos que importam, e nenhum é aquele em que foi exportada.** Um é quantos
pixels CSS de largura a página a desenha: num celular, a largura da tela menos as margens, uns 360; num
notebook, os 640 da coluna do planner. O outro é quantos pixels do aparelho isso dá: um celular tem dois
ou três para cada pixel CSS, então uma imagem nítida ali tem três vezes essa largura. 2400 pixels é mais
do que qualquer um deles precisa, e o tamanho certo depende da tela.

**E uma fotografia tem um formato certo, que não é o PNG.** Três formatos comprimem fotografias jogando
fora o que o olho não vê, cada um numa qualidade que você escolhe:

| formato | o que é | onde funciona |
|---|---|---|
| **JPEG** | o formato de toda câmera desde os anos 1990 | em todo lugar |
| **WebP** | do Google, menor que o JPEG com a mesma aparência | em todo navegador atual |
| **AVIF** | vindo do codec de vídeo AV1, menor ainda | em todo navegador atual; mais lento para codificar |

## Fazendo as cópias

O `tools/images.ts` lê cada capa e escreve nove cópias dela: 400, 800 e 1600 pixels de largura, cada uma
em AVIF, WebP e JPEG. As qualidades são as que cada codificador costuma usar para fotografias; uma
qualidade é um número por codificador, então 50 no AVIF e 75 no JPEG parecem mais ou menos iguais. Salve-o
em `tools/`:

```typescript
// tools/images.ts: make, from each cover a designer handed over, the copies a
// browser can choose from: three widths, in three formats.
//
//   node tools/images.ts
import sharp from "sharp";
import { readdir } from "node:fs/promises";

const widths = [400, 800, 1600];
// Each format at the quality its own encoder is usually run at for photographs.
const formats = {
  avif: (s: sharp.Sharp) => s.avif({ quality: 50 }),
  webp: (s: sharp.Sharp) => s.webp({ quality: 75 }),
  jpg: (s: sharp.Sharp) => s.jpeg({ quality: 75, mozjpeg: true }),
};
for (const file of (await readdir("public/covers")).filter((f) => /^[a-z-]+\.png$/.test(f))) {
  const name = file.replace(".png", "");
  const sizes: string[] = [];
  for (const w of widths) {
    for (const [ext, encode] of Object.entries(formats)) {
      const info = await encode(sharp(`public/covers/${file}`).resize(w)).toFile(`public/covers/${name}-${w}.${ext}`);
      sizes.push(`${w}.${ext} ${Math.round(info.size / 1024)} KB`);
    }
  }
  console.log(`${name}: ${sizes.join(", ")}`);
}
```

```
ana@dev:~/planner$ node tools/images.ts
git: 400.avif 6 KB, 400.webp 9 KB, 400.jpg 7 KB, 800.avif 37 KB, 800.webp 51 KB, 800.jpg 44 KB, 1600.avif 111 KB, 1600.webp 160 KB, 1600.jpg 171 KB
html-css: 400.avif 5 KB, 400.webp 6 KB, 400.jpg 6 KB, 800.avif 34 KB, 800.webp 44 KB, 800.jpg 39 KB, 1600.avif 112 KB, 1600.webp 144 KB, 1600.jpg 158 KB
javascript: 400.avif 5 KB, 400.webp 6 KB, 400.jpg 6 KB, 800.avif 32 KB, 800.webp 40 KB, 800.jpg 37 KB, 1600.avif 108 KB, 1600.webp 133 KB, 1600.jpg 153 KB
```

**A cópia de que um celular precisa tem algumas dezenas de kilobytes.** Duas coisas fizeram o trabalho, e
a primeira fez a maior parte: menos pixels, porque uma imagem de 800 pixels de largura tem um nono dos
pixels de uma de 2400, e um formato feito para fotografias. Entre os três formatos a diferença é menor, o
AVIF na frente, o WebP e o JPEG perto, e com 400 pixels quase não importa.

## Quantas larguras

Três é uma escolha, não uma regra. Cada largura a mais é um arquivo para fazer e guardar, e compra um
encaixe mais justo para alguma tela. Larguras que diferem por um fator de dois, como estas, desperdiçam no
máximo metade dos bytes do arquivo escolhido, e em geral bem menos. O que evitar é o tamanho único do
começo desta aula: um arquivo só, grande o bastante para a maior tela, mandado para toda tela.

As cópias vão para `public/covers/`, ao lado dos originais, então o próximo build as copia para `dist/`.
Num projeto de verdade os originais ficariam totalmente fora de `public/`, onde nada pode servi-los por
engano.
