---
title: Quando um modelo linear é a escolha certa
version: 1
---

Nos dados de churn, a regressão logística fez R$ 16.424 nos meses de teste e o gradient boosting
R$ 21.672. É uma diferença real, cerca de um quarto, e por essa evidência a caixa vence. Muitas vezes
essa é a decisão certa, e vale conhecer os motivos de às vezes não ser antes que a aula 8 aumente a
caixa.

**Um modelo linear é legível.** O conteúdo inteiro dele é uma lista curta de números, e a lista pode
ser conferida contra o que as pessoas que conhecem o negócio acreditam. Quando um peso sai com o
sinal errado, digamos entregas atrasadas deixando as pessoas *menos* propensas a sair, isso é um
achado: um vazamento, um defeito numa coluna ou uma surpresa sobre os clientes, e cada um vale saber.
Um modelo de boosting com o mesmo defeito é mais difícil de pegar.

**Ele é estável.** Reajustado no mês seguinte com linhas um pouco diferentes, os pesos mudam pouco;
as previsões para um dado assinante mudam pouco. Alguns modelos mudam muito de ideia sobre linhas
individuais entre um ajuste e outro, o que é um problema quando a equipe de retenção já ligou para
alguém.

**Ele se degrada com elegância fora dos dados.** Uma entrega de 45 km, mais longa que qualquer uma do
treino, recebe uma previsão que continua a reta: longa, mais ou menos certa. Uma árvore, mostra a aula
7, prevê o mesmo que para a entrega mais longa que viu, o que é errado de um jeito diferente e menos
óbvio.

**É barato de rodar e de explicar a um regulador.** Em crédito, seguro e saúde, a explicação às vezes
é exigência legal e não gentileza, e a aula 20 volta a isso.

Contra tudo isso: **ele só acha as formas que recebe.** Os dados de churn têm um limiar dentro, quem
tem avaliação média abaixo de certo ponto sai muito mais, e uma interação entre atraso e ser novo. A
regressão logística vê uma versão em linha reta de cada um, e o modelo de boosting os vê como são.
Isso é quase todo o R$ 5.248 entre os dois.

A conclusão prática é um hábito, não uma regra. **Ajuste o modelo linear primeiro**, sempre: ele é a
linha de base mais forte que existe, leva um minuto, e seus pesos dizem se os dados fazem sentido.
Depois ajuste a caixa, e pergunte se o ganho dela vale o que o modelo linear estava dando. Aqui, com
essa diferença, a Ana escolheria a caixa e manteria o modelo linear como conferência dela.
