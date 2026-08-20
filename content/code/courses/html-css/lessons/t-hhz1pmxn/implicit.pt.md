---
title: Grid implícito e grades que se ajustam
---

Se você declara duas colunas e entram seis itens, o grid cria linhas novas sozinho: é o **grid implícito**, controlado por `grid-auto-rows`.

A combinação mais rentável do CSS moderno faz uma grade responsiva **sem nenhuma media query**:

```css
.cartoes {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 12px;
}
```

Lê-se: quantas colunas couberem, cada uma com no mínimo 220px e dividindo o resto igualmente. A grade se reorganiza sozinha em qualquer largura.

`auto-fill` mantém as colunas vazias reservadas; `auto-fit` as colapsa, fazendo os itens existentes esticarem para preencher. Com poucos itens numa tela larga, a escolha entre os dois é bem visível.
