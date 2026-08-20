---
title: Mobile first é sobre o que é padrão
---

Mobile first não é "começar desenhando o celular": é **escrever o CSS do celular sem media query nenhuma**, e usar as media queries só para acrescentar o que telas maiores permitem.

```css
/* padrão: uma coluna, vale para todo mundo */
.grade { display: grid; gap: 12px; }

/* a partir de 860px, duas colunas */
@media (min-width: 860px) {
  .grade { grid-template-columns: 1fr 1fr; }
}
```

A ordem importa mais do que parece. Escrito ao contrário — desktop primeiro, com `max-width` — o celular precisa **desfazer** regras, e desfazer custa mais linhas e mais especificidade que acrescentar. Além disso, o aparelho mais fraco passa a baixar e aplicar o CSS que não vai usar.
