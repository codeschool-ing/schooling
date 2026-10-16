---
title: Finanças: a demonstração de resultado, e por que lucro não é caixa
version: 1
---

Finanças é onde os números de todas as outras áreas terminam, então é a área que um analista de BI
precisa entender primeiro. O documento central dela é a **demonstração de resultado**: vendas em cima,
custos descontados numa ordem fixa, lucro embaixo. **Cada linha responde a uma pergunta diferente, e as
margens entre elas são os números que um conselho de fato lê.** A da Varanda em 2025 é pequena o
bastante para digitar.

## O 2025 da Varanda, simplificado

Acrescente uma aba e digite as linhas em milhares de reais. Ela é simplificada de propósito: as vendas
são contadas depois dos impostos que incidem sobre elas, e os custos abaixo do lucro operacional —
juros, imposto de renda — ficam de fora, porque pertencem mais ao mundo de Otávio que ao de um
analista.

| | A | B |
|---|---|---|
| 1 | Linha | R$ mil |
| 2 | Vendas | 98000 |
| 3 | Custo das mercadorias vendidas | 55370 |
| 4 | Lucro bruto | |
| 5 | Pessoal | 18750 |
| 6 | Lojas e aluguel | 9800 |
| 7 | Marketing | 4410 |
| 8 | Depósito e entregas | 3920 |
| 9 | Outras | 2890 |
| 10 | Despesas operacionais | |
| 11 | Lucro operacional | |

As três células vazias são fórmulas:

```localised
B4    =B2-B3          42630
B10   =SOMA(B5:B9)    39770
B11   =B4-B10         2860
```

O **custo das mercadorias vendidas** é o que a Varanda pagou aos fornecedores pelo que vendeu no ano —
não por tudo que comprou, já que o que ainda está no depósito não foi vendido. O **lucro bruto** é o
que a venda rendeu antes de pagar o funcionamento da empresa. As **despesas operacionais** são o custo
desse funcionamento: pessoas, lojas, marketing, logística. O **lucro operacional** é o que sobra.

## Margens: cada linha como parcela das vendas

Uma linha sozinha diz pouco; os mesmos R$ 2,86 milhões seriam um ótimo ano para uma loja pequena e um
desastre para uma grande. Dividir pelas vendas torna as linhas comparáveis entre anos e entre empresas.
Em C1 digite `Margem %`, e:

```localised
C4    =ARRED(B4/B2*100;1)     43,5
C11   =ARRED(B11/B2*100;1)    2,9
```

**Uma margem bruta de 43,5% e uma margem operacional de 2,9%.** Lidas juntas, dizem que a Varanda
compra bem — de cada R$ 100 de vendas, sobram R$ 43,50 depois de pagar as mercadorias — e que manter
nove lojas, um depósito e uma loja online consome quase tudo isso. As duas maiores linhas operacionais,
pessoal com 19,1% das vendas e lojas e aluguel com 10,0%, são onde um diretor financeiro olha primeiro
quando a margem operacional cai.

## Lucro não é caixa

A demonstração de resultado registra a venda quando ela acontece, não quando o dinheiro chega. Essa
diferença é uma das leituras erradas mais comuns de uma empresa lucrativa.

Em dezembro, uma cliente compra um sofá de R$ 6.000 em dez parcelas sem juros no cartão, o que é
comum no varejo de móveis no Brasil. **Os R$ 6.000 inteiros são venda de dezembro, e a margem deles é
lucro de dezembro.** O dinheiro chega a R$ 600 por mês nos dez meses seguintes:

```localised
=6000/10      600
```

Agora multiplique isso por toda venda parcelada de um bom dezembro. **A demonstração de resultado
mostra um mês recorde enquanto a conta bancária enche devagar**, e enquanto isso os fornecedores que
mandaram o estoque de Natal em outubro querem receber. O varejista pode pedir às empresas de cartão que
antecipem as parcelas, mediante uma taxa, e essa taxa é um custo de vender parcelado que o número de
vendas não mostra.

Por isso finanças acompanha o caixa separado do lucro, num demonstrativo de fluxo de caixa e numa
previsão do saldo bancário semana a semana. **Um analista a quem finanças pergunta "como fomos?" deve
perguntar "em lucro ou em caixa?"** — as duas respostas diferem todo mês, e mais que nunca em dezembro.
