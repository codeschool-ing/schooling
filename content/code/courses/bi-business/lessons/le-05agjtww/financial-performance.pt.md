---
title: Desempenho financeiro: o que uma financeira ganha
version: 1
---

Um varejista ganha a diferença entre o preço de venda das mercadorias e o custo delas. Uma financeira
vende dinheiro, e **o resultado dela é uma corrente de quatro subtrações**: os juros que ganha nos
empréstimos, menos o que paga pelo dinheiro que empresta, menos os empréstimos que não voltam, menos o
custo de manter a empresa funcionando. Cada subtração tem uma razão, e as três razões são a primeira
coisa que alguém olha numa financeira.

## Os dois anos da Ipê, na sua planilha

Os números da Ipê de 2024 e 2025 em milhões de reais. A carteira é o valor médio emprestado durante o
ano, empréstimo pessoal e saldo do cartão juntos. Digite numa aba nova a partir de A1:

| | A | B | C |
|---|---|---|---|
| 1 | Linha | 2024 | 2025 |
| 2 | Carteira média | 640 | 820 |
| 3 | Receita de juros | 236 | 291 |
| 4 | Receita de tarifas | 30 | 36 |
| 5 | Custo de captação | 77 | 98 |
| 6 | Perdas de crédito | 45 | 74 |
| 7 | Custos operacionais | 64 | 72 |

O custo de captação é o que a Ipê paga para tomar emprestado o dinheiro que empresta, a bancos e a
investidores. As perdas de crédito são o que os empréstimos ruins do ano custaram, como a contabilidade
os registra. A receita de tarifas é, na maior parte, tarifa do cartão.

## A corrente

Em A8 digite `Margem financeira`, e em B8 os juros ganhos menos o custo de captá-los:

```localised
=B3-B5      159
```

Em A9 `Receita total`, e em B9 a margem financeira mais as tarifas:

```localised
=B8+B4      189
```

Em A10 `Lucro antes dos impostos`, e em B10 a receita total menos os dois custos:

```localised
=B9-B6-B7      80
```

Copie B8:B10 para C8:C10. **Sua coluna de 2025 deve mostrar 193, 229 e 83.**

## As três razões

Cada razão divide um elo da corrente por alguma coisa, e cada uma responde a uma pergunta.

**Margem financeira líquida** (NIM, na sigla em inglês) — quanto o crédito em si rende, por real
emprestado:

```localised
=ARRED(B8/B2*100;1)      24,8
```

**Custo do risco** — quanto da carteira se perdeu em empréstimos que não voltaram:

```localised
=ARRED(B6/B2*100;1)      7
```

**Índice de eficiência** — quantos reais de custo operacional são necessários para ganhar cem reais de
receita. Quanto menor, melhor, o que surpreende na primeira vez:

```localised
=ARRED(B7/B9*100;1)      33,9
```

Ponha nas linhas 11 a 13 e copie cada uma para a coluna C:

| razão | 2024 | 2025 |
|---|---|---|
| margem financeira líquida | 24,8% | 23,5% |
| custo do risco | 7,0% | 9,0% |
| índice de eficiência | 33,9% | 31,4% |

Margens desse tamanho são do crédito ao consumidor no Brasil, onde as taxas do empréstimo pessoal são
altas; um banco que empresta a empresas trabalha com uma fração delas. A comparação que importa é a Ipê
contra ela mesma.

## O que o ano diz

A apresentação de 2025 ao conselho abriu com crescimento. A carteira cresceu 28,1% e a receita total
21,2%, e o índice de eficiência melhorou de 33,9% para 31,4%: a Ipê ganha cada real de receita com menos
estrutura que um ano antes. Tudo verdade.

**O lucro antes dos impostos cresceu 3,8%.** Entre a receita e o lucro está o custo do risco, que foi de
7,0% da carteira para 9,0%. As perdas de crédito subiram 64,4%, mais que o dobro do ritmo da carteira.
Se as perdas tivessem ficado na proporção de 2024, a Ipê teria perdido R$ 16 milhões a menos com
empréstimos ruins em 2025.

Duas leituras são possíveis, e o resultado do ano não escolhe entre elas. Ou a Ipê está emprestando a
pessoas mais arriscadas do que antes, ou os empréstimos mais novos simplesmente chegaram à idade em que
empréstimos dão errado. **A resposta não está nos totais do ano; está nos empréstimos agrupados por
quando foram feitos**, que é a próxima seção.
