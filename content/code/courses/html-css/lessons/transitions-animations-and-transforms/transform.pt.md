---
title: Transformações
---

`transform` move, gira, escala e inclina sem tirar o elemento do fluxo: **o espaço dele continua reservado** onde sempre esteve, e nada em volta se mexe.

```css
.selo {
  transform: translateX(10px) rotate(-3deg) scale(1.05);
  transform-origin: left center;
}
```

A ordem das funções importa: girar e depois deslocar não dá no mesmo que deslocar e depois girar, porque cada uma opera no sistema de coordenadas deixado pela anterior.
