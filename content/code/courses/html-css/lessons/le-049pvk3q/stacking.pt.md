---
title: Qual caixa fica por cima: z-index e contextos de empilhamento
version: 1
---

Quando caixas posicionadas se sobrepõem, algo tem de decidir qual é desenhada na frente. Sem instrução nenhuma, **o que vem depois no HTML fica por cima**, e caixas posicionadas são desenhadas acima das caixas do fluxo normal. **`z-index`** muda essa ordem: maior fica na frente. Ele funciona em caixas posicionadas, e em itens flex e grid, que as aulas 8 e 9 apresentam.

Essa é a parte que todo mundo conhece, e ela leva direto a um enigma. Aqui está um cabeçalho com um menu suspenso em `z-index: 9999`, seguido de uma seção de destaque em `z-index: 2`, arrumados para se sobrepor:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Stacking · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      header { position: relative; z-index: 1; height: 60px; background: #2f6f4e; }
      .menu {
        position: absolute;
        top: 40px;
        left: 20px;
        z-index: 9999;
        width: 200px;
        height: 120px;
        background: white;
        border: 1px solid #333;
      }
      .hero { position: relative; z-index: 2; height: 200px; background: #f4f1ea; }
    </style>
  </head>
  <body>
    <header>
      <ul class="menu">
        <li>Events</li>
        <li>Order a book</li>
      </ul>
    </header>
    <section class="hero"><h1>This week</h1></section>
  </body>
</html>
```

O primeiro comando mede o menu e o destaque e pergunta o que está desenhado por cima no ponto 100,120, onde eles se sobrepõem; o segundo pergunta o mesmo a `stacking-fixed.html`, a mesma página com uma declaração a menos, que o fim desta seção explica:

```
ana@laptop:~/site$ probe stacking.html box .menu box .hero top 100 120
ul.menu  x 20     y 56     width 242    height 122
section.hero  x 0      y 81.44  width 1024   height 200
at 100,120: h1  "This week"
ana@laptop:~/site$ probe stacking-fixed.html top 100 120
at 100,120: ul.menu  "Events Order a book"
```

**Na primeira página, o título do destaque está por cima.** Um menu em 9999 fica embaixo de uma caixa em 2.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 254\" role=\"img\" aria-label=\"Contextos de empilhamento em stacking.html. Dentro do contexto da página ficam o header, com z-index 1, e o hero, com z-index 2. O menu, com z-index 9999, está dentro do header, então é pintado como parte da camada do header no nível 1, e o hero no nível 2 o cobre. Sem o z-index do header, o menu disputa no nível da página e vence.\"><rect x=\"20\" y=\"20\" width=\"330\" height=\"220\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o contexto de empilhamento da página</text><rect x=\"36\" y=\"52\" width=\"300\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"48\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">header  z-index: 1</text><rect x=\"60\" y=\"84\" width=\"260\" height=\"46\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"72\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.menu  z-index: 9999</text><rect x=\"36\" y=\"156\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"48\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.hero  z-index: 2</text><text x=\"372\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">header tem z-index: 1, então cria um contexto</text><text x=\"372\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">de empilhamento: tudo dentro dele é pintado como</text><text x=\"372\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma camada no nível 1. O 9999 do menu só o</text><text x=\"372\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ordena entre os filhos do próprio header.</text><text x=\"372\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">No nível da página a disputa é header 1 contra</text><text x=\"372\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">hero 2, e o hero vence: o probe achou o h1</text><text x=\"372\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dele por cima em 100,120.</text><text x=\"372\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Tire o z-index do header e o menu disputa no</text><text x=\"372\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nível da página com o seu 9999.</text></svg>", "caption": "z-index só é comparado entre irmãos do mesmo contexto de empilhamento."}
```

## Contextos de empilhamento

`z-index` não é um ranking global único. Um elemento posicionado **com um `z-index` diferente de `auto`** cria um **contexto de empilhamento**: tudo dentro dele é pintado junto, como uma camada só, no nível desse elemento, e os valores de `z-index` dos descendentes só os ordenam entre si, dentro dessa camada. O cabeçalho tem `z-index: 1`, então o 9999 do menu quer dizer "primeiro entre os filhos do cabeçalho". No nível da página, a disputa é o 1 do cabeçalho contra o 2 do destaque, e o destaque vence, com o cabeçalho inteiro, menu incluído, embaixo dele.

Tire o `z-index` do cabeçalho, que é o que `stacking-fixed.html` faz, e o cabeçalho deixa de criar um contexto de empilhamento. Esse foi o segundo comando acima: ali o menu, `ul.menu`, está por cima no mesmo ponto, disputando no nível da página com o seu 9999 contra o 2 do destaque.

**Várias outras propriedades também criam contextos de empilhamento**: uma `opacity` menor que 1, qualquer `transform`, um `filter`, `position: fixed` ou `sticky`, e `isolation: isolate`, que existe só para criar um. Então um esmaecimento num pai pode empurrar o menu suspenso dele para baixo da seção seguinte.

## Mantendo o z-index são

Quando uma caixa está embaixo de algo, a correção quase nunca é um número maior: 9999 perdeu para 2. Encontre os ancestrais que criam contextos de empilhamento, o que o painel **Layers** do DevTools e a visão 3D do Edge mostram, e decida nesse nível. Mantenha uma escala curta de valores com nomes, para que um modal fique sempre acima de um menu e um menu acima do conteúdo, o que a aula 10 escreve como variáveis.
