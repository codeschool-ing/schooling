---
title: Por que dividir por n − 1?
version: 1
---

A variância amostral divide a soma dos quadrados por *n* − 1 em vez de *n*. Parece uma correção
caprichosa, e conserta um viés real.

## O problema: a média da própria amostra está perto demais

Os desvios são medidos a partir da média **da amostra**, não da média verdadeira de tudo aquilo de onde a
amostra veio. A média verdadeira é desconhecida — em geral é por isso que se tirou uma amostra. E a média
da própria amostra tem uma propriedade que enviesa o resultado: ela é o ponto que torna a soma dos
desvios ao quadrado **a menor possível**. Meça os mesmos oito valores a partir de qualquer outro ponto,
a média verdadeira inclusive, e a soma dos quadrados sai maior.

Então uma soma dos quadrados em torno da média amostral é sistematicamente um pouco pequena demais, e
dividi-la por *n* dá uma variância pequena demais em média. Dividir pelo número menor, *n* − 1, a infla na
medida exata.

## Vendo isso numa população que dá para listar

Pegue uma população minúscula cuja variância verdadeira é conhecida: três tempos de entrega, **30, 35 e
43 minutos**. A média deles é 36, e a variância, dividida por *n* porque esta é a população inteira, é
**28,67**.

Agora tire todas as amostras possíveis de dois tempos, com reposição, para que cada sorteio seja
independente do outro. São nove: (30, 30), (30, 35), (30, 43), (35, 30) e assim por diante. Para cada
amostra, calcule a variância dos dois jeitos e tire a média das nove:

| dividindo por | média das nove variâncias amostrais |
|---|---|
| *n* = 2 | 14,33 |
| *n* − 1 = 1 | 28,67 |

Dividir por *n* erra pela metade, em média. Dividir por *n* − 1 acerta exatamente os 28,67 da população. É
isso que os estatísticos querem dizer quando falam que a versão com *n* − 1 é **não viesada**: na média de
todas as amostras que você poderia ter tirado, ela cai na verdade.

## Graus de liberdade

O nome usual de *n* − 1 é **graus de liberdade**. Fixada a média amostral, só *n* − 1 dos desvios estão
livres para variar: o último é forçado, porque eles precisam somar zero. Os sete primeiros desvios do
Davi são −13, −9, −4, 0, 3, 5 e 9; o oitavo tem de ser 9 para o total dar zero. Oito valores, sete
informações independentes sobre a dispersão.

A expressão volta nas aulas 12 a 16, onde toda estatística de teste carrega seus graus de liberdade.

## Quando dividir por n

Divida por *n* só quando os dados **são** a população inteira e você quer descrevê-la, não inferir nada
além dela: os salários das nove pessoas da Horta, se a pergunta é sobre essas nove pessoas e mais
ninguém. Na prática isso é raro, e a diferença encolhe conforme *n* cresce: com 400 cestas, dividir por 399
ou por 400 muda o desvio padrão no quarto algarismo significativo.
