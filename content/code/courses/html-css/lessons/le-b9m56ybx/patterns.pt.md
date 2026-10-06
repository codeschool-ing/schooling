---
title: Padrões: um menu, uma fileira dividida, uma mensagem centralizada e um rodapé no fundo
version: 1
---

Quatro layouts pequenos formam a maior parte do que o Flexbox faz num site de verdade. Aqui estão eles numa página:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="patterns.css">
  </head>
  <body>
    <header>
      <p class="logo">Andorinha Books</p>
      <nav aria-label="Main">
        <ul>
          <li><a href="events.html">Events</a></li>
          <li><a href="order.html">Order a book</a></li>
          <li class="account"><a href="account.html">Your account</a></li>
        </ul>
      </nav>
    </header>
    <main>
      <article class="review">
        <img src="cover.png" alt="" width="60" height="90">
        <div>
          <h2>Vidas Secas</h2>
          <p>Graciliano Ramos, 1938. Reviewed by Ana.</p>
        </div>
      </article>
      <div class="empty">
        <p>Nothing in your basket yet.</p>
      </div>
    </main>
    <footer>Rua dos Pinheiros, 1000 · São Paulo</footer>
  </body>
</html>
```

```css
body {
  margin: 0;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}
main { flex: 1; }

nav ul {
  display: flex;
  gap: 16px;
  list-style: none;
  margin: 0;
  padding: 0;
}
nav .account { margin-left: auto; }

.review { display: flex; gap: 16px; align-items: flex-start; }
.review h2 { margin-top: 0; }

.empty {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 200px;
  background: #f4f1ea;
}
```

```
ana@laptop:~/site$ probe patterns.html box 'nav li' box '.review img' box '.review h2'
li          x 0      y 50     width 43.55  height 18
li          x 59.55  y 50     width 84.42  height 18
li.account  x 938.97 y 50     width 85.03  height 18
img  x 0      y 68     width 60     height 90
h2  x 76     y 68     width 281.72 height 27
ana@laptop:~/site$ probe patterns.html box .empty box ".empty p" box main box footer
div.empty  x 0      y 158    width 1024   height 200
p  x 424.67 y 249    width 174.64 height 18
main  x 0      y 68     width 1024   height 682
footer  x 0      y 750    width 1024   height 18
```

## Um menu numa linha, com um item empurrado para o fim

A aula 2 prometeu que a lista de links do menu seria posta numa linha. `display: flex` no `<ul>` faz isso, `gap: 16px` espaça os itens, e a lista continua sendo uma lista no HTML. O link da conta está na extrema direita, **x 938,97**, por causa de uma declaração: **`margin-left: auto`**. Num contêiner flex, uma margem `auto` pega todo o espaço livre daquele lado, o que empurra o item, e tudo depois dele, para o fim. A aula 6 disse que uma margem `auto` vertical não fazia nada no fluxo normal e que esta aula mostraria onde ela faz mais: no Flexbox, margens auto funcionam nos dois eixos, e são como se afasta um item do grupo.

## Uma imagem ao lado do texto

A resenha é o **media object**: uma imagem e um bloco de texto lado a lado, o texto ocupando o resto da largura. `display: flex` com `gap: 16px` põe o título em **x 76**, a capa de 60 pixels mais o vão. `align-items: flex-start` impede o `stretch` padrão de esticar a imagem até a altura do texto.

## Centralizado nas duas direções

A mensagem de cesta vazia é centralizada com `justify-content: center` e `align-items: center` numa caixa de 200 de altura. O parágrafo está em x 424,67, que é (1024 − 174,64) / 2, e na vertical no meio da caixa. Duas declarações, e a mensagem continua centralizada seja qual for o comprimento dela ou a largura da janela.

## Um rodapé que fica no fundo

Numa página com pouco conteúdo, o rodapé normalmente ficaria logo abaixo dele, no meio da janela. Aqui o body é uma **coluna** flex pelo menos da altura da janela, `min-height: 100vh`, e o `main` tem `flex: 1`, então ele pega toda a altura livre: **o main tem 682 de altura e o rodapé começa em 750**, no fundo da janela de 768. Numa página longa, o `main` tem só a altura do conteúdo e o rodapé vem depois dele.
