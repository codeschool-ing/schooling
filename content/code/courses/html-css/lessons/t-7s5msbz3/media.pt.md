---
title: Media queries além da largura
---

Largura é a mais usada, e longe de ser a única:

```css
@media (max-height: 560px)          { }  /* teclado virtual aberto */
@media (prefers-color-scheme: dark) { }  /* tema do sistema */
@media (prefers-reduced-motion: reduce) { }  /* movimento reduzido */
@media (hover: none)                { }  /* toque, sem cursor */
```

A de `prefers-reduced-motion` é a que mais gente esquece e a que mais importa para quem precisa dela: há pessoas para quem animação de deslocamento causa enjoo real. Respeitá-la é desligar transições dentro dessa consulta.

`hover: none` resolve o menu que "não abre no celular": efeitos pendurados em `:hover` não existem no toque.
