---
title: box-sizing, e a primeira linha de todo CSS
---

Por padrão, `width` mede só o conteúdo. Então uma caixa declarada com 200px e mais padding e borda ocupa **mais** que 200px:

```css
.caixa {
  width: 200px;
  padding: 20px;
  border: 2px solid;
}
/* largura real: 200 + 20+20 + 2+2 = 244px */
```

Isso torna qualquer layout uma conta de cabeça. A correção é uma linha, e ela abre praticamente todo CSS moderno:

```css
*, *::before, *::after {
  box-sizing: border-box;
}
```

Com `border-box`, `width: 200px` significa 200px na tela, com padding e borda **para dentro**. É o comportamento que todo mundo esperava desde o começo.
