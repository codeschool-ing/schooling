---
title: Um vocabulário comum, não uma lista de verificação
version: 1
---

A OWASP, Open Worldwide Application Security Project, é uma comunidade que documenta como o software
falha e publica o que acha abertamente. A lista mais conhecida dela é o Top 10 para aplicações web.
Desde 2023 ela publica um **Top 10 para aplicações com LLM** separado, e a edição atual, a que esta aula
usa, é de 2025.

A lista é fácil de usar mal de dois jeitos opostos.

**Como lista de verificação.** Uma equipe lê os dez nomes, confirma que cada um soa como algo em que já
pensou, e marca a aplicação como coberta. A lista não sustenta isso. Cada entrada descreve uma família
de falhas, e se uma aplicação está exposta depende do que ela faz: um assistente sem ferramentas tem
pouco a temer de *excessive agency* e muito de *misinformation*.

**Como curiosidade.** Um curso ou uma entrevista pergunta que número uma categoria tem. Os números
ordenam as entradas mais ou menos pela frequência e pela gravidade, mudaram entre as edições de 2023 e
2025, e vão mudar de novo.

Para o que a lista serve é **um vocabulário**. Quando um revisor escreve *improper output handling* ao
lado de um pull request, todo mundo que leu a lista imagina a mesma coisa: a resposta de um modelo usada
por outro código sem ser conferida. Um nome comum transforma uma preocupação vaga numa pergunta que pode
ser feita a um recurso específico, e é assim que este curso o usa.

Toda entrada é uma falha que este curso já encontrou, com um nome próprio. A próxima seção põe os dois
nomes lado a lado.
