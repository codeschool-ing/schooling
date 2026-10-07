---
title: relative: deslocada, com o espaço mantido
version: 1
---

**`position: relative`** desenha uma caixa deslocada de onde o fluxo normal a pôs, pelas quantidades em `top`, `left`, `bottom` e `right`, **e deixa o espaço dela no fluxo exatamente onde estava**. Aqui estão três cartões, o do meio deslocado:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Relative · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .card { width: 300px; height: 60px; margin: 20px; background: #f4f1ea; }
      .nudged { position: relative; top: 10px; left: 40px; }
    </style>
  </head>
  <body>
    <div class="card one">One</div>
    <div class="card two nudged">Two</div>
    <div class="card three">Three</div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe relative.html box .card
div.card.one         x 20     y 20     width 300    height 60
div.card.two.nudged  x 60     y 110    width 300    height 60
div.card.three       x 20     y 180    width 300    height 60
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três cartões de relative.html nas posições medidas. One em x 20, y 20. Two é desenhado em x 60, y 110, deslocado 40 para a direita e 10 para baixo a partir de um contorno tracejado em x 20, y 100, onde estaria. Three está em x 20, y 180, exatamente onde estaria se Two não tivesse se movido: o espaço que Two deixou fica reservado.\"><rect x=\"38\" y=\"34\" width=\"270\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">One  x 20, y 20</text><rect x=\"38\" y=\"106\" width=\"270\" height=\"54\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"50\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">onde Two estaria</text><rect x=\"74\" y=\"115\" width=\"270\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"86\" y=\"149\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Two  x 60, y 110</text><rect x=\"38\" y=\"178\" width=\"270\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Three  x 20, y 180</text><text x=\"400\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">top: 10px; left: 40px moveu Two</text><text x=\"400\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">de onde ele estaria, e nada</text><text x=\"400\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mais se mexeu.</text><text x=\"400\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Three está onde estaria se Two</text><text x=\"400\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">não tivesse se movido: o espaço</text><text x=\"400\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">que Two deixou fica reservado.</text></svg>", "caption": "position: relative move o desenho e deixa o espaço onde estava."}
```

O cartão dois estaria em x 20, y 100: 20 pixels de margem abaixo do cartão um, que termina em 80. `top: 10px; left: 40px` o desenhou em **x 60, y 110**, 40 para a direita e 10 para baixo. **O cartão três está em y 180, onde estaria de qualquer jeito**: 100 + 60 + 20. O fluxo continua achando que o cartão dois está em 100, então nada mais se mexeu, e o cartão dois agora sobrepõe o três em 10 pixels.

`top: 10px` quer dizer "10 pixels para baixo a partir do topo de onde você estaria", o que de início parece ao contrário: o inset diz a partir de que borda o deslocamento é medido, e um valor positivo se afasta dessa borda, para dentro do espaço da caixa.

## Para que o relative serve de verdade

Empurrar caixas alguns pixels raramente é o uso do `relative`: sobrepor o vizinho, como o cartão dois faz, costuma ser um bug. **O uso real dele é ser a referência para filhos posicionados de forma absoluta.** Uma caixa com `position: relative` e nenhum deslocamento fica exatamente onde está, e vira a caixa a partir da qual os filhos absolutos são medidos. Isso são as próximas duas seções, e é por isso que você vai escrever `position: relative` sem `top` nem `left` muito mais vezes do que com eles.
