---
title: A área segura e o botão de adicionar sessão, calculados
version: 1
---

**Este programa recebe uma tela e os insets dela, calcula a área segura e então posiciona o botão
de adicionar sessão do planner de três jeitos: na borda da tela, na borda da área segura e acima do
teclado.** Para cada posição ele diz o que cobre o botão, se algo cobre. O tamanho da tela, os
insets e a altura do teclado são **valores de exemplo**, números redondos do tipo que um celular
informa em pontos ou dp; eles não são medidas de nenhum celular em particular, e um aparelho real
informa os seus. Salve-o como `insets.ts` em `~/planner`:

```typescript
// insets.ts: the part of a screen an app can use, and whether the keyboard hides a button
type Insets = { top: number; bottom: number; left: number; right: number };
type Case = { name: string; w: number; h: number; insets: Insets; keyboard: number };

// Example values in dp or points, round numbers of the kind a phone reports.
// They are not measurements of any particular device.
const cases: Case[] = [
  { name: "portrait", w: 390, h: 844, insets: { top: 48, bottom: 32, left: 0, right: 0 }, keyboard: 0 },
  { name: "landscape", w: 844, h: 390, insets: { top: 0, bottom: 24, left: 48, right: 48 }, keyboard: 0 },
  { name: "portrait, keyboard up", w: 390, h: 844, insets: { top: 48, bottom: 32, left: 0, right: 0 }, keyboard: 300 },
];

const BUTTON = 48; // the "add session" button's height
const MARGIN = 16; // its gap above whatever edge it sits on

// Where the button lands if its bottom edge sits MARGIN above `edge`
function button(edge: number) {
  return { top: edge - MARGIN - BUTTON, bottom: edge - MARGIN };
}

// What covers it: the keyboard, the bottom inset, or nothing
function covered(b: { top: number; bottom: number }, c: Case): string {
  if (c.keyboard > 0 && b.bottom > c.h - c.keyboard) return "under the keyboard";
  if (b.bottom > c.h - c.insets.bottom) return "under the bottom inset";
  return "clear";
}

for (const c of cases) {
  const i = c.insets;
  const safe = { x0: i.left, x1: c.w - i.right, y0: i.top, y1: c.h - i.bottom };
  console.log(`${c.name}: screen ${c.w} x ${c.h}, keyboard ${c.keyboard}`);
  console.log(`  ${"safe area".padEnd(26)} x ${safe.x0}-${safe.x1}, y ${safe.y0}-${safe.y1}` +
    ` (${safe.x1 - safe.x0} x ${safe.y1 - safe.y0})`);
  const placements: [string, number][] = [
    ["at the screen edge", c.h],
    ["in the safe area", c.h - i.bottom],
    ["above the keyboard", c.h - Math.max(i.bottom, c.keyboard)],
  ];
  for (const [label, edge] of placements) {
    if (label === "above the keyboard" && c.keyboard === 0) continue;
    const b = button(edge);
    console.log(`  button ${label.padEnd(19)} y ${b.top}-${b.bottom}  ${covered(b, c)}`);
  }
}
```

```
ana@dev:~/planner$ node insets.ts
portrait: screen 390 x 844, keyboard 0
  safe area                  x 0-390, y 48-812 (390 x 764)
  button at the screen edge  y 780-828  under the bottom inset
  button in the safe area    y 748-796  clear
landscape: screen 844 x 390, keyboard 0
  safe area                  x 48-796, y 0-366 (748 x 366)
  button at the screen edge  y 326-374  under the bottom inset
  button in the safe area    y 302-350  clear
portrait, keyboard up: screen 390 x 844, keyboard 300
  safe area                  x 0-390, y 48-812 (390 x 764)
  button at the screen edge  y 780-828  under the keyboard
  button in the safe area    y 748-796  under the keyboard
  button above the keyboard  y 480-528  clear
```

## Lendo a saída

**Em retrato sem teclado, a área segura é a tela menos 48 em cima e 32 embaixo**: 390 por 764 de um
total de 390 por 844. Um botão posto 16 acima da borda de baixo da própria tela fica entre 780 e
828, e o inset de baixo começa em 812, então a área de gestos cobre a parte de baixo dele. Posto 16
acima da borda de baixo da área segura, de 748 a 796, ele fica livre. Esse é o primeiro erro inteiro
e a correção dele, em duas linhas.

**Em paisagem os insets vão para as laterais.** O exemplo põe 48 à esquerda e à direita, onde agora
ficam o recorte e os cantos arredondados, e só 24 embaixo, então a área segura tem 748 de largura e
366 de altura. O botão segue a mesma regra e fica livre na área segura de novo. Um app que leu
"top 48" ao abrir e o guardou deixaria agora uma faixa vazia em cima e desenharia a lista no
recorte da lateral.

**Com o teclado aberto, a área segura sozinha não basta.** O teclado tem 300 de altura e cobre tudo
abaixo de 544, então o botão em 748 a 796, livre um instante antes, fica embaixo das teclas. Posto
16 acima da mais alta das duas bordas de baixo, o topo do teclado ou a borda de baixo da área
segura, ele fica em 480 a 528 e livre. Esse `Math.max` é a linha que a ferramenta de cada plataforma
da seção anterior roda por você: `imePadding()`, a região de teclado do SwiftUI, o
`KeyboardAvoidingView`.

## O que o programa deixa de fora

Ele trabalha numa dimensão, a altura, porque o botão e o teclado estão os dois embaixo; um layout
de verdade aplica os insets da esquerda e da direita também à largura do botão, o que a linha da
área segura já mostra. Ele trata o teclado como se aparecesse de uma vez, quando um teclado de
verdade é animado, e um app pode acompanhar a animação quadro a quadro, na thread principal da
aula 6. E ele não sabe nada sobre a altura real do teclado: o teclado de um celular pode mudar de altura com o
idioma, a barra de sugestões e as configurações do próprio usuário, e é esse o motivo de toda
plataforma o informar como um inset e não como uma constante.
