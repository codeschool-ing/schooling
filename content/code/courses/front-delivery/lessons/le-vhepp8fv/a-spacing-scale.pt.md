---
title: Uma escala de espaçamento numa grade
version: 1
---

**Tokens de espaçamento são múltiplos de uma unidade, para que todo espaço do produto seja um de poucos
tamanhos.** A unidade do planner é um quarto de rem, quatro pixels por padrão, e ela tem oito passos:

```
ana@dev:~/planner$ grep space src/tokens.css
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-5: 1.25rem;
  --space-6: 1.5rem;
  --space-7: 1.75rem;
  --space-8: 2rem;
```

Quatro pixels é a grade que a maioria dos design systems usa, porque divide por igual os tamanhos de tela
comuns e é pequena o bastante para ajustar um controle denso sem inventar um valor. Alguns sistemas usam
oito e dividem por dois onde precisam; a escolha importa menos que ter uma.

## O que os tokens substituem

A folha de estilo do planner da aula 1 tinha `margin: 2rem auto`, `padding: 0 1rem`, `gap: 1rem` e
`margin: 0.25rem 0`. Cada um desses foi o olho de alguém no dia. Como tokens eles viram `--space-8`,
`--space-4`, `--space-4` e `--space-1`, e três coisas vêm disso:

- **quem revisa consegue ver um valor errado.** `padding: 13px` num pull request salta aos olhos no meio de
  `var(--space-…)`; `13px` no meio de outros valores em pixel, não.
- **os passos se relacionam.** O espaço interno de um cartão em `--space-4` e o espaço entre cartões em
  `--space-6` formam um ritmo, porque compartilham uma unidade.
- **a densidade muda num lugar só.** Um modo compacto para uma tabela densa é uma unidade diferente para
  aquela parte da página, e todo espaço dentro dela acompanha.

## Onde a escala para

Nem todo comprimento é espaçamento. As dimensões próprias de um componente, a largura máxima de uma coluna
(`40rem` no planner), a espessura de uma borda: esses são tokens separados ou valores simples, e
forçá-los na escala de espaçamento produz um `--space-160` que ninguém consegue explicar. Tokens de
espaçamento são para o espaço **entre** e **dentro** das coisas, que é a maioria dos comprimentos de uma
folha de estilo e não todos.
