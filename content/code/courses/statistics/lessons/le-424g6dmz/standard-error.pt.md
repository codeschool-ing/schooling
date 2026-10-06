---
title: O erro padrão
version: 1
---

A aula 11 mostrou que as médias amostrais se espalham em torno da média da população com desvio padrão de
σ ÷ √*n*. Na prática σ, o desvio padrão da população, é desconhecido. O que você tem é uma amostra, e o desvio
padrão dela, *s*.

Então a dispersão é estimada pondo *s* no lugar de σ: **EP = *s* ÷ √*n***.

Essa estimativa tem nome próprio, o **erro padrão** da média, ou **EP**. É o desvio padrão estimado da
distribuição amostral: quão longe, tipicamente, uma média amostral desse tamanho cai da média verdadeira.

## A amostra de 40 da Horta

A Horta sorteia 40 pedidos entre os 400 do mês. A amostra tem

- média de **R$ 82,39**,
- desvio padrão de **R$ 79,86**,
- e portanto erro padrão de 79,86 ÷ √40 = **R$ 12,63**.

Com os dados em A2:A41:

```localised
=DESVPAD.A(A2:A41)/RAIZ(40)      12,6264621645681
```

Leia assim: uma média de 40 cestas cai tipicamente a uns R$ 13 da média verdadeira. A média amostral de
R$ 82,39 é uma dessas quedas.

## Desvio padrão contra erro padrão

Os dois se confundem com facilidade, e respondem perguntas diferentes.

| | mede | para a amostra de 40 |
|---|---|---|
| desvio padrão, *s* | quão espalhadas estão as **cestas individuais** | R$ 79,86 |
| erro padrão, *s* ÷ √*n* | quão incerta é a **média** | R$ 12,63 |

O desvio padrão descreve os dados e não encolhe conforme a amostra cresce: as cestas são tão variadas
quanto são. O erro padrão descreve a estimativa e encolhe, porque a média de uma amostra maior fica mais
bem determinada.

Um relatório que escreve "média R$ 82,39 ± 79,86" está dizendo que as cestas individuais variam muito. Um
relatório que escreve "média R$ 82,39 ± 12,63" está dizendo que a média é conhecida com precisão de uns
R$ 13. **Diga sempre qual dos dois é o ±.**

## A população sabia o tempo todo

Como as 400 cestas são o mês inteiro, a média verdadeira é conhecida neste exemplo: R$ 82,78. A amostra
errou por R$ 0,39, bem menos que um erro padrão. Isso foi sorte tanto quanto qualquer outra coisa; a
próxima seção transforma o erro padrão numa faixa que acerta com uma frequência declarada.
