---
title: Crescendo e encolhendo: flex-grow, flex-shrink e flex-basis
version: 1
---

Todo item flex tem três números que decidem o tamanho dele no eixo principal:

- **`flex-basis`**: o tamanho de partida, antes de qualquer crescimento ou encolhimento. O padrão, `auto`, quer dizer o `width` dele, se tiver um, e o tamanho do conteúdo se não tiver.
- **`flex-grow`**: quantas partes do **espaço livre** ele pega quando sobra espaço. O padrão é 0: ele não cresce.
- **`flex-shrink`**: quantas partes da **falta** ele cede quando os itens não cabem. O padrão é 1: todos encolhem igualmente.

## Crescendo

Três livros com `flex-basis: 100px` numa prateleira de 600, com `flex-grow` 1, 2 e 1:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Grow and shrink · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .shelf { display: flex; width: 600px; margin-bottom: 8px; background: #f4f1ea; }
      .book { flex-basis: 100px; background: #2f6f4e; color: white; }
      #grow .a, #grow .c { flex-grow: 1; }
      #grow .b { flex-grow: 2; }
      #shrink .book { flex-basis: 300px; }
      #shrink .b { flex-shrink: 2; }
    </style>
  </head>
  <body>
    <div class="shelf" id="grow">
      <div class="book a">A</div>
      <div class="book b">B</div>
      <div class="book c">C</div>
    </div>
    <div class="shelf" id="shrink">
      <div class="book a">A</div>
      <div class="book b">B</div>
      <div class="book c">C</div>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe grow.html box '#grow .book'
div.book.a  x 0      y 0      width 175    height 24
div.book.b  x 175    y 0      width 250    height 24
div.book.c  x 425    y 0      width 175    height 24
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 168\" role=\"img\" aria-label=\"Um exemplo resolvido de flex-grow. Um contêiner de 600 de largura tem três itens com flex-basis 100, o que deixa 300 pixels de espaço livre. Com flex-grow 1, 2 e 1, o espaço livre vira quatro partes de 75: A recebe uma parte e fica com 175, B recebe duas e fica com 250, C recebe uma e fica com 175.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">contêiner de 600, três itens com flex-basis 100: sobram 300</text><rect x=\"20\" y=\"34\" width=\"100\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">A 100</text><rect x=\"120\" y=\"34\" width=\"100\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">B 100</text><rect x=\"220\" y=\"34\" width=\"100\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">C 100</text><rect x=\"320\" y=\"34\" width=\"300\" height=\"30\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"470\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">espaço livre 300</text><text x=\"20\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">flex-grow 1, 2, 1: os 300 viram 4 partes de 75</text><rect x=\"20\" y=\"106\" width=\"100\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"120\" y=\"106\" width=\"75\" height=\"30\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"107.5\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">A = 100 + 75 = 175</text><rect x=\"195\" y=\"106\" width=\"100\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"295\" y=\"106\" width=\"150\" height=\"30\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">B = 100 + 150 = 250</text><rect x=\"445\" y=\"106\" width=\"100\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"545\" y=\"106\" width=\"75\" height=\"30\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"532.5\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">C = 100 + 75 = 175</text></svg>", "caption": "flex-grow divide o espaço que sobra, não a largura inteira: B não tem o dobro da largura de A."}
```

Os livros começam com 100 cada, então o espaço livre é 600 − 300 = **300**. Os valores de grow somam 4, então cada parte é 300 / 4 = 75. A recebe uma parte, **175**; B recebe duas, **250**; C recebe uma, **175**. O importante é o que não aconteceu: **B não tem o dobro da largura de A**. `flex-grow` divide o espaço que sobra, não a largura inteira. Para B ter o dobro da largura, as bases também precisam ser zero, o que a forma abreviada da seção 09 faz.

## Encolhendo

A segunda prateleira da mesma página dá a cada livro `flex-basis: 300px`, 900 no total numa prateleira de 600, e `flex-shrink: 2` ao B:

```
ana@laptop:~/site$ probe grow.html box '#shrink .book'
div.book.a  x 0      y 32     width 225    height 24
div.book.b  x 225    y 32     width 150    height 24
div.book.c  x 375    y 32     width 225    height 24
```

A falta é de 300. O encolhimento é ponderado pelo valor de shrink **vezes a base**, então um item grande cede mais que um pequeno: aqui as bases são iguais, os pesos são 1, 2 e 1, e os 300 são tirados como 75, 150 e 75. A fica com **225**, B com **150**, C com **225**. A ponderação pela base existe para que um item pequeno não encolha até sumir enquanto um grande mal se mexe.

O encolhimento tem um piso, e ele é o assunto da próxima seção, porque é o bug de Flexbox mais comum que existe.
