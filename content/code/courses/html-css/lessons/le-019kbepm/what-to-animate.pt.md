---
title: O que é barato animar
version: 2
---

A aula 10 de `web-fundamentals` descreveu o trabalho do navegador a cada quadro: **estilo**, depois **layout**, depois **pintura**, depois a **composição** das camadas pintadas. Uma animação roda esse trabalho até sessenta vezes por segundo, e quanto dele cada quadro precisa depende da propriedade animada. Dois pontos deslizam 200 pixels para lá e para cá, um animando `margin-left`, o outro animando `transform: translateX()`. O primeiro é o `cost-margin.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      .dot { width: 24px; height: 24px; background: #8a1c1c;
             animation: by-margin 1s linear infinite alternate; }
      @keyframes by-margin { to { margin-left: 200px; } }
    </style>
  </head>
  <body>
    <div class="dot"></div>
  </body>
</html>
```

O `cost-transform.html` é uma cópia com a animação renomeada e o único keyframe movendo por `transform`: `animation: by-transform 1s linear infinite alternate;` e `@keyframes by-transform { to { transform: translateX(200px); } }`. O passo novo **`frames`** deixa cada página rodar por um segundo e lê os contadores do próprio Chromium:

```
ana@laptop:~/site$ probe cost-margin.html frames 1000
in 1000 ms: 62 layouts, 62 style recalculations
ana@laptop:~/site$ probe cost-transform.html frames 1000
in 1000 ms: 0 layouts, 1 style recalculations
```

`margin-left`: **62 layouts e 62 recálculos de estilo** em um segundo, mais ou menos um de cada por quadro. A cada quadro, o navegador recalculou o estilo do ponto, montou a página de novo para descobrir onde vão o ponto e tudo depois dele, e pintou. `transform`: **0 layouts e 1 recálculo de estilo**, o do início. O navegador entregou a animação ao **compositor**, que move uma camada já pintada a cada quadro sem perguntar nada à thread principal.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 196\" role=\"img\" aria-label=\"As quatro etapas do trabalho do navegador por quadro: estilo, layout, pintura e composição. Animar margin-left roda as quatro em todo quadro, e a captura contou 62 layouts e 62 recálculos de estilo em um segundo. Animar transform roda só a composição em cada quadro, com 0 layouts e 1 recálculo de estilo no início.\"><rect x=\"150\" y=\"14\" width=\"116\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"208\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">estilo</text><rect x=\"290\" y=\"14\" width=\"116\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"348\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">layout</text><rect x=\"430\" y=\"14\" width=\"116\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"488\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">pintura</text><rect x=\"570\" y=\"14\" width=\"116\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"628\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">composição</text><text x=\"20\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">margin-left</text><rect x=\"150\" y=\"64\" width=\"116\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"290\" y=\"64\" width=\"116\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"430\" y=\"64\" width=\"116\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"570\" y=\"64\" width=\"116\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"150\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">todo quadro: 62 layouts e 62 recálculos de estilo em um segundo</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">transform</text><rect x=\"150\" y=\"134\" width=\"116\" height=\"24\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"290\" y=\"134\" width=\"116\" height=\"24\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"430\" y=\"134\" width=\"116\" height=\"24\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"570\" y=\"134\" width=\"116\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"150\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">todo quadro: só composição; 0 layouts, 1 recálculo de estilo no início</text></svg>", "caption": "Que etapas cada quadro precisa depende da propriedade animada.", "same": ["layout"]}
```

Nesta página, um ponto é barato de qualquer jeito. Numa página real, um layout por quadro quer dizer que toda caixa da página é reconsiderada sessenta vezes por segundo, na mesma thread que roda o JavaScript da página, e num celular é aí que uma animação começa a engasgar.

## A lista curta

**`transform` e `opacity` são as duas propriedades que um navegador consegue animar no compositor**, junto com `filter` na maioria dos casos. Movimento, escala e rotação devem ser transforms; aparecer e sumir deve ser opacity. `width`, `height`, `margin`, `top` e `left` causam layout; `color`, `background-color` e `box-shadow` causam pintura, que é mais barata que layout e ainda é trabalho a cada quadro. Para um hover curto num botão nada disso importa. Para algo que roda o tempo todo, ou move algo grande, importa.

**`will-change: transform`** avisa o navegador de antemão que um elemento vai receber transform, para que ele o promova a uma camada própria antes de a animação começar. Use nos poucos elementos que precisam, e só quando há um problema medido: toda camada custa memória e, como mostrou a seção 04, também faz do elemento um bloco de contenção e um contexto de empilhamento.
