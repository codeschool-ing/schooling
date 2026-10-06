---
title: Alinhando através: align-items e align-self
version: 1
---

**`align-items`** posiciona os itens no eixo cruzado, o que numa linha quer dizer na vertical. Aqui estão quatro prateleiras de 100 pixels de altura, cada uma com três itens cujo texto tem 12, 28 e 16 pixels, então as alturas naturais diferem:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>align-items · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .shelf { display: flex; gap: 8px; height: 100px; margin-bottom: 8px; background: #f4f1ea; }
      .book { padding: 4px 8px; background: #2f6f4e; color: white; }
      .small { font-size: 12px; }
      .big { font-size: 28px; }
      #stretch { align-items: stretch; }
      #flex-start { align-items: flex-start; }
      #center { align-items: center; }
      #baseline { align-items: baseline; }
    </style>
  </head>
  <body>
    <div class="shelf" id="stretch">
      <div class="book small">Poetry</div>
      <div class="book big">Fiction</div>
      <div class="book">Children</div>
    </div>
    <div class="shelf" id="flex-start">
      <div class="book small">Poetry</div>
      <div class="book big">Fiction</div>
      <div class="book">Children</div>
    </div>
    <div class="shelf" id="center">
      <div class="book small">Poetry</div>
      <div class="book big">Fiction</div>
      <div class="book">Children</div>
    </div>
    <div class="shelf" id="baseline">
      <div class="book small">Poetry</div>
      <div class="book big">Fiction</div>
      <div class="book">Children</div>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe align.html box '#stretch .book'
div.book.small  x 0      y 0      width 50.69  height 100
div.book.big    x 58.69  y 0      width 98.47  height 100
div.book        x 165.16 y 0      width 75.59  height 100
ana@laptop:~/site$ probe align.html box '#flex-start .book'
div.book.small  x 0      y 108    width 50.69  height 26
div.book.big    x 58.69  y 108    width 98.47  height 50
div.book        x 165.16 y 108    width 75.59  height 32
ana@laptop:~/site$ probe align.html box '#center .book'
div.book.small  x 0      y 253    width 50.69  height 26
div.book.big    x 58.69  y 241    width 98.47  height 50
div.book        x 165.16 y 250    width 75.59  height 32
ana@laptop:~/site$ probe align.html box '#baseline .book'
div.book.small  x 0      y 341    width 50.69  height 26
div.book.big    x 58.69  y 324    width 98.47  height 50
div.book        x 165.16 y 337    width 75.59  height 32
```

As prateleiras estão empilhadas a 108 pixels uma da outra, então o y de cada item no `probe` inclui a posição da prateleira: a de stretch começa em 0, a de flex-start em 108, a de center em 216 e a de baseline em 324. Descontando isso:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 214\" role=\"img\" aria-label=\"Quatro contêineres flex de 100 pixels de altura, cada um com três itens com texto de 12, 28 e 16 pixels. stretch: os três têm 100 de altura. flex-start: mantêm a própria altura, 26, 50 e 32, no topo. center: cada um é centralizado, a 37, 25 e 34 do topo. baseline: são postos de modo que as linhas de base do texto se alinhem, a 17, 0 e 13 do topo.\"><text x=\"20\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">stretch</text><rect x=\"20\" y=\"26\" width=\"149.42\" height=\"140\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"20\" y=\"26\" width=\"31.43\" height=\"140\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"56.39\" y=\"26\" width=\"61.05\" height=\"140\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"122.4\" y=\"26\" width=\"46.87\" height=\"140\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"196\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">flex-start</text><rect x=\"196\" y=\"26\" width=\"149.42\" height=\"140\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"196\" y=\"26\" width=\"31.43\" height=\"36.4\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"232.39\" y=\"26\" width=\"61.05\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"298.4\" y=\"26\" width=\"46.87\" height=\"44.8\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"372\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">center</text><rect x=\"372\" y=\"26\" width=\"149.42\" height=\"140\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"372\" y=\"77.8\" width=\"31.43\" height=\"36.4\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408.39\" y=\"61\" width=\"61.05\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"474.4\" y=\"73.6\" width=\"46.87\" height=\"44.8\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"548\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">baseline</text><rect x=\"548\" y=\"26\" width=\"149.42\" height=\"140\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"548\" y=\"49.8\" width=\"31.43\" height=\"36.4\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"584.39\" y=\"26\" width=\"61.05\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"650.4\" y=\"44.2\" width=\"46.87\" height=\"44.8\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Três itens com texto de 12, 28 e 16 pixels em contêineres de 100 de altura, desenhados das caixas medidas.</text><text x=\"20\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">baseline alinha o texto dentro dos itens, e por isso as próprias caixas ficam desencontradas.</text></svg>", "caption": "align-items posiciona os itens no eixo cruzado; stretch, o padrão, é por que colunas flex saem com alturas iguais."}
```

- **`stretch`**, o padrão: todo item tem **100 de altura**, a altura inteira da prateleira, seja qual for o texto.
- **`flex-start`**: cada um mantém a própria altura, **26, 50 e 32**, no topo da prateleira, que começa em 108.
- **`center`**: cada um é centralizado, a **37, 25 e 34** do topo, que é (100 − 26) / 2, (100 − 50) / 2 e (100 − 32) / 2.
- **`baseline`**: os itens se movem para que **as primeiras linhas do texto fiquem na mesma linha**: 17, 0 e 13 do topo. As caixas ficam desencontradas e as palavras se leem como uma linha só, que é o que uma fileira com um preço, um título e um rótulo quer.

## Um item sozinho: `align-self`

`align-self` num item sobrescreve o `align-items` do contêiner só para esse item: uma fileira de cartões esticados com um cartão `align-self: flex-start` que mantém a própria altura. Não existe `justify-self` no Flexbox, porque ao longo do eixo principal os itens são posicionados como grupo; para afastar um item dos outros, o Flexbox usa uma margem `auto`, seção 11.

## Centralizando algo

`justify-content: center` e `align-items: center` juntos centralizam os itens nas duas direções, e por muito tempo esse par foi o motivo de as pessoas aprenderem Flexbox. A seção 11 faz isso na mensagem de cesta vazia do sebo.
