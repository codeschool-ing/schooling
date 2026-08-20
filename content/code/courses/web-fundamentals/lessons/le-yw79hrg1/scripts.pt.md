---
title: Onde o JavaScript entra
---

Um `<script>` comum **para a montagem do DOM** enquanto baixa e executa, porque ele pode alterar a árvore que está sendo construída. Script no topo do `<head>` é a receita clássica de página em branco.

Dois atributos resolvem: `defer` baixa em paralelo e executa depois do HTML montado, preservando a ordem entre scripts; `async` baixa em paralelo e executa assim que chegar, sem garantir ordem nenhuma.

`defer` é o padrão certo para o código da própria página, e é também o comportamento de um `<script type="module">` — o que explica por que este portal pode chamar `document.querySelector` no topo do módulo sem esperar por evento nenhum.
