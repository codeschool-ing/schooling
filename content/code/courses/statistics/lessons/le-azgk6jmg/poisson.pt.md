---
title: A distribuição de Poisson
version: 1
---

A Horta recebe em média 2,4 reclamações por dia. Elas não chegam com hora marcada; cada uma é um evento
independente, e o dia não tem um número fixo de "tentativas". Quão provável é um dia sem nenhuma
reclamação? E com cinco ou mais?

A **distribuição de Poisson** modela contagens de eventos que acontecem **ao acaso, de forma
independente, a uma taxa média constante**: reclamações por dia, pedidos por minuto, erros de digitação
por página, acidentes por mês num cruzamento. Ela tem um único parâmetro, a taxa média **λ** (a letra
grega lambda), e leva o nome do matemático francês Siméon Denis Poisson.

## A fórmula

A probabilidade de exatamente *k* eventos, quando a média é λ, é

```localised
P(X = k) = e^(−taxa) × taxa^k ÷ k!
```

em que a taxa é λ, *e* é a constante 2,71828… e *k*! é "*k* fatorial", 1 × 2 × … × *k*, com 0! = 1.

Para λ = 2,4:

| reclamações | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|---|
| probabilidade | 0,091 | 0,218 | 0,261 | 0,209 | 0,125 | 0,060 | 0,024 | 0,008 |

Um dia **sem reclamações** tem probabilidade e^(−2,4) = **0,0907**, cerca de um dia em onze. Um dia com
**cinco ou mais** tem probabilidade 0,0959, cerca de um dia em dez.

```localised
=DIST.POISSON(0; 2,4; FALSO)              0,0907179532894125
=1 - DIST.POISSON(4; 2,4; VERDADEIRO)     0,0958685903363992
```

## A média é igual à variância

A média de uma distribuição de Poisson é λ, e a **variância** também. Isso dá uma conferência rápida para
saber se dados de contagem podem ser Poisson: calcule a média e a variância e veja se estão perto.

Os últimos 60 dias de reclamações da Horta têm média 2,18 e variância 1,85. Perto o bastante para ser
plausível. Uma variância muito acima da média — chamada **superdispersão** — diria que os eventos não
são independentes: reclamações chegando em rajadas, digamos, porque um lote ruim de morangos irrita vinte
clientes de uma vez.

## A taxa acompanha o intervalo

A taxa pertence a um intervalo, e muda com ele. 2,4 reclamações por dia são 16,8 por semana, e a chance de
uma semana inteira sem nenhuma reclamação é e^(−16,8), cerca de 5 em 100 milhões. A binomial precisava de
um número de tentativas; a Poisson precisa só de uma taxa e de um intervalo, e por isso serve para eventos
que podem acontecer a qualquer momento.
