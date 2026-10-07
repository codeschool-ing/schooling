---
title: Alinhando dentro das células
version: 1
---

Itens grid são postos em células, e um item menor que a célula pode ficar em qualquer lugar dentro dela. O Grid usa as propriedades de alinhamento do Flexbox e acrescenta a que o Flexbox não tem:

| propriedade | em | alinha | eixo |
| --- | --- | --- | --- |
| `justify-items` | contêiner | cada item na sua célula | inline, horizontal |
| `align-items` | contêiner | cada item na sua célula | bloco, vertical |
| `justify-self` | item | aquele item | horizontal |
| `align-self` | item | aquele item | vertical |
| `justify-content` | contêiner | o grid inteiro no contêiner | horizontal |
| `align-content` | contêiner | o grid inteiro no contêiner | vertical |

O padrão para os itens é `stretch`: um item preenche a célula, e é por isso que itens grid têm a largura e a altura das trilhas sem pedir. Aqui estão rótulos em células de 200 de largura e 120 de altura, com `justify-items: center` e `align-items: end`, e um rótulo que sobrescreve os dois:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Alignment · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .labels {
        display: grid;
        grid-template-columns: repeat(3, 200px);
        grid-auto-rows: 120px;
        gap: 10px;
        justify-items: center;
        align-items: end;
        background: #f4f1ea;
      }
      .labels span { padding: 4px 8px; background: #2f6f4e; color: white; }
      .labels .full { justify-self: stretch; align-self: start; }
      .centred { display: grid; place-items: center; height: 200px; background: #f4f1ea; }
    </style>
  </head>
  <body>
    <div class="labels">
      <span>Poetry</span>
      <span>Fiction</span>
      <span class="full">Children</span>
    </div>
    <div class="centred"><p>Nothing in your basket yet.</p></div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe align.html box '.labels span' box '.centred p'
span       x 68.88  y 88     width 62.25  height 32
span       x 278.44 y 88     width 63.13  height 32
span.full  x 420    y 0      width 200    height 32
p  x 417.28 y 208    width 189.44 height 24
```

*Poetry* e *Fiction* estão cada um centralizados na sua célula de 200 pixels, em x 68,88 e 278,44, e ficam embaixo: y **88**, que é 120 menos a altura deles, 32. *Children* tem `justify-self: stretch` e `align-self: start`: preenche a largura da célula, **200**, e fica em cima, y 0.

## `place-items: center`

`place-items` é a abreviação de `align-items` e `justify-items` juntos, e **`place-items: center` num contêiner grid centraliza o conteúdo nas duas direções**: a mensagem de cesta vazia da aula 8, aqui com uma declaração em vez de duas. O parágrafo está em y **208**: a caixa dele fica 88 pixels para dentro do contêiner de 200, que começa em 120. É hoje o jeito mais curto de centralizar qualquer coisa em CSS.

`justify-content` e `align-content` só importam quando as trilhas somam menos que o contêiner, por exemplo colunas de largura fixa numa página mais larga; aí elas posicionam o grid inteiro, `center` ou `space-between`, exatamente como no Flexbox.
