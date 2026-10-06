---
title: calc() e uma escala de tamanhos
version: 1
---

**`calc()`** faz contas com valores CSS, e pode misturar unidades que o navegador só resolve durante o layout: `calc(100% - 15rem)` é "a largura do contêiner menos quinze root ems", o que nenhuma unidade sozinha consegue dizer. Com variáveis, o `calc()` transforma um valor numa **escala**:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>A scale · Andorinha Books</title>
    <style>
      :root {
        --space: 0.5rem;
        --space-2: calc(var(--space) * 2);
        --space-4: calc(var(--space) * 4);
        --sidebar: 15rem;
      }
      .card { padding: var(--space-2); margin-bottom: var(--space-4); }
      .main { width: calc(100% - var(--sidebar) - var(--space-4)); }
    </style>
  </head>
  <body>
    <article class="card">One card</article>
    <div class="main">The main column</div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe scale.html style :root --space-2,--space-4 style .card padding-top,margin-bottom box .main
html  --space-2: calc(0.5rem * 2)
html  --space-4: calc(0.5rem * 4)
article.card  padding-top: 16px
article.card  margin-bottom: 32px
div.main  x 8      y 90     width 736    height 18
```

Duas coisas nessa saída merecem leitura. O padding do cartão é **16px** e a margem dele **32px**: `--space` é meio rem, e a escala o dobra e o quadruplica. Mude `--space` e todo tamanho da escala se move junto, na proporção.

**As propriedades personalizadas foram guardadas sem avaliar**: `--space-2` é `calc(0.5rem * 2)`, não `1rem` e não `16px`. É o comportamento da seção 05, visto do outro lado. Uma propriedade personalizada guarda o texto que recebeu, com qualquer `var()` dentro dele substituído, e a conta só acontece onde ele é finalmente usado, em `padding`, onde o navegador sabe que é um comprimento. Isso também quer dizer que uma variável definida com `em` é resolvida contra o tamanho de fonte do elemento que a **usa**, não do que a declarou.

A largura da coluna principal é `calc(100% - var(--sidebar) - var(--space-4))`, e deu **736**: 1008 menos 240 menos 32. Um `calc()` assim é como se faziam layouts antes do Grid; com o Grid, aula 9, `1fr` faz isso sem conta, e o `calc()` continua útil para tudo o que não é uma trilha de layout.

## Os operadores

`+` e `-` precisam de espaço dos dois lados: `calc(100% -1rem)` é inválido, porque `-1rem` se lê como um número negativo. `*` e `/` não precisam, e um dos lados de cada um tem de ser um número puro. `min()`, `max()` e `clamp()` são parentes do calc: escolhem o menor, o maior, ou um valor entre dois limites, e a aula 11 monta tipografia fluida com `clamp()`.
