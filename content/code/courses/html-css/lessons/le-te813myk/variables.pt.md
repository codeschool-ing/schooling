---
title: Custom properties
---

Variáveis de CSS são declaradas com dois hífens e lidas com `var()`:

```css
:root {
  --azul: #5b8cff;
  --espaco: 16px;
}

.botao {
  background: var(--azul);
  padding: var(--espaco);
}
```

A diferença para as variáveis de um pré-processador é decisiva: estas **existem no navegador**. Elas herdam, podem ser trocadas dentro de um seletor, respondem a media query e são legíveis e escrevíveis pelo JavaScript em tempo de execução. Uma variável de Sass some na compilação; esta continua lá.
