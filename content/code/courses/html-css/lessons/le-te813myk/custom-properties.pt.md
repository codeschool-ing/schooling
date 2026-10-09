---
title: Propriedades personalizadas: um valor com nome
version: 2
---

Uma **propriedade personalizada** (*custom property*) é uma propriedade cujo nome você escolhe, começando com dois hifens, e cujo valor você usa em outro lugar com **`var()`**. Muita gente as chama de **variáveis CSS**, e o nome é justo, com uma diferença em relação às variáveis de uma linguagem de programação que é o assunto das próximas seções. Aqui está a página de eventos da livraria, com as cores e o espaçamento declarados uma vez, em `tokens.css`:

```css
:root {
  --green: #2f6f4e;
  --red: #8a1c1c;
  --paper: #fbf8f2;
  --ink: #1d1d1b;

  --accent: var(--green);
  --space: 1rem;
}

body {
  background: var(--paper);
  color: var(--ink);
}

.event {
  padding: var(--space);
  border-left: 4px solid var(--accent);
}
.event h2 { color: var(--accent); }

.cancelled { --accent: var(--red); }
```

As declarações ficam em **`:root`**, uma pseudo-classe que casa com o elemento `<html>`, para que todo elemento da página possa usá-las. `--green` e `--red` são as cores cruas. `--accent` é o papel, "a cor que marca um evento", e o valor dele é outra variável. Depois as regras usam os nomes: a borda dos eventos e os títulos deles pegam `var(--accent)`, o padding pega `var(--space)`.

A página é o `events.html`, dois eventos e um link para essa folha de estilos:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Events · Andorinha Books</title>
    <link rel="stylesheet" href="tokens.css">
  </head>
  <body>
    <main>
      <h1>Events</h1>
      <article class="event">
        <h2>Poetry reading</h2>
        <p>Thursday 8 October, 7 pm.</p>
      </article>
      <article class="event cancelled">
        <h2>Bookbinding class</h2>
        <p>Cancelled: the teacher is ill.</p>
      </article>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe events.html style :root --accent,--space style '.event h2' color style .event padding-left
html  --accent: #2f6f4e
html  --space: 1rem
h2  color: rgb(47, 111, 78)
h2  color: rgb(138, 28, 28)
article.event  padding-left: 16px
article.event.cancelled  padding-left: 16px
```

A raiz tem os valores, com `--accent` já resolvido para `#2f6f4e`. O primeiro título é verde, `rgb(47, 111, 78)`, e o padding é **16px**, `1rem`. O segundo título é **vermelho**, `rgb(138, 28, 28)`, e nenhuma regra da folha de estilos diz que um título é vermelho: ele lê `var(--accent)` como o primeiro. A próxima seção explica por quê.

## O que uma propriedade personalizada não é

**Não é uma propriedade que faz algo sozinha.** `--accent: green` num elemento não muda nada na aparência dele; só guarda um valor para o `var()` ler. O navegador não sabe o que `--accent` quer dizer e nunca vai saber.

**Não é conferida quando é declarada.** Qualquer coisa pode ser guardada, `--accent: banana` inclusive, e o navegador só descobre se o valor faz sentido onde ele é usado. A seção 05 é o que acontece quando não faz.

Propriedades personalizadas diferenciam maiúsculas de minúsculas, ao contrário do resto do CSS: `--Accent` e `--accent` são duas variáveis diferentes.
