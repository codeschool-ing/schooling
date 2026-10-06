---
title: O teorema central do limite
version: 1
---

O **teorema central do limite** diz, em linguagem de gente:

> Quando você tira a média de uma amostra aleatória grande o bastante, essa média vem de uma distribuição
> aproximadamente **normal**, centrada na **média da população**, com desvio padrão igual ao **desvio
> padrão da população dividido pela raiz quadrada do tamanho da amostra**.

E diz isso **seja qual for a forma da população**: assimétrica, achatada, irregular, não importa, desde que
o desvio padrão da população seja finito e as observações sejam independentes.

## As três partes

**A forma é normal.** As médias se amontoam numa curva em sino, mesmo quando os dados não. Essa é a parte
surpreendente, e o motivo de a distribuição normal da aula 8 importar muito além dos sacos de arroz.

**O centro é a média da população.** A média amostral é não viesada: em média, entre amostras, ela acerta μ
exatamente.

**A dispersão é σ ÷ √*n*.** A dispersão das médias amostrais é menor que a dos dados por um fator de √*n*. A
aula 12 dá um nome a essa quantidade, **erro padrão**, e constrói o intervalo de confiança com ele.

## Em símbolos

Para amostras aleatórias de tamanho *n* de uma população com média μ e desvio padrão σ, a média amostral *x̄*
é aproximadamente **normal, com média μ e desvio padrão σ ÷ √*n***.

Para as cestas da Horta, com σ = R$ 58,82, amostras de 30 dão médias com desvio padrão de 58,82 ÷ √30 =
**R$ 10,74**, e amostras de 100 dão 58,82 ÷ 10 = **R$ 5,88**.

## Por que tirar média produziria um sino?

Uma intuição, não uma prova. Uma média amostral é uma soma de muitos pedaços independentes, dividida por
um número. Cada cesta da amostra empurra a média um pouco para cima ou para baixo. Resultados extremos
precisam que muitos pedaços empurrem para o mesmo lado ao mesmo tempo — as trinta cestas grandes, digamos
—, e isso é raro, porque os pedaços são independentes. Resultados médios podem acontecer de um número
enorme de jeitos. Muitos empurrões pequenos e independentes, a maioria se anulando, produzem o sino. É o
mesmo motivo que a aula 8 deu para os sacos de arroz: muitos efeitos pequenos e independentes somados.

O teorema foi desenvolvido ao longo de mais de um século, desde Abraham de Moivre, nos anos 1730, que achou
a curva normal como aproximação para o lançamento de moedas, passando por Pierre-Simon Laplace, até uma
prova geral no começo do século XX.
