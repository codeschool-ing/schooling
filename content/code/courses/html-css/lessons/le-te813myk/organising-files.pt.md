---
title: Organizando a folha de estilos
version: 2
---

Uma folha de estilos que cresce sem plano acaba com o mesmo botão estilizado em quatro lugares e ninguém sabendo qual vence. A saída é uma **ordem**, escolhida uma vez, em que o geral vem antes do específico. Uma ordem comum tem seis partes, e a pasta `css/` desta aula, dentro de `site`, a segue:

```
ana@laptop:~/site$ find css -type f | sort
css/base.css
css/components/event-card.css
css/layout.css
css/main.css
css/reset.css
css/tokens.css
css/utilities.css
```

1. **`reset.css`**: as poucas regras que desfazem padrões do navegador que ninguém quer: `box-sizing: border-box` para tudo, aula 6, nenhuma margem no body, imagens como blocos.
2. **`tokens.css`**: as propriedades personalizadas da seção 08, e nada mais.
3. **`base.css`**: a aparência padrão dos elementos simples, só por seletor de tipo: a fonte e a cor do body, links, títulos, listas. Nenhuma classe.
4. **`layout.css`**: as formas grandes, o grid da página e os contêineres que seguram as coisas, aulas 8 e 9.
5. **`components/`**: um arquivo por componente, cada um estilizando só os próprios nomes de classe: o cartão de evento, o menu, o formulário de pedido.
6. **`utilities.css`**: classes pequenas, de um propósito só, que precisam vencer onde quer que sejam postas, como a classe `visually-hidden` da aula 7.

A ordem é também a de **especificidade crescente e alcance crescente**: seletores de elemento, depois algumas classes de layout, depois classes de componente, depois utilitários que sobrepõem. Escrita nessa ordem, a cascata quase sempre funciona sem ninguém brigar com ela, e a seção 10 transforma essa ordem numa regra que o navegador impõe.

Todos são curtos. Aqui estão eles, para salvar com esses nomes:

`css/reset.css`:

```css
*, *::before, *::after { box-sizing: border-box; }
body { margin: 0; }
img { display: block; max-width: 100%; }
```

`css/tokens.css`:

```css
:root {
  --color-text: #1d1d1b;
  --color-accent: #2f6f4e;
  --space: 0.5rem;
}
```

`css/base.css`:

```css
body { color: var(--color-text); font: 1rem/1.5 system-ui, sans-serif; }
a { color: var(--color-accent); }
```

`css/layout.css`:

```css
.page { display: grid; gap: calc(var(--space) * 4); }
```

`css/components/event-card.css`:

```css
.event-card { padding: calc(var(--space) * 2); border-left: 4px solid var(--color-accent); }
.event-card__title { margin: 0; font-size: 1.1rem; }
.event-card--cancelled { --color-accent: #8a1c1c; }
```

`css/utilities.css`:

```css
.visually-hidden {
  position: absolute !important;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
```

`css/main.css`:

```css
@layer reset, tokens, base, layout, components, utilities;

@import url("reset.css") layer(reset);
@import url("tokens.css") layer(tokens);
@import url("base.css") layer(base);
@import url("layout.css") layer(layout);
@import url("components/event-card.css") layer(components);
@import url("utilities.css") layer(utilities);
```

## Um arquivo ou vários

O `main.css` traz os outros com **`@import`**, e isso tem um custo que o navegador mostra. A página que os usa, `site.html`, liga o `main.css` e mais nada:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Events · Andorinha Books</title>
    <link rel="stylesheet" href="css/main.css">
  </head>
  <body>
    <main class="page">
      <article class="event-card event-card--cancelled">
        <h2 class="event-card__title">Bookbinding class</h2>
        <p>Cancelled: the teacher is ill.</p>
      </article>
    </main>
  </body>
</html>
```

Aberta, ela pede estes arquivos:

```
ana@laptop:~/site$ probe site.html fetched
main.css
reset.css
tokens.css
base.css
layout.css
event-card.css
utilities.css
```

Isso é o que a página pediu, em ordem: `main.css` primeiro, depois os seis arquivos que ele importa. O navegador não tem como saber de `reset.css` antes de baixar e ler o `main.css`, então os imports são descobertos com uma ida e volta de atraso, e nada é desenhado até que todos tenham chegado, seção 12 da aula 1. Num site servido pela rede, esse atraso é real. Então **os arquivos são para quem trabalha no CSS, e o navegador deve receber um arquivo só**: em desenvolvimento o `@import` é prático, e para produção uma etapa de build junta tudo numa folha de estilos. O `front-delivery` é onde esse build é montado. Para um site pequeno com uma folha de estilos, as partes são simplesmente seções de um arquivo, na mesma ordem.
