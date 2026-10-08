---
title: Block, inline e inline-block
version: 2
---

Se width, height e margens fazem alguma coisa num elemento depende do **`display`** dele. Dois valores vieram antes de todo o resto, e o navegador dá um deles a cada elemento por padrão:

- **`block`**: a caixa ocupa toda a largura disponível e começa numa linha nova. `<p>`, `<h1>`, `<div>`, `<article>`, `<ul>` são block.
- **`inline`**: a caixa corre dentro de uma linha de texto, da largura do conteúdo. `<a>`, `<span>`, `<em>`, `<strong>`, `<img>` são inline.

Aqui está um `<span>` com largura, altura, padding e margens, três vezes: como vem, como `inline-block` e como `block`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Display · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .tag {
        width: 200px;
        height: 60px;
        padding: 4px 8px;
        margin: 20px;
        background: #f4f1ea;
      }
      .as-block { display: block; }
      .as-inline-block { display: inline-block; }
    </style>
  </head>
  <body>
    <p>A <span class="tag">poetry</span> event.</p>
    <p>A <span class="tag as-inline-block">poetry</span> event.</p>
    <p>A <span class="tag as-block">poetry</span> event.</p>
  </body>
</html>
```

```
ana@laptop:~/site$ probe display.html style .tag display box .tag
span.tag  display: inline
span.tag.as-inline-block  display: inline-block
span.tag.as-block  display: block
span.tag                  x 34.23  y 15     width 60.47  height 25
span.tag.as-inline-block  x 34.23  y 76     width 216    height 68
span.tag.as-block         x 20     y 224    width 216    height 68
```

**O span inline ignorou a largura e a altura.** Ele tem 60,47 pixels de largura, a largura da palavra *poetry* mais 16 pixels de padding, e 25 de altura, o texto da linha mais 8 pixels de padding. As margens verticais também não fizeram nada: o padding vertical de uma caixa inline é desenhado, e não empurra nada acima ou abaixo para fora do caminho.

**`inline-block` obedece a tudo e continua na linha**: 216 por 68, que é 200 mais 16 de padding e 60 mais 8, com as palavras *A* e *event.* uma de cada lado. É assim que um link com cara de botão fica numa frase.

**`block` obedece e sai da linha**: os mesmos 216 por 68, mas agora numa linha própria, 20 pixels para dentro a partir da esquerda, porque as margens valem em todos os lados.

## O vão embaixo de uma imagem

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Cover · Andorinha Books</title>
    <style>
      .frame { border: 1px solid #2f6f4e; width: 120px; }
      .fixed img { display: block; }
    </style>
  </head>
  <body>
    <div class="frame"><img src="cover.png" alt="" width="120" height="80"></div>
    <div class="frame fixed"><img src="cover.png" alt="" width="120" height="80"></div>
  </body>
</html>
```

Salve-a como `gap.html`, com qualquer imagem pequena ao lado como `cover.png`; os atributos fixam o tamanho dela.

```
ana@laptop:~/site$ probe gap.html box .frame
div.frame        x 8      y 8      width 122    height 86
div.frame.fixed  x 8      y 94     width 122    height 82
```

A primeira moldura tem 86 pixels de altura para uma imagem de 80 e 2 pixels de borda, então sobram 4 pixels: o espaço abaixo da linha de base que a aula 1 encontrou no modo padrão. A segunda moldura diz `img { display: block; }`, a imagem não está mais numa linha de texto, e a moldura tem 82, exatamente imagem mais borda. `vertical-align: bottom` na imagem também o remove, tirando a imagem da linha de base. Qualquer um dos dois costuma ser a primeira linha do tratamento de imagens numa folha de estilos.

As aulas 8 e 9 acrescentam mais dois valores, `flex` e `grid`, que mudam como um elemento monta os **filhos**. Tudo nesta aula é sobre a própria caixa.
