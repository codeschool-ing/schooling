---
title: Onde entram o CSS e o JavaScript
---

A folha de estilo vai no `<head>`, e o script vai no fim do `<body>` ou com `defer`:

```html
<head>
  <link rel="stylesheet" href="estilo.css" />
  <script src="app.js" defer></script>
</head>
```

Os dois lugares vêm do mesmo raciocínio, com resultados opostos. **CSS bloqueia a renderização de propósito** — mostrar a página sem estilo e reestilizá-la depois piscaria a tela inteira —, então quanto antes ele começar a baixar, melhor.

**Script comum bloqueia a montagem do DOM**, porque pode alterar a árvore que está sendo construída. Por isso `<script>` no topo do `<head>` sem `defer` é a receita clássica de página em branco. Com `defer`, ele baixa em paralelo e executa depois do HTML montado, preservando a ordem entre scripts.
