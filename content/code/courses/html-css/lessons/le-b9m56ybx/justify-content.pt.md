---
title: Distribuindo ao longo do eixo principal: justify-content
version: 1
---

Quando os itens não preenchem o eixo principal, **`justify-content`** decide o que fazer com o espaço que sobra. Aqui estão seis prateleiras, cada uma com 600 de largura e três livros de 100, então há sempre 300 pixels a posicionar; cada prateleira usa um valor diferente:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>justify-content · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .shelf { display: flex; width: 600px; margin-bottom: 8px; background: #f4f1ea; }
      .book { width: 100px; background: #2f6f4e; color: white; }
      #flex-start { justify-content: flex-start; }
      #center { justify-content: center; }
      #flex-end { justify-content: flex-end; }
      #space-between { justify-content: space-between; }
      #space-around { justify-content: space-around; }
      #space-evenly { justify-content: space-evenly; }
    </style>
  </head>
  <body>
    <div class="shelf" id="flex-start">
      <div class="book">A</div>
      <div class="book">B</div>
      <div class="book">C</div>
    </div>
    <div class="shelf" id="center">
      <div class="book">A</div>
      <div class="book">B</div>
      <div class="book">C</div>
    </div>
    <div class="shelf" id="flex-end">
      <div class="book">A</div>
      <div class="book">B</div>
      <div class="book">C</div>
    </div>
    <div class="shelf" id="space-between">
      <div class="book">A</div>
      <div class="book">B</div>
      <div class="book">C</div>
    </div>
    <div class="shelf" id="space-around">
      <div class="book">A</div>
      <div class="book">B</div>
      <div class="book">C</div>
    </div>
    <div class="shelf" id="space-evenly">
      <div class="book">A</div>
      <div class="book">B</div>
      <div class="book">C</div>
    </div>
  </body>
</html>
```

O `probe` imprimiu onde cada livro começa. Quatro das seis:

```
ana@laptop:~/site$ probe justify.html box '#center .book'
div.book  x 150    y 32     width 100    height 24
div.book  x 250    y 32     width 100    height 24
div.book  x 350    y 32     width 100    height 24
ana@laptop:~/site$ probe justify.html box '#space-between .book'
div.book  x 0      y 96     width 100    height 24
div.book  x 250    y 96     width 100    height 24
div.book  x 500    y 96     width 100    height 24
ana@laptop:~/site$ probe justify.html box '#space-around .book'
div.book  x 50     y 128    width 100    height 24
div.book  x 250    y 128    width 100    height 24
div.book  x 450    y 128    width 100    height 24
ana@laptop:~/site$ probe justify.html box '#space-evenly .book'
div.book  x 75     y 160    width 100    height 24
div.book  x 250    y 160    width 100    height 24
div.book  x 425    y 160    width 100    height 24
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Seis contêineres de 600 pixels de largura, cada um com três itens de 100, desenhados nas posições x medidas. flex-start: 0, 100, 200. center: 150, 250, 350. flex-end: 300, 400, 500. space-between: 0, 250, 500. space-around: 50, 250, 450. space-evenly: 75, 250, 425.\"><text x=\"20\" y=\"27\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">flex-start</text><rect x=\"150\" y=\"14\" width=\"480\" height=\"26\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"150\" y=\"17\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"190\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A</text><rect x=\"230\" y=\"17\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"270\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B</text><rect x=\"310\" y=\"17\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"350\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">C</text><text x=\"640\" y=\"27\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 100 200</text><text x=\"20\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">center</text><rect x=\"150\" y=\"50\" width=\"480\" height=\"26\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"270\" y=\"53\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"310\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A</text><rect x=\"350\" y=\"53\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B</text><rect x=\"430\" y=\"53\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"470\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">C</text><text x=\"640\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150 250 350</text><text x=\"20\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">flex-end</text><rect x=\"150\" y=\"86\" width=\"480\" height=\"26\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"390\" y=\"89\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"430\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A</text><rect x=\"470\" y=\"89\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"510\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B</text><rect x=\"550\" y=\"89\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"590\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">C</text><text x=\"640\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300 400 500</text><text x=\"20\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">space-between</text><rect x=\"150\" y=\"122\" width=\"480\" height=\"26\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"150\" y=\"125\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"190\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A</text><rect x=\"350\" y=\"125\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B</text><rect x=\"550\" y=\"125\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"590\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">C</text><text x=\"640\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 250 500</text><text x=\"20\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">space-around</text><rect x=\"150\" y=\"158\" width=\"480\" height=\"26\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"190\" y=\"161\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"230\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A</text><rect x=\"350\" y=\"161\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B</text><rect x=\"510\" y=\"161\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"550\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">C</text><text x=\"640\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50 250 450</text><text x=\"20\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">space-evenly</text><rect x=\"150\" y=\"194\" width=\"480\" height=\"26\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"197\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"250\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A</text><rect x=\"350\" y=\"197\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B</text><rect x=\"490\" y=\"197\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"530\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">C</text><text x=\"640\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">75 250 425</text></svg>", "caption": "Os 300 pixels que sobram, divididos de seis jeitos. Os números são onde cada item começa."}
```

- **`flex-start`**, o padrão: os livros em 0, 100 e 200, e os 300 pixels todos depois deles.
- **`center`**: 150 pixels antes e 150 depois. Os livros em 150, 250, 350.
- **`flex-end`**: os 300 todos antes deles.
- **`space-between`**: o primeiro livro no começo, o último no fim, e os 300 divididos entre os dois vãos, 150 cada. Os livros em 0, 250, 500.
- **`space-around`**: cada livro recebe uma parte igual dos dois lados, 50 cada, então os vãos entre livros, 100, são o dobro dos vãos das pontas, 50. Os livros em 50, 250, 450.
- **`space-evenly`**: os quatro vãos, antes, entre e depois, são todos iguais: 300 / 4 = 75. Os livros em 75, 250, 425.

`space-between` é o de um cabeçalho com o logotipo à esquerda e o menu à direita. `center` é metade de centralizar algo, seção 11. A diferença entre `space-around` e `space-evenly` é a que as pessoas confundem, e os números resolvem: around dá a todo item a mesma margem, evenly dá a todo vão a mesma largura.

## O espaço só existe se nada crescer

Os seis supõem que os itens mantêm o próprio tamanho. Se algum item tem `flex-grow`, seção 07, ele pega o espaço livre para si, e não sobra nada para o `justify-content` distribuir. É o motivo usual de um `justify-content` parecer não fazer nada.
