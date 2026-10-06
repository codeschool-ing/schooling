---
title: Um contêiner flex e os seus dois eixos
version: 1
---

**Flexbox é um jeito de montar os filhos de um elemento numa linha.** Escreva `display: flex` num contêiner, e os filhos diretos dele viram **itens flex**, postos um depois do outro ao longo de uma linha em vez de empilhados como blocos. Aqui está uma prateleira de três livros, uma vez como linha e outra como coluna:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Axes · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .shelf { display: flex; width: 600px; background: #f4f1ea; }
      .column { flex-direction: column; }
      .book { padding: 8px; background: #2f6f4e; color: white; }
    </style>
  </head>
  <body>
    <div class="shelf row">
      <div class="book">Vidas Secas</div>
      <div class="book">Macunaíma</div>
      <div class="book">Grande Sertão: Veredas</div>
    </div>
    <div class="shelf column">
      <div class="book">Vidas Secas</div>
      <div class="book">Macunaíma</div>
      <div class="book">Grande Sertão: Veredas</div>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe axes.html box '.row .book' box '.column .book'
div.book  x 0      y 0      width 104.66 height 40
div.book  x 104.66 y 0      width 99.59  height 40
div.book  x 204.25 y 0      width 188.56 height 40
div.book  x 0      y 40     width 600    height 40
div.book  x 0      y 80     width 600    height 40
div.book  x 0      y 120    width 600    height 40
```

Na linha, os três livros ficam lado a lado começando em x 0, e **cada um tem a largura do próprio conteúdo**: 104,66, 99,59 e 188,56, os títulos mais o padding. A prateleira tem 600 de largura e os livros usam 393 dela; o resto sobra, e é disso que trata a maior parte desta aula. Na coluna, os mesmos livros se empilham, e **cada um tem 600 de largura**, a largura inteira da prateleira.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 222\" role=\"img\" aria-label=\"Dois contêineres flex. Com flex-direction row, três itens A, B e C ficam lado a lado, cada um da largura do conteúdo; o eixo principal vai da esquerda para a direita e o cruzado de cima para baixo. Com flex-direction column, os mesmos itens se empilham; o eixo principal vai de cima para baixo, o cruzado da esquerda para a direita, e os itens se esticam nele até a largura inteira.\"><defs><marker id=\"ah8\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ah8b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">flex-direction: row</text><rect x=\"20\" y=\"30\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"30\" y=\"40\" width=\"70\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"65\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">A</text><rect x=\"106\" y=\"40\" width=\"66\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"139\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">B</text><rect x=\"178\" y=\"40\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"238\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">C</text><line x1=\"20\" y1=\"116\" x2=\"316\" y2=\"116\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#ah8)\"></line><text x=\"20\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">eixo principal: os itens se alinham ao longo dele</text><line x1=\"336\" y1=\"30\" x2=\"336\" y2=\"98\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#ah8b)\"></line><text x=\"348\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cruzado</text><text x=\"420\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">flex-direction: column</text><rect x=\"420\" y=\"30\" width=\"200\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"430\" y=\"40\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">A</text><rect x=\"430\" y=\"86\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">B</text><rect x=\"430\" y=\"132\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">C</text><line x1=\"640\" y1=\"30\" x2=\"640\" y2=\"178\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#ah8)\"></line><text x=\"652\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">principal</text><line x1=\"420\" y1=\"196\" x2=\"618\" y2=\"196\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#ah8b)\"></line><text x=\"420\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">eixo cruzado: os itens se esticam nele</text></svg>", "caption": "justify-content trabalha ao longo do eixo principal e align-items através dele, seja para onde for o eixo principal."}
```

Essa diferença é o modelo inteiro. Um contêiner flex tem dois eixos. **O eixo principal é a direção em que os itens são postos**, definida por `flex-direction`: `row`, o padrão, vai da esquerda para a direita, e `column` de cima para baixo. **O eixo cruzado corre através dele.** Duas propriedades fazem então quase todo o trabalho, e é fácil distingui-las quando os eixos estão firmes na cabeça:

- **`justify-content`** posiciona os itens **ao longo do eixo principal**: juntos no começo, no meio, espalhados. Seção 04.
- **`align-items`** os posiciona **através**, no eixo cruzado: em cima, no meio ou esticados para preencher. Seção 05.

Os livros da coluna tinham 600 de largura porque o valor padrão de `align-items` é `stretch`: no eixo cruzado, os itens se esticam para preencher o contêiner. Numa linha, o eixo cruzado é vertical, então o mesmo padrão faz todo item ter a altura da linha, e é por isso que colunas flex saem com alturas iguais sem ninguém pedir.

## Só os filhos

`display: flex` afeta **só os filhos diretos** do contêiner. Um parágrafo dentro de um livro é montado do jeito comum dentro do livro; para montar o conteúdo do livro numa linha também, o livro vira um contêiner flex. Aninhar contêineres flex é normal, e uma página costuma ter vários.

O próprio contêiner continua se comportando como um bloco para os vizinhos: ocupa a largura inteira e começa numa linha nova. `display: inline-flex` o faz ficar dentro de uma linha de texto, como o `inline-block` da aula 6.

`row-reverse` e `column-reverse` também existem, e põem os itens a partir da outra ponta. A seção 10 trata de por que inverter a ordem visual é mais perigoso do que parece.
