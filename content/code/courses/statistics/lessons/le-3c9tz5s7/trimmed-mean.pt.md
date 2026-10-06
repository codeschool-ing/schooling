---
title: A média aparada
version: 1
---

A média usa o tamanho de todo valor e a mediana quase nenhum. Uma **média aparada** fica entre as duas:
ordene os valores, corte uma fração fixa em cada ponta e tire a média do que sobrar.

## Aparando a folha

Ordene os nove salários da Horta e tire um de cada ponta — os R$ 2.100 mais baixos e os R$ 28.000 do
fundador. Os sete que sobram são 2.100, 2.250, 2.300, 2.400, 2.600, 2.900 e 3.400, e a média deles é
**R$ 2.564,29**.

Isso está perto da mediana de R$ 2.400 e longe da média de R$ 5.338,89. Aparar um valor em cada ponta
bastou, porque só um valor era extremo.

## Aparando as cestas

Para dados maiores, o corte é uma porcentagem. Uma **média aparada a 10%** das 400 cestas descarta as 40
menores e as 40 maiores e tira a média das 320 do meio:

| resumo | valor |
|---|---|
| média | R$ 82,78 |
| média aparada a 5% | R$ 76,28 |
| média aparada a 10% | R$ 73,31 |
| mediana | R$ 66,74 |

Conforme o corte cresce, a média aparada vai da média em direção à mediana. Corte metade de cada ponta e
não sobra nada além do meio, que é a mediana. Média e mediana são as duas pontas de uma família só, e o
corte escolhe um lugar entre elas.

As planilhas trazem isso pronto. Com as cestas em A2:A401:

```localised
=MÉDIA.INTERNA(A2:A401; 0,2)      73,31309375
```

Esse é o valor que o LibreOffice Calc devolveu para as 400 cestas do curso. O segundo argumento é a
fração **total** removida, dividida entre as duas pontas, então 0,2 tira 10% de cada ponta. É fácil
errar, e errar apara o dobro do que se queria.

## Onde se usa

Médias aparadas aparecem onde se esperam alguns valores extremos que não devem decidir o resultado.
Esportes julgados como os saltos ornamentais descartam as notas mais alta e mais baixa dos juízes antes
de tirar a média do resto, para que um juiz generoso ou severo demais não decida uma medalha. Algumas
estatísticas oficiais de preços usam uma média aparada das variações de preço como medida da inflação
de fundo, para que o salto de preço de um produto não domine o mês.

A fraqueza dela é a mesma que a força: ela joga dados fora. Se os valores extremos são reais e importam
— o salário do fundador para a folha, as cestas grandes para a receita —, apará-los esconde exatamente o
que precisava ser visto.
