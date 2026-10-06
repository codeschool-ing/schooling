---
title: Conteúdo, padding, borda e margem
version: 1
---

Para um navegador montando uma página, **todo elemento é um retângulo**, e todo retângulo tem quatro camadas, de dentro para fora: o **conteúdo**, o **padding** em volta dele, a **borda** em volta disso e a **margem** fora da borda. Um parágrafo, um link, um título, uma imagem: todos, mesmo os redondos, que são retângulos desenhados com cantos arredondados.

Aqui está um cartão de evento com um valor para cada camada:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>A card · Andorinha Books</title>
    <style>
      body { margin: 0; }
      .card {
        width: 300px;
        padding: 20px;
        border: 4px solid #2f6f4e;
        margin: 30px;
      }
      .card p { margin: 0; }
    </style>
  </head>
  <body>
    <article class="card">
      <p>Poetry reading: Hilda Hilst. Thursday 8 October, 7 pm.</p>
    </article>
  </body>
</html>
```

E a caixa dele, medida:

```
ana@laptop:~/site$ probe box.html box .card box '.card p'
article.card  x 30     y 30     width 348    height 84
p  x 54     y 54     width 300    height 36
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 282\" role=\"img\" aria-label=\"O modelo de caixa do cartão de box.html, de dentro para fora. A área de conteúdo tem 300 por 36. Em volta, 20 pixels de padding; em volta disso, uma borda de 4 pixels; em volta disso, 30 pixels de margem, desenhada tracejada porque fica fora da caixa. O probe informou a caixa como 348 por 84, que é conteúdo, padding e borda: 300 mais 20 mais 20 mais 4 mais 4 dá 348.\"><rect x=\"20\" y=\"20\" width=\"440\" height=\"250\" rx=\"0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"60\" y=\"56\" width=\"360\" height=\"178\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"6\"></rect><rect x=\"90\" y=\"86\" width=\"300\" height=\"118\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"240\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">conteúdo</text><text x=\"240\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">300 × 36</text><text x=\"240\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">padding 20</text><text x=\"240\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">padding 20</text><text x=\"240\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">margin 30</text><text x=\"240\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">margin 30</text><text x=\"330\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">border 4</text><text x=\"498\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">As quatro áreas de .card,</text><text x=\"498\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">de dentro para fora:</text><text x=\"498\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conteúdo, padding, borda,</text><text x=\"498\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">margem.</text><text x=\"498\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">O probe imprimiu a caixa</text><text x=\"498\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">como 348 × 84: a caixa da</text><text x=\"498\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">borda, que é conteúdo,</text><text x=\"498\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">padding e borda, sem margem.</text><text x=\"498\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">300 + 20 + 20 + 4 + 4 = 348</text></svg>", "caption": "width: 300px definiu só a área de conteúdo, que é o padrão, content-box."}
```

O parágrafo de dentro, que é o conteúdo do cartão, tem **300 por 36**: o `width` definido, e a altura de duas linhas de texto. O cartão em si tem **348 por 84**. Isso é o conteúdo mais 20 pixels de padding de cada lado e 4 pixels de borda de cada lado: 300 + 40 + 8 = 348 na horizontal, e 36 + 40 + 8 = 84 na vertical. O que `probe box` imprime, e o que o DevTools destaca quando você passa o mouse, é a **caixa da borda** (*border box*): conteúdo, padding e borda. A margem fica fora dela, e é por isso que o cartão começa em x 30 e y 30.

## Para que serve cada camada

**Padding** é espaço dentro da caixa: a cor de fundo o preenche, e clicar nele é clicar no elemento. **Borda** é a linha em volta do padding, com uma largura, um estilo e uma cor: `4px solid #2f6f4e`. **Margem** é espaço fora da caixa: sempre transparente, nunca clicável, e o vão entre este elemento e os vizinhos.

Cada um dos três aceita de um a quatro valores, no sentido horário a partir do topo: `padding: 20px` são os quatro lados, `padding: 10px 20px` é cima e baixo 10, esquerda e direita 20, e `padding: 5px 10px 15px 20px` é cima, direita, baixo, esquerda. Cada lado também pode ser definido sozinho, `padding-left: 20px`. O DevTools desenha as quatro camadas como retângulos aninhados no painel **Computed**, com o número de cada lado, e esse é o jeito mais rápido de ler de onde vem um vão.

## O espaço embaixo das imagens, removido de propósito

A aula 1 mediu uma `<div>` 4 pixels mais alta que a imagem dentro dela, e prometeu que esta aula removeria o espaço de propósito. O motivo está na próxima seção: uma imagem é em linha (*inline*) por padrão e fica sobre a linha de texto como uma letra.
