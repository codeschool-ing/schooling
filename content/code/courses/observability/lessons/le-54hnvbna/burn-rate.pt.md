---
title: A taxa de queima
version: 1
---

Um alerta sobre o SLI precisa de um limite, e o óbvio está errado. *Acionar quando a disponibilidade
cair abaixo de 99,5%* dispara em quaisquer cinco minutos em que mais de um checkout em duzentos falha,
o que de madrugada pode ser uma falha em cinquenta requisições, e não diz nada sobre se o mês está em
perigo.

A pergunta útil é **com que velocidade o orçamento está sendo gasto**. Essa é a **taxa de queima** (burn
rate): a taxa de erros dividida pela taxa de erros que o objetivo permite.

> taxa de queima = (1 − SLI) / (1 − SLO)

Com um objetivo de 99,5%, a taxa de erros permitida é 0,5%. Uma taxa de queima de 1 significa
checkouts falhando a exatamente 0,5%, o que gasta o orçamento em exatamente uma janela, 28 dias. Uma
taxa de queima de 2 o gasta em 14 dias; uma de 28, em um dia.

| taxa de queima | o orçamento dura | em uma hora, gasta |
|---|---|---|
| 1 | 28 dias | 0,15% |
| 3 | 9,3 dias | 0,45% |
| 14,4 | 1,9 dia | 2,1% |
| 200 | 3,4 horas | 30% |

**A taxa de queima transforma *quão ruim* em *quão urgente*.** Uma taxa de 14,4 sustentada por uma hora
custa 2% do orçamento do mês, o que vale acordar alguém, porque deixada sozinha ela esvazia o orçamento
em menos de dois dias. Uma taxa de 3 é um problema para amanhã: levaria nove dias, e um ticket basta.
Esses dois números, 14,4 e 3, não são leis; são o par que o workbook de SRE do Google propõe, e uma
equipe pode derivar os seus de quanto orçamento aceita perder antes de alguém agir.

A taxa de queima também é cega de um jeito útil: não liga para o tráfego. Cinquenta falhas numa hora de
cinco mil checkouts e uma falha numa hora de cem são as duas uma taxa de erros de 1%, uma taxa de
queima de 2, e a mesma fração da promessa do mês. O que ela não aguenta é **tráfego nenhum**: uma razão
de nada sobre nada é indefinida, que é exatamente quando o checkout sintético da aula 14 se paga. Às
três da manhã, sem ninguém comprando, uma sonda falhando é o único sinal que existe, e merece um page
próprio se a loja vende a essa hora.
