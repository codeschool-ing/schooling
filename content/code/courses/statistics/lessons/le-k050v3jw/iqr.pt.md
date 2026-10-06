---
title: A amplitude interquartil
version: 1
---

A **amplitude interquartil**, ou IQR (da sigla em inglês), é Q3 menos Q1: a largura da metade do meio dos
dados.

Para os doze tempos de entrega, 41,75 − 32,625 = **9,125 minutos**. Metade das entregas da Horta cai numa
faixa de uns nove minutos de largura.

```localised
=QUARTIL.INC(A2:A13; 3) - QUARTIL.INC(A2:A13; 1)      9,125
```

## Robusta, como a mediana

A IQR ignora o quarto de cima e o quarto de baixo dos dados. Mude a entrega mais lenta de 61 minutos para
610 e a IQR não se mexe, enquanto o desvio padrão iria de 9,77 para mais de 160.

Isso faz da IQR para o desvio padrão o que a mediana é para a média: **uma medida robusta de dispersão**.
O ponto de ruptura dela é um quarto. Para movê-la arbitrariamente seria preciso corromper um quarto dos
valores, contra um valor só para o desvio padrão.

## Escolhendo entre a IQR e o desvio padrão

As duas medem a dispersão de jeitos diferentes, e em dados assimétricos contam histórias diferentes.

Para as 400 cestas, o desvio padrão é R$ 58,89 e a IQR é R$ 63,82, de Q1 = R$ 42,56 a Q3 = R$ 106,38. Os
números têm tamanho parecido, mas não descrevem a mesma coisa: a IQR descreve a metade do meio, onde está
a maioria dos clientes, e o desvio padrão é puxado para cima pela cauda longa das cestas grandes.

O par é natural:

| centro | dispersão | quando |
|---|---|---|
| média | desvio padrão | dados mais ou menos simétricos, ou perguntas sobre totais |
| mediana | IQR | dados assimétricos, ou dados que podem ter valores extremos |

**Informe em pares que combinam.** Uma mediana com um desvio padrão mistura um centro robusto com uma
dispersão frágil, e quem lê não consegue saber que história os números estão contando.

## A IQR como régua

A IQR também dá uma escala para decidir se um valor está anormalmente longe do resto. Uma entrega a 1,5
IQR além de Q3 está, por uma convenção muito usada, longe o bastante para merecer um olhar. Para as doze
entregas, essa linha fica em 41,75 + 1,5 × 9,125 = **55,44 minutos**, e uma entrega, a de 61 minutos, fica
além dela. O boxplot é construído exatamente sobre essa régua, e a aula 9 pergunta o que fazer com os
valores que ela aponta.
