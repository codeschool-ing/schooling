---
title: O que um celular baixa de verdade
version: 1
---

**Um app bundle não é o que um celular baixa; é o que o Google Play corta nas peças de que cada
celular precisa.** A lição 1 viu isso pelo lado da assinatura: o bundletool gerou os APKs e os
assinou. Aqui a mesma ferramenta responde à pergunta do tamanho. Um app que leva uma imagem em cinco
densidades guarda cinco cópias no bundle, e um celular baixa uma.

## Uma imagem de capa em cinco densidades

O planner mostra uma imagem de capa para a semana. Uma de verdade é uma fotografia, e uma fotografia
quase não comprime. Para ter uma aqui em tamanhos exatos, este programa escreve um PNG de ruído com
semente, que comprime tão mal quanto uma fotografia. Salve-o como `photo.ts` em `~/planner`:

```typescript
// photo.ts: write a PNG of seeded noise, WIDTH x HEIGHT, which compresses like a photograph: hardly at all
import { deflateSync } from "node:zlib";
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

const [file, width, height] = [process.argv[2], Number(process.argv[3]), Number(process.argv[4])];
let seed = width * 7919 + height;
function next(): number {
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) & 0xff;
}

const table = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
function crc(bytes: Buffer): number {
  let c = 0xffffffff;
  for (const b of bytes) c = table[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type: string, data: Buffer): Buffer {
  const head = Buffer.alloc(8);
  head.writeUInt32BE(data.length, 0);
  head.write(type, 4, "ascii");
  const tail = Buffer.alloc(4);
  tail.writeUInt32BE(crc(Buffer.concat([head.subarray(4), data])), 0);
  return Buffer.concat([head, data, tail]);
}

const header = Buffer.alloc(13);
header.writeUInt32BE(width, 0);
header.writeUInt32BE(height, 4);
header[8] = 8; // bits per channel
header[9] = 2; // colour type: RGB
const rows: Buffer[] = [];
for (let y = 0; y < height; y++) {
  const row = Buffer.alloc(1 + width * 3);
  for (let i = 1; i < row.length; i++) row[i] = next();
  rows.push(row);
}
mkdirSync(dirname(file), { recursive: true });
writeFileSync(file, Buffer.concat([
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
  chunk("IHDR", header), chunk("IDAT", deflateSync(Buffer.concat(rows))), chunk("IEND", Buffer.alloc(0)),
]));
```

## O bundle, cortado e medido

Os passos são os da lição 1, com uma entrada a mais: uma pasta `res` com a imagem uma vez por
densidade, compilada pelo `aapt2` e ligada ao módulo. O `get-size total` então informa o tamanho de
download por densidade de tela, e o build com `--mode=universal` é o APK único que um celular
receberia se o app fosse publicado como um arquivo só para todo mundo:

```
ana@dev:~/size$ for d in mdpi:240 hdpi:360 xhdpi:480 xxhdpi:720 xxxhdpi:960; do node ~/planner/photo.ts res/drawable-${d%%:*}/cover.png ${d##*:} ${d##*:}; done; ls -l res/*/cover.png
-rw-r--r-- 1 ana ana  389343 Oct 30 16:24 res/drawable-hdpi/cover.png
-rw-r--r-- 1 ana ana  173158 Oct 30 16:24 res/drawable-mdpi/cover.png
-rw-r--r-- 1 ana ana  691958 Oct 30 16:24 res/drawable-xhdpi/cover.png
-rw-r--r-- 1 ana ana 1556458 Oct 30 16:24 res/drawable-xxhdpi/cover.png
-rw-r--r-- 1 ana ana 2766668 Oct 30 16:24 res/drawable-xxxhdpi/cover.png
ana@dev:~/size$ aapt2 compile --dir res -o res.zip --no-crunch && aapt2 link --proto-format -o base.apk --manifest AndroidManifest.xml -I $ANDROID_HOME/platforms/android-36/android.jar --min-sdk-version 24 --target-sdk-version 36 res.zip
ana@dev:~/size$ java -jar ~/android/bundletool.jar build-bundle --modules=base.zip --output=planner.aab && ls -l planner.aab
-rw------- 1 ana ana 5581234 Oct 30 16:24 planner.aab
ana@dev:~/size$ java -jar ~/android/bundletool.jar build-apks --bundle=planner.aab --output=planner.apks --ks=$HOME/signing/play-stand-in.jks --ks-key-alias=app --ks-pass=pass:$PLAY_PASS
ana@dev:~/size$ java -jar ~/android/bundletool.jar get-size total --apks=planner.apks --dimensions=SCREEN_DENSITY
SCREEN_DENSITY,MIN,MAX
XXXHDPI,2774535,2774535
LDPI,180233,180233
TVDPI,569794,569794
XXHDPI,1564019,1564023
MDPI,180231,180232
HDPI,396486,396492
XHDPI,699188,699191
ana@dev:~/size$ java -jar ~/android/bundletool.jar build-apks --bundle=planner.aab --output=universal.apks --mode=universal --ks=$HOME/signing/play-stand-in.jks --ks-key-alias=app --ks-pass=pass:$PLAY_PASS
ana@dev:~/size$ java -jar ~/android/bundletool.jar get-size total --apks=universal.apks
MIN,MAX
5583525,5583525
```

## Lendo o resultado

**O bundle tem 5,6 MB, e nenhum celular baixa isso.** Um celular com tela `xxhdpi`, a densidade de
muitos celulares atuais, baixa 1,6 MB; um `mdpi`, 0,2 MB. O APK universal tem 5,6 MB para todo
celular, porque leva as cinco imagens e cada celular usa uma. **Publicar o bundle reduziu o download
típico a menos de um terço**, sem mudança nenhuma no app.

Dois detalhes da tabela merecem uma segunda olhada. `LDPI` e `TVDPI` são densidades para as quais o
bundle não tinha imagem, e o bundletool montou as divisões delas com as imagens que tinha. E o mínimo
e o máximo diferem por poucos bytes em algumas densidades, porque as duas variantes da lição 1, para
Androids mais antigos e mais novos, são assinadas de jeitos diferentes.

## No iOS e no React Native

A Apple faz o mesmo corte, chamado **app thinning**: a App Store entrega a cada aparelho os assets da
escala dele, `@2x` ou `@3x`, a partir de um catálogo de assets. As imagens de um app React Native só
se beneficiam quando chegam aos sistemas de assets nativos, o que o Expo e o React Native fazem para
imagens referenciadas com `require`, e não fazem para imagens baixadas durante o uso. *Nenhum dos dois
foi medido para este curso.*
