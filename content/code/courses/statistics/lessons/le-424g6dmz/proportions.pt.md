---
title: Um intervalo para uma proporção
version: 1
---

A aula 1 mostrou que uma coluna de sim/não codificada como 1 e 0 tem média igual à fração de sins. A aula 11
notou que isso faz de uma proporção uma média, então o teorema central do limite a cobre. Isso dá um
intervalo de confiança para uma proporção quase de graça.

## O erro padrão de uma proporção

Para uma variável 0/1 com fração *p̂* de uns, o desvio padrão sai √(*p̂*(1 − *p̂*)), então o erro padrão da
proporção é **EP = √(*p̂* × (1 − *p̂*) ÷ *n*)**, e o intervalo de 95% é *p̂* ± 1,96 × EP.

## A pesquisa de satisfação da Horta

A Horta pesquisa 400 clientes sorteados, e **248** dizem estar satisfeitos com as entregas. A proporção
amostral é 248 ÷ 400 = **0,62**.

- EP = √(0,62 × 0,38 ÷ 400) = **0,0243**.
- A margem é 1,96 × 0,0243 = **0,0476**, um pouco menos de 5 pontos percentuais.
- O intervalo de 95% vai de **0,572 a 0,668**: entre uns 57% e 67% de todos os clientes estão satisfeitos.

É daí que vem a "margem de erro" de uma notícia sobre pesquisa de opinião: "62%, com margem de erro de 5
pontos" é esta conta, com os 95% subentendidos.

## Quando funciona

A aproximação normal por trás deste intervalo precisa de bastante de cada resultado. Uma regra comum: **pelo
menos 10 sins e 10 nãos** na amostra. Os 248 e 152 da pesquisa sobram.

Os doze pedidos da Horta com três entregas atrasadas falham feio: 3 atrasadas e 9 no prazo. A fórmula daria
0,25 ± 0,245, um intervalo de 0,005 a 0,495, que finge uma precisão que doze pedidos não podem ter. Para
contagens pequenas, os softwares estatísticos oferecem intervalos melhores para uma proporção, dos quais o
**intervalo de Wilson** é a escolha usual; a fórmula acima é para amostras em que as duas contagens são
folgadamente grandes.

## O pior caso para a margem

O termo *p̂*(1 − *p̂*) é máximo quando *p̂* = 0,5, onde vale 0,25. Então, para qualquer tamanho de amostra, a
margem mais larga possível é 1,96 × √(0,25 ÷ *n*). Para 400 pessoas, isso dá 4,9 pontos; os 62% da pesquisa
deram 4,8. Esse pior caso é o que a próxima seção usa para planejar uma pesquisa antes de os resultados
existirem.
