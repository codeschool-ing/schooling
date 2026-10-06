---
title: A página inicial do sebo em Grid
version: 1
---

Tudo desta aula numa página: a moldura da seção 06, com um aside no lugar da coluna de navegação, e os eventos da seção 04 como um grid `auto-fit` dentro do `main`. Grid por fora, Grid por dentro, e nada posicionado.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="home.css">
  </head>
  <body>
    <header class="site-header"><p>Andorinha Books</p></header>
    <main>
      <h1>This week</h1>
      <div class="cards">
        <article><h2>Poetry reading</h2><p>Thursday, 7 pm.</p></article>
        <article><h2>Book swap</h2><p>Saturday, from 10 am.</p></article>
        <article><h2>Bookbinding</h2><p>Saturday, 2 pm.</p></article>
        <article><h2>New arrivals</h2><p>Forty paperbacks.</p></article>
      </div>
    </main>
    <aside><h2>Opening hours</h2><p>10 am to 7 pm.</p></aside>
    <footer><p>Rua dos Pinheiros, 1000 · São Paulo</p></footer>
  </body>
</html>
```

```css
*, *::before, *::after { box-sizing: border-box; }

body {
  margin: 0;
  display: grid;
  grid-template-columns: 1fr 240px;
  grid-template-areas:
    "header header"
    "main   aside"
    "footer footer";
  gap: 24px;
  max-width: 1100px;
  padding: 0 16px;
  margin-inline: auto;
}
.site-header { grid-area: header; }
main         { grid-area: main; }
aside        { grid-area: aside; }
footer       { grid-area: footer; }

.cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
}
.cards article { padding: 16px; background: #f4f1ea; }
```

```
ana@laptop:~/site$ probe home.html box main box aside style .cards grid-template-columns
main  x 16     y 74     width 728    height 361.5
aside  x 768    y 74     width 240    height 361.5
div.cards  grid-template-columns: 232px 232px 232px
ana@laptop:~/site$ probe --width 700 home.html box main box aside style .cards grid-template-columns
main  x 16     y 74     width 404    height 659.13
aside  x 444    y 74     width 240    height 659.13
div.cards  grid-template-columns: 404px
```

Na janela de 1024, o `main` tem **728** de largura e o aside **240**: o `1fr` e a coluna fixa, dentro de um body limitado a 1100 e com 16 de padding de cada lado. Os cartões de evento criaram três colunas de **232**, então o quarto cartão quebra para uma segunda linha. É o `auto-fit` trabalhando: três trilhas de pelo menos 220 cabem em 728, quatro não.

Numa janela de 700 de largura, o `main` encolhe para **404**, e os cartões criaram **uma coluna**, de 404. O aside continua com **240** ao lado, ocupando mais de um terço de uma tela pequena para uma caixa de horários. Nada nesta folha de estilos sabe que uma janela estreita quer outra forma de página: os cartões se adaptaram sozinhos, a moldura não. Mudar a moldura numa largura é o que uma **media query** faz, e isso, e a decisão de em que largura fazer, é a aula 11.

## O que a página não usa

Nada de floats, nada de posicionamento absoluto, nenhuma porcentagem, e nenhuma largura fixa a não ser a coluna do aside e o máximo da página. `margin-inline: auto` centraliza o body em janelas largas, a grafia em propriedade lógica do `margin: 0 auto` da aula 6: `inline` quer dizer a direção em que o texto corre. O layout são dois grids e um `gap`, e ele se lê como um desenho no template.
