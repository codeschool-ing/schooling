---
title: Crescer, encolher e a base
---

A propriedade `flex` é um atalho para três coisas: quanto o item pode crescer, quanto pode encolher e de que tamanho ele parte.

```css
.lado    { flex: 0 0 240px; }  /* não cresce, não encolhe: 240px fixos */
.miolo   { flex: 1 1 auto; }   /* ocupa o que sobrar */
.igual   { flex: 1; }          /* atalho de 1 1 0: todos com a mesma largura */
```

A diferença entre `flex: 1` e `flex: 1 1 auto` derruba muita gente: com base `0`, os itens ficam todos do mesmo tamanho; com base `auto`, o conteúdo de cada um influencia, e um item com texto longo fica maior que os outros.

E um item flex **não encolhe abaixo do conteúdo** por padrão, o que faz texto longo estourar o contêiner. A cura é `min-width: 0` no item — a linha mais misteriosa e mais útil do flexbox.
