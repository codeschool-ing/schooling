---
title: Pessoas: quadro, rotatividade e absenteísmo
version: 1
---

As pessoas são o maior custo da Varanda depois das próprias mercadorias: R$ 18,75 milhões em 2025, 19,1%
das vendas. **Recursos humanos mede a equipe do jeito que operações mede o estoque — quantas pessoas,
quanto tempo ficam, quanto do tempo delas se perde — e cada um desses números é sobre indivíduos com
nome.** Esse segundo fato muda o jeito como o analista lida com eles, e ele vem no fim desta seção.

## Quadro de pessoal, e o problema do denominador

O quadro de pessoal é o número de pessoas empregadas, e a primeira pergunta é: em que dia? O varejo
contrata para o Natal e dispensa temporários em janeiro, então uma contagem em 31 de dezembro e outra
em 31 de janeiro diferem. **Para taxas ao longo de um ano, o RH usa o quadro médio**, a média das doze
contagens de fim de mês. O quadro médio da Varanda em 2025 foi de 410 pessoas.

## Rotatividade

A rotatividade é a parcela da equipe que saiu. Em 2025, 103 pessoas saíram da Varanda, por qualquer
motivo:

```localised
=ARRED(103/410*100;1)      25,1
=ARRED(103/410/12*100;1)    2,1
```

**25,1% ao ano, ou 2,1% ao mês em média.** Um quarto das pessoas que trabalham na Varanda num dia
qualquer não vai estar lá um ano depois. No varejo isso não é raro, e o número importa menos que a
direção e a quebra dele: rotatividade concentrada numa loja, ou entre pessoas nos três primeiros
meses, aponta para um gerente ou para a contratação, e o total da empresa esconde as duas coisas.

Dois avisos. Primeiro, **há mais de uma fórmula.** Algumas empresas contam só os desligamentos; outras
tiram a média de admissões e desligamentos antes de dividir; algumas deixam de fora os demitidos, ou
quem saiu nas primeiras semanas. Cada uma dá uma taxa diferente para a mesma equipe, e comparar os
25,1% da Varanda com o número de um relatório que usou outra fórmula não compara nada. Segundo, a
rotatividade mensal vezes doze é só aproximadamente a anual, e num mês com muitos contratos
temporários terminando ela fica bem longe.

## Absenteísmo e tempo de contratação

O **absenteísmo** é a parcela das horas previstas que se perdeu em ausências. A Varanda previu 870.000
horas de trabalho em 2025 e perdeu 23.500 em ausências não planejadas:

```localised
=ARRED(23500/870000*100;1)      2,7
```

2,7%. O **tempo de contratação** é o número de dias entre abrir uma vaga e o primeiro dia da pessoa; a
equipe de Sônia registrou uma mediana de 34 dias em 2025. Uma loja que perde um vendedor em outubro e
espera 34 dias pelo próximo começa dezembro desfalcada, e é assim que um número de RH vira um número de
vendas.

## Dado de RH é dado pessoal

Cada linha por trás dessas taxas é uma pessoa: o salário, as faltas, por que saiu. Uma taxa de
rotatividade da empresa é inofensiva. **Uma tabela de rotatividade de uma loja com oito funcionários,
aberta por mês, pode identificar quem saiu e quando**, e um relatório de faltas por nome é informação
médica e disciplinar. Pela LGPD, dado de saúde é dado pessoal sensível, com regras ainda mais rígidas.

Então a regra do analista de BI da aula 4 vale com mais força: mostrar o que o leitor precisa e nada
mais, agregar antes de mostrar, e não publicar uma quebra pequena o bastante para apontar alguém. A aula
6 de `data-governance` trata de como dados pessoais e sensíveis são tratados, e a aula 7, da própria
LGPD.
