---
title: Cascata e herança são coisas diferentes
---

**Cascata** é como o navegador escolhe entre regras que disputam o mesmo elemento: origem, `!important`, especificidade e, por fim, ordem.

**Herança** é outra coisa: algumas propriedades passam de pai para filho sem ninguém pedir. `color`, `font-family` e `line-height` herdam; `border`, `padding` e `background` não.

A distinção importa porque explica um erro comum: definir `font-family` no `body` funciona para a página inteira (herança), mas definir `border` no `body` não desenha borda nenhuma nos filhos. E há o caso híbrido do `<button>`, que **não** herda a fonte por padrão — daí a linha `font: inherit` que aparece em quase todo CSS sério.
