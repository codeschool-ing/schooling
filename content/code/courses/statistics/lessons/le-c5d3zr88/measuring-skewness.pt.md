---
title: Medindo a assimetria
version: 1
---

"Assimétrica à direita" é uma descrição. O **coeficiente de assimetria** é um número para ela: positivo
para uma cauda à direita, negativo para uma cauda à esquerda, e perto de zero para uma forma simétrica.

## De onde vem o número

A medida padrão trabalha com os desvios em relação à média, como a variância, mas os eleva **ao cubo** em
vez de ao quadrado. O cubo mantém o sinal: um valor muito acima da média contribui com um cubo grande e
positivo, um muito abaixo com um grande e negativo. Numa distribuição simétrica eles se anulam. Numa
assimétrica à direita, os valores distantes acima da média pesam mais que os de baixo, e o total sai
positivo.

Os desvios são antes divididos pelo desvio padrão, para que o resultado não tenha unidade e a mesma forma
dê a mesma assimetria, medida em reais ou em centavos. A função `DISTORÇÃO` da planilha também aplica uma
pequena correção pelo tamanho da amostra.

```localised
=DISTORÇÃO(A2:A401)      2,1000341481596
```

Essa é a resposta do LibreOffice Calc para as 400 cestas. Para as três formas da seção anterior:

| dados | assimetria |
|---|---|
| notas da prova | −1,37 |
| sacos de arroz | −0,05 |
| cestas | 2,10 |

## Lendo o tamanho

Um guia aproximado comum, e é só um guia:

- entre −0,5 e 0,5, **aproximadamente simétrica**;
- entre 0,5 e 1, para qualquer lado, **moderadamente assimétrica**;
- além de 1, para qualquer lado, **fortemente assimétrica**.

Os sacos, com −0,05, são simétricos para todo efeito prático. As cestas, com 2,10, são fortemente
assimétricas à direita, e as notas, com −1,37, fortemente assimétricas à esquerda.

## Uma medida mais simples, com o que você já tem

Uma medida mais grosseira, às vezes chamada de **assimetria mediana de Pearson**, precisa só da média, da
mediana e do desvio padrão:

```localised
3 × (média − mediana) ÷ desvio padrão
```

Para as cestas: 3 × (82,78 − 66,74) ÷ 58,89 = **0,82**. É menor que os 2,10 que a `DISTORÇÃO` dá, porque
mede uma coisa um pouco diferente, mas tem o mesmo sinal, e transforma a regra prática "média contra
mediana" num número.

## A assimetria é frágil

Como eleva os desvios ao cubo, a assimetria é ainda mais sensível a valores extremos que o desvio padrão.
Numa amostra de 400 cestas, um único pedido de R$ 2.000 a aumentaria bastante. Uma assimetria tirada de
uma amostra pequena é, no máximo, uma indicação grosseira; com doze valores ela pode oscilar muito quando
um valor muda. Olhe o histograma além do número.
