---
title: Tema claro e escuro com uma chave
---

Como as variáveis herdam, trocar um tema inteiro é redeclará-las num escopo acima:

```css
:root {
  --fundo: #0a0e14;
  --texto: #e8e6df;
}

html[data-tema="claro"] {
  --fundo: #f2f4f9;
  --texto: #1a1f28;
}

body { background: var(--fundo); color: var(--texto); }
```

O resto do CSS nunca menciona cor de tema: ele lê `var(--fundo)` e não sabe que existem dois. Trocar o tema vira acrescentar um atributo no `<html>` — uma linha de JavaScript, sem reescrever regra nenhuma. É exatamente como o portal e a vitrine fazem.
