---
title: Padding que aumenta um alvo
version: 2
---

A aula 2 deixou uma regra do axe falhando na página inicial semântica: **target-size**. Cada link do menu tinha 17 pixels de altura, com o seguinte 18 pixels abaixo, e a WCAG 2.2 pede alvos de 24 por 24 pixels, ou espaço suficiente em volta de um menor. Aquela aula disse que a correção era padding. Aqui está ela, em `menu.css`, referenciado pela mesma página. O `menu.html` é o `semantic.html` da aula 2 com uma linha a mais depois do título, `<link rel="stylesheet" href="menu.css">`:

```css
nav ul { list-style: none; padding: 0; }
nav a {
  display: block;
  padding: 12px 0;
}
```

```
ana@laptop:~/site$ probe menu.html axe box 'nav a' tree nav
axe: no violations
a  x 8      y 50     width 1008   height 42
a  x 8      y 92     width 1008   height 42
a  x 8      y 134    width 1008   height 42
- navigation "Main":
  - list:
    - listitem:
      - link "Events":
        - /url: events.html
    - listitem:
      - link "Order a book":
        - /url: order.html
    - listitem:
      - link "Opening hours":
        - /url: hours.html
```

**Nenhuma violação.** Cada link agora tem 42 pixels de altura: os 18 pixels da sua linha de texto mais 12 pixels de padding em cima e embaixo. Duas declarações fizeram isso. `padding: 12px 0` aumentou a caixa, e o padding faz parte do link, então um toque em qualquer ponto dele é um toque no link. `display: block` foi necessário antes, porque a seção 03 mostrou que o padding vertical de uma caixa inline é desenhado e não empurra nada: os links teriam sobreposto o padding uns dos outros. Como blocos, eles também se esticam pela largura inteira do menu, o que torna o alvo largo além de alto.

`list-style: none` e `padding: 0` no `<ul>` tiram os marcadores e o recuo que as listas têm por padrão, a linha que a aula 2 prometeu e mais uma. A árvore depois das caixas mostra que o Chromium continua informando uma lista de três itens. O Safari é conhecido por tirar o papel de lista quando os marcadores somem, e `role="list"` no `<ul>` é o jeito usual de mantê-lo.

## Por que padding e não margem

Margem teria espaçado os links do mesmo tanto, e o espaço seria morto: um toque entre dois links não acertaria nenhum. **Padding torna a coisa maior; margem afasta as coisas.** Para tudo em que alguém clica ou toca, o alvo maior é o mais gentil, e para uma pessoa com tremor ou com um dedo grande num celular pequeno é a diferença entre acertar o link e acertar o vizinho.

O resto da página não mudou: o HTML semântico da aula 2 e uma folha de estilos pequena. Essa é a divisão de trabalho de que este curso partiu.
