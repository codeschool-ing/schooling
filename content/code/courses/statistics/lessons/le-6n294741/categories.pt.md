---
title: Categorias num modelo
version: 1
---

A aula 2 prometeu uma maneira de pôr uma variável categórica, como o bairro, num cálculo sem fingir que os rótulos são números. Aqui está ela.

## Variáveis indicadoras

Uma categoria com *k* níveis vira *k* − 1 colunas de zeros e uns, chamadas **variáveis indicadoras** ou **dummies**. Para os quatro bairros, com o Centro como **referência**:

| bairro | Cambuí | Taquaral | Barão Geraldo |
|---|---|---|---|
| Centro | 0 | 0 | 0 |
| Cambuí | 1 | 0 | 0 |
| Taquaral | 0 | 1 | 0 |
| Barão Geraldo | 0 | 0 | 1 |

O Centro é a linha de zeros. Não há quarta coluna, porque ela seria sempre igual a um menos a soma das outras três, e a regressão não conseguiria separá-la do intercepto.

## O que os coeficientes querem dizer

Uma regressão dos minutos pelas três indicadoras dá:

**minutos previstos = 30,60 + 1,35 × Cambuí + 7,62 × Taquaral + 23,22 × Barão Geraldo**

O intercepto é a média do Centro, 30,60 minutos. Cada coeficiente é a **diferença daquele bairro para o Centro**: a média do Cambuí é 30,60 + 1,35 = 31,95, a do Taquaral 38,22, a de Barão Geraldo 53,82. Uma regressão só com indicadoras reproduz as médias de grupo da ANOVA da aula 16, e o teste F dela é o mesmo teste.

## Acrescentando a distância

Ponha a distância no mesmo modelo e os coeficientes dos bairros desabam: **−1,03**, **−0,26** e **−0,69** minuto, nenhum distinguível de zero (p = 0,38, 0,87 e 0,86), enquanto a distância mantém uma inclinação de 2,51 minutos por quilômetro.

Barão Geraldo era 23 minutos mais lento que o Centro, e o modelo diz que os 23 minutos são distância. Os dados não mostram sinal de que uma entrega para Barão Geraldo demore mais que qualquer outra entrega do mesmo comprimento. O bairro importava só por causa de onde fica.

## Escolhendo a referência

O nível de referência é uma escolha, e muda os coeficientes mas não as previsões. Com Barão Geraldo como referência, todo coeficiente seria uma diferença para Barão Geraldo. Escolha o nível que deixa mais fáceis de ler as comparações que interessam, em geral o mais comum ou uma base natural.
