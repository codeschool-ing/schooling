---
title: Links levam a algum lugar, botões fazem algo
version: 1
---

Dois elementos tornam uma página interativa sem uma linha de CSS: `<a href>` e `<button>`. Eles aparecem diferentes por padrão e as pessoas os estilizam para ficarem parecidos, então a diferença se perde fácil. Ela é simples de dizer: **um link leva você a outro lugar, um botão faz algo aqui**. Ir para a página de eventos é um link. Reservar um livro, abrir um menu, enviar um formulário são botões.

A escolha importa porque cada elemento vem com um comportamento que você teria de construir. Aqui está uma página com três controles: uma `<div>` estilizada para parecer botão, um `<button>` de verdade e um link. Os dois "botões" chamam a mesma função, que escreve *Reserved.* na página.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Reserve · Andorinha Books</title>
    <link rel="stylesheet" href="controls.css">
  </head>
  <body>
    <main>
      <h1>Grande Sertão: Veredas</h1>
      <div class="button" onclick="reserve()">Reserve (div)</div>
      <button type="button" onclick="reserve()">Reserve (button)</button>
      <a href="shelf.html">Back to the shelf</a>
      <p id="status"></p>
    </main>
    <script>
      function reserve() {
        document.getElementById('status').textContent = 'Reserved.';
      }
    </script>
  </body>
</html>
```

Clicados com o mouse, os dois botões se comportam igual. A árvore de acessibilidade é o primeiro sinal de que não são iguais:

```
ana@laptop:~/site$ probe controls.html tree
- main:
  - 'heading "Grande Sertão: Veredas" [level=1]'
  - text: Reserve (div)
  - button "Reserve (button)"
  - link "Back to the shelf":
    - /url: shelf.html
  - paragraph
```

O `<button>` é um **button** chamado *Reserve (button)*. A `<div>` é **text**: quem usa leitor de tela ouve as palavras e não tem ideia de que algo acontece se ativá-las. Depois vem o teclado, que é como pessoas que não podem usar mouse, e muitas que só preferem não usar, andam por uma página. Tab move o foco de um controle para o próximo, e Enter ativa o que está com ele:

```
ana@laptop:~/site$ probe controls.html tab press Enter text "#status" tab tab
focus: button "Reserve (button)"
p#status  "Reserved."
focus: a "Back to the shelf"
focus: body (nothing left to focus)
```

O primeiro Tab foi para o `<button>`, e o Enter reservou o livro. O seguinte foi para o link. O seguinte caiu do fim da página, e **a `<div>` nunca foi alcançada**. Para quem usa teclado, o primeiro controle da página não existe.

## O que um `<button>` traz e uma `<div>` não

Para a `<div>` se comportar como botão você precisaria de: `role="button"` para a árvore dizer o que ela é, `tabindex="0"` para ela poder receber foco, um tratamento de tecla para Enter *e* para Espaço, porque botões respondem aos dois, um estilo de foco visível e um estado desabilitado quando for preciso. São cinco coisas a lembrar e acertar em cada uma delas. `<button>` já tem todas, e corretas em todo navegador.

O mesmo vale para links: `<a href>` recebe foco, abre com Enter, mostra o endereço ao passar o mouse, pode ser aberto numa nova aba e é anunciado como link. Um `<span>` com um tratamento de clique que muda a página não faz nada disso, e um `<a>` sem `href` também não recebe foco.

**Um `<button>` dentro de um formulário envia o formulário por padrão.** A aula 3 é sobre formulários, e a seção 06 de lá trata exatamente disso; para um botão que faz outra coisa que não enviar, escreva `type="button"`, como a página acima faz.
