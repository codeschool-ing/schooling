---
title: Qual unidade para quê
---

Cada unidade responde a uma pergunta diferente, e escolher errado é a origem de metade dos problemas de acessibilidade em tipografia.

- **`px`** — absoluto. Bom para borda e para sombra, onde o valor é físico mesmo.
- **`rem`** — múltiplo da fonte-raiz. É o padrão para tipografia e espaçamento, porque **respeita quem aumentou a fonte no navegador**. Tamanho de texto em `px` ignora essa preferência.
- **`em`** — múltiplo da fonte do próprio elemento. Útil para espaçamento que deve acompanhar o texto, mas cuidado: ele acumula em elementos aninhados.
- **`%`** — relativo ao contêiner. Largura.
- **`vw` / `vh`** — relativo à janela. Bom para telas cheias; no celular, prefira `svh`/`dvh`, que lidam com a barra do navegador que aparece e some.

A regra prática que resolve quase tudo: **`rem` para texto e espaço, `%` ou `fr` para largura, `px` só para detalhes finos.**
