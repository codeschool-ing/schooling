---
title: Configuração é onde o design system mora
---

As classes saem de uma escala configurável. Personalizar a escala é o que impede o Tailwind de ser um monte de valores mágicos:

```css
@theme {
  --color-marca: #5b8cff;
  --spacing-secao: 4.5rem;
}
/* passam a existir bg-marca, text-marca, p-secao… */
```

Feito isso, `bg-marca` é a cor da marca em todo lugar, e trocá-la é editar uma linha. É o mesmo papel das variáveis CSS da aula 09 — a diferença é que aqui a escala também gera as classes.
