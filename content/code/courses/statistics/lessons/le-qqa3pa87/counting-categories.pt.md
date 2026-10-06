---
title: Contando categorias
version: 1
---

Como todo resumo de uma variável categórica parte de uma contagem, a ferramenta básica é a **tabela de
frequências**: cada categoria, quantas observações caíram nela e que parte do todo isso representa.

| pagamento | contagem | proporção |
|---|---|---|
| pix | 6 | 50,0% |
| cartão | 4 | 33,3% |
| dinheiro | 2 | 16,7% |
| **total** | **12** | **100,0%** |

A contagem é a **frequência**. A proporção é a **frequência relativa**: a contagem dividida pelo total.
Uma frequência relativa pode ser escrita como fração, decimal ou porcentagem. 2/12, 0,167 e 16,7% são o
mesmo fato.

## Por que proporções, se as contagens estão ali

Uma contagem responde *quantos*. Uma proporção responde *quão comum*, e é ela que dá para comparar.

Se um segundo mês trouxesse 30 pagamentos com cartão, você não saberia dizer se o cartão ficou mais
popular até saber quantos pedidos aquele mês teve. Trinta em sessenta é a mesma proporção que quatro em
oito. Contagens comparam totais; **proporções comparam hábitos**.

## As proporções deveriam somar 100%, e às vezes não somam

Proporções arredondadas para um relatório podem somar 99,9% ou 100,1%. Acima, 50,0 + 33,3 + 16,7 soma
exatamente 100,0, mas 33,3 já é um terço arredondado para baixo, e com outras contagens o arredondamento
apareceria. Isso não é erro de contagem, e uma nota dizendo que os números estão arredondados basta.

Uma tabela de frequências cujas proporções somam bem mais que 100% é outra história. Significa que
algumas observações foram contadas em mais de uma categoria, o que quebra a primeira das duas regras da
seção sobre variáveis categóricas. Descubra o motivo antes que alguém leia a tabela.

## Duas variáveis categóricas ao mesmo tempo

Conte por duas variáveis juntas e você obtém uma **tabela de contingência**, com uma variável nas
linhas e a outra nas colunas:

| | pix | cartão | dinheiro | total |
|---|---|---|---|---|
| Cambuí | 3 | 0 | 1 | 4 |
| Taquaral | 1 | 2 | 0 | 3 |
| Barão Geraldo | 1 | 1 | 0 | 2 |
| Centro | 1 | 1 | 1 | 3 |
| **total** | **6** | **4** | **2** | **12** |

As margens trazem a tabela de frequências de cada variável sozinha, e as células trazem as combinações.
**Três dos quatro pedidos do Cambuí foram pagos por pix**, contra um dos três do Taquaral.

Com doze pedidos, essa diferença é três contra um e significa muito pouco. Com doze mil, o mesmo padrão
poderia ser um fato sobre como dois bairros pagam. Separar esses dois casos é exatamente o que um teste
de hipótese faz, e a aula 16 roda o teste qui-quadrado numa tabela com o formato desta.
