---
title: Toda coisa é uma caixa
---

Cada elemento é um retângulo com quatro camadas, de dentro para fora: **conteúdo**, **padding**, **borda** e **margem**.

Padding é espaço interno — ele empurra o conteúdo para longe da borda e recebe a cor de fundo. Margem é espaço externo — separa esta caixa das vizinhas e é transparente.

Um detalhe que confunde todo mundo uma vez: **margens verticais adjacentes se fundem**. Dois parágrafos com 20px de margem embaixo e em cima não ficam com 40px de distância; ficam com 20. É o *colapso de margens*, vale só na vertical, e é a razão de muita gente usar `gap` do flex/grid em vez de margem.
