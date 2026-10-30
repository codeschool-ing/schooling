---
title: O botão do planner, calculado para cada tela
version: 1
---

**A tela de um curso no planner tem um botão "adicionar sessão": um alvo de toque de 48 dp com um
ícone de 24 dp dentro.** As orientações de acessibilidade do Android recomendam que todo alvo de
toque tenha pelo menos 48 dp por 48 dp, e o ícone é metade disso. Este programa pega esses dois
tamanhos e calcula quanto eles dão em pixels em cada bucket do Android, numa tela entre dois
buckets e num iPhone em cada fator de escala, e depois lista os arquivos de imagem de que um ícone
raster precisaria. Salve-o como `density.ts` em `~/planner`:

```typescript
// density.ts: one size in density-independent units, as the pixels each screen needs
const target = 48; // a touch target, in dp on Android and pt on iOS
const icon = 24; // an icon inside it

// Android: px = dp * dpi / 160, for each density bucket
const buckets = [
  { name: "mdpi", dpi: 160 },
  { name: "hdpi", dpi: 240 },
  { name: "xhdpi", dpi: 320 },
  { name: "xxhdpi", dpi: 480 },
  { name: "xxxhdpi", dpi: 640 },
];
const px = (dp: number, dpi: number) => (dp * dpi) / 160;
const row = (...cells: (string | number)[]) =>
  console.log(cells.map((c, i) => (i === 0 ? String(c).padEnd(8) : String(c).padStart(7))).join(""));

row("bucket", "dpi", "scale", "48 dp", "24 dp");
for (const b of buckets) {
  row(b.name, b.dpi, `${b.dpi / 160}x`, `${px(target, b.dpi)} px`, `${px(icon, b.dpi)} px`);
}

// A screen between two buckets: the sum still works, and no file is that size
console.log(`\n420 dpi: 48 dp = ${px(target, 420)} px, 24 dp = ${px(icon, 420)} px\n`);

// iOS: px = pt * scale
row("scale", "48 pt", "24 pt");
for (const s of [1, 2, 3]) row(`@${s}x`, `${target * s} px`, `${icon * s} px`);

// The raster files one 24-unit icon needs, when it is not a vector
console.log("\nfiles for one raster icon:");
for (const b of buckets) {
  console.log(`  ${`drawable-${b.name}/ic_session.png`.padEnd(32)} ${px(icon, b.dpi)}x${px(icon, b.dpi)}`);
}
for (const s of [2, 3]) {
  console.log(`  ${`ic_session@${s}x.png`.padEnd(32)} ${icon * s}x${icon * s}`);
}
```

Ele não precisa de nada dos outros arquivos do planner. Rode:

```
ana@dev:~/planner$ node density.ts
bucket      dpi  scale  48 dp  24 dp
mdpi        160     1x  48 px  24 px
hdpi        240   1.5x  72 px  36 px
xhdpi       320     2x  96 px  48 px
xxhdpi      480     3x 144 px  72 px
xxxhdpi     640     4x 192 px  96 px

420 dpi: 48 dp = 126 px, 24 dp = 63 px

scale     48 pt  24 pt
@1x       48 px  24 px
@2x       96 px  48 px
@3x      144 px  72 px

files for one raster icon:
  drawable-mdpi/ic_session.png     24x24
  drawable-hdpi/ic_session.png     36x36
  drawable-xhdpi/ic_session.png    48x48
  drawable-xxhdpi/ic_session.png   72x72
  drawable-xxxhdpi/ic_session.png  96x96
  ic_session@2x.png                48x48
  ic_session@3x.png                72x72
```

## Lendo a tabela

**A primeira tabela é a fórmula das seções anteriores, cinco vezes.** 48 dp são 48 pixels em mdpi,
a referência, e 144 em xxhdpi, três vezes mais em cada direção, então nove vezes mais pixels no
quadrado. O ícone segue a mesma coluna na metade do tamanho. Nada na tabela é medido; é aritmética,
e esse é o motivo para confiar nela.

**A linha de 420 dpi é o caso que os buckets escondem.** 48 dp nessa tela são 126 pixels, um
tamanho que o arquivo de nenhum bucket tem. A conta funciona para qualquer densidade, porque o
sistema multiplica pela densidade da própria tela. Só um arquivo precisa vir em tamanhos fixos, e
quando não há arquivo para 420 dpi o sistema pega o do bucket mais próximo e o redimensiona, um
pouco para baixo a partir dos 144 do xxhdpi ou bastante para cima a partir dos 96 do xhdpi.

**A tabela do iOS é mais curta porque os degraus são.** @2x e @3x são os fatores de escala que os
iPhones usam, então o mesmo botão tem 96 ou 144 pixels, as mesmas contagens do xhdpi e do xxhdpi do
Android. A linha @1x está ali para mostrar a referência que as diretrizes definem, um pixel por
ponto.

## Por que não dar a toda tela o maior arquivo?

O último bloco da saída responde. **Um ícone raster são sete arquivos**: cinco para os buckets do
Android e dois para os fatores de escala do iOS, com 24x24 pixels no menor e 96x96 no maior. Um
único arquivo de 96x96 reduzido em toda tela ficaria aceitável, e também faria um celular mdpi
decodificar dezesseis vezes os pixels que mostra, para cada ícone, toda vez. Fornecer cada tamanho,
ou desenhar o ícone uma vez como vetor, são as duas respostas honestas, e a próxima seção pesa as
duas.
