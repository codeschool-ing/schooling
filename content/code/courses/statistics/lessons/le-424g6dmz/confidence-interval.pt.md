---
title: O intervalo de confiança
version: 1
---

O teorema central do limite diz que a média amostral é aproximadamente normal em torno da média
verdadeira, com dispersão de um erro padrão. A aula 8 disse que 95% de uma distribuição normal fica a até
1,96 desvio padrão do centro. Junte as duas coisas:

> Em 95% das amostras, a média amostral cai a até 1,96 erro padrão da média verdadeira.

Inverta: se você se afasta 1,96 erro padrão para cada lado da média amostral, pega a média verdadeira em
95% das amostras. Essa faixa é um **intervalo de confiança de 95%**: a média amostral mais ou menos 1,96
erro padrão.

## Para a amostra da Horta

82,39 ± 1,96 × 12,63 dá **de R$ 57,64 a R$ 107,13**.

A Horta pode dizer: "a cesta média é R$ 82,39, com intervalo de confiança de 95% de R$ 57,64 a R$ 107,13". O
intervalo é largo porque 40 cestas de uma quantidade muito variada não determinam a média com precisão. A
última seção desta aula diz quantas cestas um intervalo mais estreito exigiria.

A média verdadeira, R$ 82,78, está dentro. Na vida real você não saberia disso; saberia só que o método pega
a média verdadeira em 95% das amostras.

## Outros níveis

1,96 pertence a 95%. Outros níveis de confiança usam outros multiplicadores, da mesma curva normal:

| confiança | multiplicador | intervalo para a amostra da Horta |
|---|---|---|
| 90% | 1,645 | mais estreito |
| 95% | 1,960 | de R$ 57,64 a R$ 107,13 |
| 99% | 2,576 | mais largo |

Mais confiança custa largura. Um intervalo de 99% pega a verdade mais vezes porque é mais largo. Um de 100% iria de zero ao infinito e não diria nada. 95% é uma convenção, escolhida por ser um equilíbrio razoável, e
a aula 13 apresenta a gêmea dela, o nível de significância de 5%.

## Do que ele precisa

O intervalo herda todas as suposições do teorema central do limite: uma **amostra aleatória**, observações
**independentes** e uma amostra **grande o bastante** para as médias ficarem perto de normais. Para dados
muito assimétricos como as cestas, 40 é pouco, e numa simulação mais adiante nesta aula os intervalos de
95% pegam a média verdadeira um pouco menos de 95% das vezes. E, como o teorema, o intervalo não diz nada
sobre viés: um intervalo de confiança de uma amostra por conveniência é uma afirmação precisa sobre a
população errada.
