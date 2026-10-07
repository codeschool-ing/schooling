---
title: translate, rotate, scale, e a ordem delas
version: 1
---

Um transform é uma lista de **funções**. As comuns:

- **`translate(x, y)`** move. Porcentagens são do tamanho do **próprio** elemento: `translate(-50%, -50%)` move um elemento para cima e para a esquerda em metade da largura e da altura dele, que é o velho truque de centralização.
- **`rotate(ângulo)`** gira, no sentido horário para ângulos positivos: `45deg`, `0.25turn`.
- **`scale(x, y)`** ou `scale(n)` redimensiona o que é desenhado. `scale(-1, 1)` o espelha.
- **`skew(ângulo)`** o inclina; raramente é o que você quer.

Uma lista é aplicada **da direita para a esquerda**, e cada função trabalha no sistema de coordenadas em que a seguinte a deixou. Então a ordem muda o resultado:

```css
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 16px; }
      .tile { width: 60px; height: 60px; margin-bottom: 100px; background: #2f6f4e; }
      .move-then-turn { transform: translateX(200px) rotate(90deg); }
      .turn-then-move { transform: rotate(90deg) translateX(200px); }
      .separate       { rotate: 90deg; translate: 200px; }
    </style>
  </head>
  <body>
    <div class="tile move-then-turn"></div>
    <div class="tile turn-then-move"></div>
    <div class="tile separate"></div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe order.html box .tile style .tile transform
div.tile.move-then-turn  x 216    y 16     width 60     height 60
div.tile.turn-then-move  x 16     y 376    width 60     height 60
div.tile.separate        x 216    y 336    width 60     height 60
div.tile.move-then-turn  transform: matrix(0, 1, -1, 0, 200, 0)
div.tile.turn-then-move  transform: matrix(0, 1, -1, 0, 0, 200)
div.tile.separate  transform: none
```

`translateX(200px) rotate(90deg)` girou o quadrado e depois o moveu 200 para a **direita**: x 216. `rotate(90deg) translateX(200px)` primeiro o moveu ao longo do próprio eixo x, e esse eixo tinha sido girado para apontar **para baixo**: o quadrado está 200 mais abaixo, em y 376, e não andou nada para o lado. As matrizes computadas dizem o mesmo: os dois últimos números são o movimento, 200 para o lado numa e 200 para baixo na outra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois quadrados com as mesmas duas funções de transform em ordens opostas, desenhados em escala 0,6. Com translateX e depois rotate, o quadrado andou 200 pixels para a direita, até x 216. Com rotate e depois translateX, a rotação virou o eixo x do quadrado para baixo, então a translação o levou 200 pixels para baixo, até y 376.\"><defs><marker id=\"ah12\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">translateX(200px) rotate(90deg)</text><rect x=\"20\" y=\"30\" width=\"320\" height=\"190\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"36\" y=\"46\" width=\"36\" height=\"36\" rx=\"1\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><rect x=\"156\" y=\"46\" width=\"36\" height=\"36\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">início</text><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">andou 200 para o lado: x 216</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">rotate(90deg) translateX(200px)</text><rect x=\"380\" y=\"30\" width=\"320\" height=\"190\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"396\" y=\"46\" width=\"36\" height=\"36\" rx=\"1\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><rect x=\"396\" y=\"166\" width=\"36\" height=\"36\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"396\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">início</text><text x=\"380\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">andou 200 para baixo: y 376</text><line x1=\"76\" y1=\"64\" x2=\"150\" y2=\"64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah12)\"></line><line x1=\"414\" y1=\"86\" x2=\"414\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah12)\"></line></svg>", "caption": "As funções são aplicadas da direita para a esquerda, cada uma nos eixos que a anterior deixou."}
```

## As propriedades separadas

`translate`, `rotate` e `scale` também existem como **propriedades próprias**, e o terceiro quadrado as usa. Elas são sempre aplicadas numa ordem fixa, primeiro translate, depois rotate, depois scale, seja qual for a ordem em que você as escreve. Então `rotate: 90deg; translate: 200px` deu o mesmo resultado do primeiro quadrado, x 216, e o `transform` dele é **none**, porque nada foi definido ali. As propriedades separadas são mais fáceis de ler e de mudar uma de cada vez, o que importa mais nas próximas seções: um hover pode mudar `scale` sem repetir o `translate` que o elemento já tinha.
