---
title: "Quanto a reta explica: R²"
version: 1
---

Uma reta pode ser a melhor disponível e ainda assim ser fraca. O **R²**, o **coeficiente de determinação**, mede quanto da variação na resposta ela responde.

## Dividindo a variação

Sem regressão, a melhor previsão para toda entrega é a média, 38,65 minutos. A distância total ao quadrado dos dados até essa média é a **soma total dos quadrados**: para as 120 entregas, **13.174,20**.

Com a reta, esse total se divide em duas partes:

- a parte que a reta responde, as distâncias ao quadrado dos valores **previstos** até a média: **11.012,45**;
- a parte que sobra, os **resíduos** ao quadrado: **2.161,75**.

As duas somam o total. O R² é a fração respondida:

**R² = 11.012,45 ÷ 13.174,20 = 0,836**

```localised
=RQUAD(D2:D121; A2:A121)    0,835910261670024
=EPADYX(D2:D121; A2:A121)   4,28017769397204
```

Para uma reta com um preditor, o R² é exatamente o quadrado da correlação da aula 17: 0,914² = 0,836.

## O tamanho de um erro típico

O R² é uma proporção, sem unidade. O **desvio padrão dos resíduos**, também chamado de erro padrão da regressão, dá a mesma informação em minutos: **4,28**. Uma entrega típica cai a uns quatro minutos da reta. Sem a reta, uma entrega típica cai a 10,52 minutos da média, que é o desvio padrão dos minutos.

Para uma promessa de entrega, o desvio padrão dos resíduos é o número mais útil. "A reta explica 84% da variação" é abstrato. "As previsões erram tipicamente por uns quatro minutos" é algo com que a Horta consegue se planejar.

## O que o R² não diz

Um R² alto não quer dizer que a reta tem a forma certa: a curva de Anscombe na aula 17 tinha r² = 0,67 com o modelo errado. Não quer dizer que o preditor causa a resposta: aula 18. E um R² baixo não torna uma inclinação inútil. O número de itens explica só 4% da variação nos tempos de entrega, mas sua inclinação continua sendo a melhor estimativa de quanto custa um item a mais.
