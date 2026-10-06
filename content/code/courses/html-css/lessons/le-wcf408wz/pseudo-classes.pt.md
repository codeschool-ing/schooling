---
title: Estados e posições: pseudo-classes
version: 1
---

Uma **pseudo-classe** seleciona elementos por algo que não está escrito no HTML: um estado em que estão, como estar sob o mouse ou com foco, ou a posição entre os irmãos. Ela se escreve com um dois-pontos: `a:hover`. Aqui estão as que mais trabalham, em `states.css`:

```css
.event:nth-child(odd) { background: #f4f1ea; }
.event:not(.cancelled) h2 { color: #2f6f4e; }
.event:has(.note) { border-left: 4px solid #7a5c00; }
.more:hover { text-decoration: none; }
.more:focus-visible { outline: 3px solid #7a5c00; }
```

## Posição: `:nth-child()`

```
ana@laptop:~/site$ probe states.html style .event background-color
article.event  background-color: rgb(244, 241, 234)
article.event.featured  background-color: rgba(0, 0, 0, 0)
article.event.cancelled  background-color: rgb(244, 241, 234)
ana@laptop:~/site$ probe states.html style '.event h2' color style .event border-left-width
h2  color: rgb(47, 111, 78)
h2  color: rgb(47, 111, 78)
h2  color: rgb(0, 0, 0)
article.event  border-left-width: 4px
article.event.featured  border-left-width: 0px
article.event.cancelled  border-left-width: 0px
```

`.event:nth-child(odd)` deu fundo ao **primeiro e ao terceiro** articles, e o motivo merece cuidado. `:nth-child()` conta **todos** os irmãos do elemento, não só os que têm a classe. Dentro do `<main>`, o `<h1>` é o filho 1 e o parágrafo de introdução o filho 2, então os articles são os filhos 3, 4 e 5, e os ímpares são o 3 e o 5. O seletor se lê como "um elemento que é um filho de número ímpar, e também tem a classe `event`". Quando você quer dizer "um evento sim, outro não", ponha os eventos num contêiner próprio, que é para isso que serve uma lista ou uma `<div>` de cartões.

## Lógica: `:not()`, `:is()`, `:has()`

`.event:not(.cancelled) h2` coloriu os títulos dos dois eventos que não estão cancelados, e deixou o terceiro no preto padrão. `:not()` recebe um seletor e casa com o que ele não casa. `:is(h1, h2, h3)` casa com qualquer um de uma lista, e mantém seletores longos curtos. E **`:has()`** casa com um elemento pelo que ele contém: `.event:has(.note)` deu borda só ao article com uma nota dentro. Por vinte anos o CSS não conseguia selecionar um pai pelos filhos, e `:has()` é a resposta, disponível em todos os navegadores principais desde o fim de 2023.

## Estado: `:hover`, `:focus-visible`, `:user-invalid`

```
ana@laptop:~/site$ probe states.html style .more text-decoration-line hover .more style .more text-decoration-line
a.more  text-decoration-line: underline
a.more  text-decoration-line: none
```

Sob o ponteiro, o link perdeu o sublinhado. Agora o teclado:

```
ana@laptop:~/site$ probe states.html tab style .more outline-style,outline-width
focus: a "How the swap works"
a.more  outline-style: solid
a.more  outline-width: 3px
```

**`:focus-visible` casou quando o link foi alcançado com Tab**, e desenhou um contorno de 3 pixels. Ele casa quando o navegador julga que um anel de foco é necessário, o que quer dizer foco pelo teclado e não um clique do mouse, e é por isso que é o que se deve usar. **Nunca tire o contorno de foco sem pôr outro no lugar**: `outline: none` sozinho torna uma página inutilizável pelo teclado, porque ninguém consegue ver onde está.

A seção 08 da aula 3 disse que o CSS consegue marcar um campo que o navegador considera inválido. Há duas pseudo-classes para isso, e a diferença é o ponto inteiro:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Newsletter · Andorinha Books</title>
    <style>
      input { border: 2px solid #767676; }
      input:invalid { background: #fff4f4; }
      input:user-invalid { border-color: #8a1c1c; }
    </style>
  </head>
  <body>
    <main>
      <h1>Newsletter</h1>
      <form action="subscribe">
        <label for="email">Email</label>
        <input id="email" name="email" type="email" required>
        <button>Subscribe</button>
      </form>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe signup.html style input border-top-color,background-color fill input ana@ press Tab style input border-top-color,background-color
input#email  border-top-color: rgb(118, 118, 118)
input#email  background-color: rgb(255, 244, 244)
input#email  border-top-color: rgb(138, 28, 28)
input#email  background-color: rgb(255, 244, 244)
```

Antes de qualquer pessoa digitar, o campo obrigatório vazio já casava com **`:invalid`**, e estava rosa. É um formulário que recebe o leitor com um erro. **`:user-invalid`** só casou depois que Ana digitou `ana@` e seguiu em frente, e só então a borda ficou vermelha. Estilize erros com `:user-invalid`, e mantenha a mensagem em palavras ao lado do campo.
