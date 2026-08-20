---
title: CSSOM e o cálculo de estilo
---

O CSS passa pelo mesmo processo e vira o **CSSOM**. Aí o navegador combina as duas árvores para decidir o estilo final de cada nó, resolvendo herança, especificidade e ordem.

É neste ponto que se decide uma disputa como a que este portal enfrentou: uma regra do navegador para `[hidden]` tem especificidade zero e perde para qualquer classe que declare `display`. Nada disso é visível no arquivo CSS — só no estilo computado.

CSS **bloqueia a renderização** de propósito: mostrar a página sem estilo e reestilizá-la depois piscaria a tela inteira. Por isso folha de estilo grande atrasa a primeira pintura, e por isso `<link>` de CSS fica no `<head>`.
