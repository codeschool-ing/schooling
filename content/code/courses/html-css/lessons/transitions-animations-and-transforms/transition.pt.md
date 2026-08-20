---
title: Transição: suavizar uma mudança
---

`transition` interpola entre dois valores quando a propriedade muda:

```css
.botao {
  background: var(--azul);
  transition: background .2s ease, transform .2s ease;
}
.botao:hover {
  transform: translateY(-2px);
}
```

A transição é declarada no estado **normal**, não no `:hover` — assim ela vale na ida e na volta. Declarada só no `:hover`, o efeito entra suave e sai seco.

Evite `transition: all`. Ele passa a animar propriedades que você nem sabia que mudaram, e é uma fonte silenciosa de travamento.
