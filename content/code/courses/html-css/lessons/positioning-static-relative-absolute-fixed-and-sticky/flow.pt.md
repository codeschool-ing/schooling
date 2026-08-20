---
title: O fluxo normal, e sair um pouco dele
---

Por padrão todo elemento é `position: static`: ele fica onde o fluxo o colocou, e `top`/`left` não fazem nada.

`position: relative` mantém o elemento no fluxo — **o espaço dele continua reservado** — e desloca só o desenho. Por isso ele quase nunca é usado para mover coisas: é usado para virar **âncora** de um filho `absolute`, que é o assunto da próxima seção.
