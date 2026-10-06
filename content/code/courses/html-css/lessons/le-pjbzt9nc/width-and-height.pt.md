---
title: Width e height: reservando o espaço
version: 1
---

Você já passou por isto como leitor: começa a ler um parágrafo, uma imagem acima termina de carregar e o parágrafo pula para baixo na tela. Isso se chama **deslocamento de layout** (*layout shift*), e acontece porque o navegador não sabia a altura da imagem até o arquivo chegar. A cura são dois atributos que dizem isso a ele de antemão.

Aqui estão duas imagens do mesmo arquivo, uma com `width` e `height` e uma sem, cada uma seguida de um parágrafo:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>The shop · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>The shop</h1>
      <img class="sized" src="shelves-480.png" width="480" height="320" alt="The fiction shelves">
      <p class="after-sized">Fiction is at the front.</p>
      <img class="unsized" src="shelves-480.png" alt="The poetry corner">
      <p class="after-unsized">Poetry is at the back.</p>
    </main>
  </body>
</html>
```

`probe --hold-images` segura toda requisição de imagem até o passo `release`, para a página poder ser medida no momento em que uma conexão lenta a mostraria, e de novo quando as imagens chegam:

```
ana@laptop:~/site$ probe --hold-images shift.html box img box p release box img box p
img.sized    x 8      y 79.88  width 480    height 320
img.unsized  x 8      y 467.88 width 0      height 0
p.after-sized    x 8      y 419.88 width 1008   height 18
p.after-unsized  x 8      y 487.88 width 1008   height 18
img.sized    x 8      y 79.88  width 480    height 320
img.unsized  x 8      y 453.88 width 480    height 320
p.after-sized    x 8      y 419.88 width 1008   height 18
p.after-unsized  x 8      y 793.88 width 1008   height 18
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 334\" role=\"img\" aria-label=\"Dois instantâneos de shift.html, desenhados a partir das caixas que o probe mediu, fora de escala. Antes de as imagens chegarem, a imagem com width e height já ocupa 320 pixels, e a sem tamanho tem 0 pixel de altura, com o parágrafo em y 487,88. Depois que chegam, a imagem sem tamanho tem 320 de altura e o parágrafo foi para y 793,88, 306 pixels mais abaixo. O parágrafo embaixo da imagem com tamanho não se mexeu.\"><text x=\"150\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">antes de as imagens chegarem</text><rect x=\"20\" y=\"30\" width=\"260\" height=\"290\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"30\" y=\"44\" width=\"144\" height=\"96\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"102\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">img.sized</text><text x=\"182\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">320</text><rect x=\"30\" y=\"148\" width=\"240\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"159\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">p.after-sized  y 419.88</text><line x1=\"30\" y1=\"179\" x2=\"174\" y2=\"179\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"182\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">img.unsized: 0</text><rect x=\"30\" y=\"188\" width=\"240\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">p.after-unsized  y 487.88</text><text x=\"420\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">depois</text><rect x=\"290\" y=\"30\" width=\"260\" height=\"290\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"300\" y=\"44\" width=\"144\" height=\"96\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"372\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">img.sized</text><text x=\"452\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">320</text><rect x=\"300\" y=\"148\" width=\"240\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"306\" y=\"159\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">p.after-sized  y 419.88</text><rect x=\"300\" y=\"178\" width=\"144\" height=\"96\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"372\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">img.unsized</text><text x=\"452\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">320</text><rect x=\"300\" y=\"282\" width=\"240\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"306\" y=\"293\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">p.after-unsized  y 793.88</text><text x=\"566\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">A com tamanho</text><text x=\"566\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">guardou os 320 pixels</text><text x=\"566\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">desde o início, e nada</text><text x=\"566\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">depois dela se mexeu.</text><text x=\"566\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A sem tamanho tinha</text><text x=\"566\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">0 de altura, depois</text><text x=\"566\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">320: o parágrafo</text><text x=\"566\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">embaixo pulou 306.</text></svg>", "caption": "Width e height deixam o navegador reservar o espaço antes de ter o arquivo."}
```

Antes de os arquivos chegarem, a imagem com tamanho já ocupa **320 pixels**, a altura que os atributos prometeram, e o parágrafo dela fica abaixo desse espaço. A imagem sem tamanho tem **0 por 0**: o navegador não fazia ideia. Depois do release, a imagem com tamanho não mudou, e nem nada do que vem depois dela. A sem tamanho passou a ter 320 de altura e empurrou o parágrafo de y 487,88 para **793,88, 306 pixels mais abaixo**. Quem estava lendo ou prestes a tocar nesse parágrafo o teve arrancado de baixo do dedo.

## Para que servem os dois números

`width` e `height` são o tamanho da imagem em pixels, escritos como números simples, sem unidade. O navegador os usa para duas coisas: o tamanho a desenhar se o CSS não disser outra coisa, e **a proporção da imagem**, 480 para 320 aqui, para conseguir reservar a altura certa mesmo quando o CSS deixa a imagem mais estreita. Esse segundo uso é o que faz valer a pena escrevê-los em layouts responsivos, em que o CSS define `width: 100%; height: auto;`, como a página da próxima seção faz: o navegador calcula a altura a partir da largura que recebe e da proporção que os atributos deram, antes de chegar um byte do arquivo.

A aula 6 apresenta o `aspect-ratio`, a propriedade CSS que faz o mesmo trabalho para qualquer caixa. Para imagens, os atributos no HTML bastam e são o hábito a manter. A nota **Cumulative Layout Shift** do Google, uma das medidas com que `front-performance` trabalha, soma exatamente esses pulos.
