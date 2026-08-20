---
title: Duas dimensões de uma vez
---

Flexbox organiza ao longo de um eixo; Grid organiza linhas e colunas ao mesmo tempo. A unidade nova é `fr`, uma fração do espaço livre:

```css
.pagina {
  display: grid;
  grid-template-columns: 240px 1fr;
  gap: 16px;
}
```

Isso é uma barra lateral fixa e um conteúdo que ocupa o resto — exatamente o esqueleto deste portal. Em flexbox daria para fazer, mas exigiria declarar o comportamento em cada filho; em grid, o pai declara a forma e os filhos não precisam saber de nada.
