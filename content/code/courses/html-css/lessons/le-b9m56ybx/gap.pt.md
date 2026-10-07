---
title: Espaço entre itens: gap
version: 1
---

O espaço entre itens flex costumava ser feito com margens, e margens causam dois problemas: o último item tem uma margem depois dele que ninguém queria, então a fileira termina curta, e com quebra de linha os itens do começo de cada linha têm uma margem antes. **`gap`** põe espaço **entre** os itens e em nenhum outro lugar:

```css
.shelf {
  display: flex;
  gap: 16px;
}
```

São 16 pixels entre cada par de itens, e nada antes do primeiro nem depois do último. Com quebra de linha, `gap` também define o espaço entre as linhas; dois valores, `gap: 24px 16px`, definem primeiro o vão entre linhas e depois entre itens, a mesma ordem linha-depois-coluna de todo o resto do CSS. `row-gap` e `column-gap` os definem um de cada vez.

As prateleiras de `align.html` acima usaram `gap: 8px`, e é por isso que as posições x dos itens eram 0, 58,69 e 165,16: cada um começa 8 pixels depois de o anterior terminar, 50,69 + 8 = 58,69.

## O gap e o espaço livre

O `gap` sai do espaço livre antes de qualquer outra distribuição. Uma prateleira de 600 com três itens de 100 e `gap: 16px` tem 600 − 300 − 32 = 268 pixels para o `justify-content` ou o `flex-grow` trabalharem. **Use `gap` para o espaço entre itens, e margens para o espaço entre o contêiner e o que está em volta dele.** A mesma propriedade funciona igual no Grid, aula 9, o que é mais um motivo para preferi-la.
