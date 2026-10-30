---
title: Nove janelas, separadas em classes
version: 1
---

**Este programa aplica os pontos de quebra do Android e a regra de dois painéis do planner a uma
lista de janelas, para que as decisões das seções anteriores possam ser conferidas uma janela por
vez.** As janelas são exemplos. Os tamanhos delas em dp são números redondos escolhidos para cair
em cada classe e mostrar o mesmo aparelho em dois formatos; **eles não são medidas de nenhum
celular, dobrável ou tablet real**, e um aparelho real de cada tipo pode cair em outra classe.
Salve-o como `sizeclass.ts` em `~/planner`:

```typescript
// sizeclass.ts: a window's size classes, and one pane or two for the planner
type Win = { name: string; w: number; h: number }; // sizes in dp

// Android's width breakpoints, in dp, as its documentation lists them
function widthClass(w: number): string {
  if (w < 600) return "compact";
  if (w < 840) return "medium";
  if (w < 1200) return "expanded";
  if (w < 1600) return "large";
  return "extra-large";
}

// And its height breakpoints
function heightClass(h: number): string {
  if (h < 480) return "compact";
  if (h < 900) return "medium";
  return "expanded";
}

// The planner's rule: the course list and a course's detail side by side
// only in a window at least expanded wide and not compact tall
function panes(win: Win): string {
  return win.w >= 840 && win.h >= 480 ? "two: list | detail" : "one: list, then detail";
}

// Example windows, in dp. They are round numbers chosen to land in each class,
// not measurements of any real device.
const windows: Win[] = [
  { name: "phone, portrait", w: 360, h: 800 },
  { name: "phone, landscape", w: 800, h: 360 },
  { name: "foldable, folded", w: 360, h: 780 },
  { name: "foldable, open, portrait", w: 700, h: 880 },
  { name: "foldable, open, landscape", w: 880, h: 700 },
  { name: "tablet, portrait", w: 800, h: 1280 },
  { name: "tablet, landscape", w: 1280, h: 800 },
  { name: "tablet, half in split screen", w: 640, h: 800 },
  { name: "desktop window, short", w: 1000, h: 420 },
];

console.log(`${"window".padEnd(29)}${"dp".padStart(11)}  ${"width".padEnd(9)} ${"height".padEnd(9)} panes`);
for (const win of windows) {
  const size = `${win.w} x ${win.h}`;
  console.log(
    `${win.name.padEnd(29)}${size.padStart(11)}  ${widthClass(win.w).padEnd(9)} ${heightClass(win.h).padEnd(9)} ${panes(win)}`,
  );
}
```

```
ana@dev:~/planner$ node sizeclass.ts
window                                dp  width     height    panes
phone, portrait                360 x 800  compact   medium    one: list, then detail
phone, landscape               800 x 360  medium    compact   one: list, then detail
foldable, folded               360 x 780  compact   medium    one: list, then detail
foldable, open, portrait       700 x 880  medium    medium    one: list, then detail
foldable, open, landscape      880 x 700  expanded  medium    two: list | detail
tablet, portrait              800 x 1280  medium    expanded  one: list, then detail
tablet, landscape             1280 x 800  large     medium    two: list | detail
tablet, half in split screen   640 x 800  medium    medium    one: list, then detail
desktop window, short         1000 x 420  expanded  compact   one: list, then detail
```

## Lendo linha por linha

**O mesmo celular são duas janelas diferentes.** Em retrato ele é compact de largura e medium de
altura; deitado ele é medium de largura e compact de altura. Nenhum dos dois ganha dois painéis: o
primeiro é estreito demais, e o segundo é baixo demais, que é exatamente o caso de paisagem que a
documentação do Android descreve.

**O mesmo dobrável cruza a linha quando abre, e só num dos jeitos de segurá-lo.** Fechado, com 360
dp de largura, ele é um celular. Aberto e em retrato, 700 dp, ele é medium e ainda mostra um painel.
Aberto e virado, 880 dp, ele é expanded e mostra lista e detalhe lado a lado. Um app de verdade num
dobrável de verdade faz essa troca enquanto o aluno está olhando um curso, e é por isso que o curso
escolhido precisa sobreviver a ela.

**O mesmo tablet são três janelas.** Em retrato ele é medium de largura, um painel; em paisagem ele
é large, dois painéis; e metade dele em tela dividida, 640 dp, é medium de novo. Nada no aparelho
mudou entre as duas últimas linhas. Só a janela mudou.

**A última linha é o motivo da condição de altura.** Uma janela de desktop com 1000 dp de largura e
420 dp de altura é expanded pela largura e compact pela altura. Dois painéis com 420 dp de altura
mostrariam cada um poucas linhas de uma lista e um detalhe apertado, então a regra volta para um.

## O que o programa não decide

Ele não desenha nada; decidir a classe é a parte que é igual em toda plataforma, e desenhar dois
painéis é tarefa do kit de interface depois da bifurcação. **Ele não cobre as classes próprias do
iOS**, compact e regular, porque a Apple não as publica como números para comparar: um app iOS
pergunta ao sistema em qual delas está. E ele põe o ponto de quebra do planner em expanded porque o
detalhe de um curso precisa de espaço; um app cujo detalhe é um único cartão curto poderia, com
razão, dividir em medium. A regra é uma decisão que o app toma uma vez e escreve, e é tudo o que
esta aula pede.
