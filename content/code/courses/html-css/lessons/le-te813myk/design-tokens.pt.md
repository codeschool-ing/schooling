---
title: Design tokens: dando nome às decisões
version: 1
---

As variáveis de que o design de um site é feito costumam se chamar **design tokens**: as decisões nomeadas sobre cor, espaçamento, tipografia e assim por diante, escritas uma vez para que toda regra se refira a elas. Uma equipe de design as guarda numa ferramenta de design, e o `:root` da folha de estilos é onde elas viram CSS. Dar bons nomes é a maior parte do trabalho, e dois níveis de nome ajudam:

```css
:root {
  /* the palette: what colours exist */
  --green-700: #2f6f4e;
  --green-200: #8fd1ad;
  --red-800: #8a1c1c;
  --sand-50: #fbf8f2;

  /* the roles: where each is used */
  --color-page: var(--sand-50);
  --color-text: #1d1d1b;
  --color-accent: var(--green-700);
  --color-danger: var(--red-800);

  /* space, on one scale */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-4: 1rem;
  --space-8: 2rem;

  /* type */
  --font-body: system-ui, sans-serif;
  --text-small: 0.875rem;
  --text-heading: 1.5rem;

  /* what sits on top of what, lesson 7 */
  --layer-dropdown: 10;
  --layer-sticky: 20;
  --layer-modal: 100;
}
```

**Os nomes da paleta dizem o que a cor é**; os nomes de papel dizem para que ela serve. Os componentes só usam os papéis: um botão usa `--color-accent`, nunca `--green-700`. Aí um redesenho que deixa o destaque azul muda uma linha, e um tema escuro redefine os papéis e deixa a paleta em paz, como fez a seção 06.

**Uma escala em vez de números soltos.** Com `--space-1` a `--space-8`, todo espaço do site é um de poucos tamanhos, e uma página parece coerente sem ninguém medir. Um valor fora da escala, `margin: 13px`, passa a ser visivelmente uma exceção, o que costuma ser um engano.

**z-index como níveis com nome.** A seção 08 da aula 7 terminou com isto: uma escala curta com nomes faz de "o modal fica acima do dropdown" um fato num lugar só, em vez de uma disputa entre 9999 e 99999 em dois arquivos.

O Tailwind, aula 13, é construído exatamente sobre essa ideia, com tokens próprios, e deixa você trocá-los pelos seus.
