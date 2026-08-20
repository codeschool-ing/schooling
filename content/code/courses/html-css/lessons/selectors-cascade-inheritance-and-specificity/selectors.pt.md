---
title: O vocabulário dos seletores
---

Seletor é a pergunta "quais elementos?". As formas que resolvem quase tudo:

```css
.cartao          { }   /* classe */
#topo            { }   /* id */
nav a            { }   /* descendente: todo `a` dentro de nav */
nav > a          { }   /* filho direto */
li + li          { }   /* irmão imediatamente seguinte */
a[href^="http"]  { }   /* atributo que começa com */
li:nth-child(2n) { }   /* pseudo-classe */
```

Na prática, **classe resolve 90% dos casos**, e é o que se deve preferir. Id é único por página e, como se vê na próxima seção, tem um peso na especificidade que atrapalha mais do que ajuda.
