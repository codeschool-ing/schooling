---
title: Animações, e o custo de cada propriedade
---

Para algo que acontece sozinho, `@keyframes` descreve o caminho:

```css
@keyframes surgir {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: none; }
}

.painel { animation: surgir .3s ease both; }
```

Repare no que está sendo animado, e é a regra mais rentável desta aula inteira: **anime `transform` e `opacity`.** Elas mexem só na composição, que a placa de vídeo faz sozinha. Animar `width`, `top` ou `margin` refaz o layout de tudo em volta a cada quadro, e é isso que trava em celular.

E respeite quem pediu menos movimento:

```css
@media (prefers-reduced-motion: reduce) {
  * { animation: none !important; transition: none !important; }
}
```
