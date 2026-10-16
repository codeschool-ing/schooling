---
title: Uma métrica primária
version: 1
---

**Um teste é decidido por um número, escolhido antes de ele começar.** Esse número é a **métrica
primária**. Olhar dez números e escolher o que se mexeu é o jeito mais comum de um teste produzir
um resultado que não se repete, pelo motivo que a aula 11 mede.

Uma boa métrica primária tem quatro propriedades, e elas puxam umas contra as outras.

| propriedade | a pergunta | o teste de checkout da Panela |
|---|---|---|
| **relevante** | se ela se mexer, o negócio se importa? | um primeiro pedido é receita e um cliente |
| **sensível** | a mudança consegue mexê-la durante o teste? | o checkout é onde o pedido é feito, então sim |
| **atribuível** | ela é medida na unidade que foi sorteada? | sorteio por visitante, medida por visitante |
| **a tempo** | ela chega dentro das semanas do teste? | o pedido é feito na mesma visita |

Então a métrica primária é **a conversão: a fração de visitantes que fazem um primeiro pedido**,
contada por visitante.

## Por que não receita, ou retenção

Receita por visitante é mais relevante e bem menos sensível: ela carrega o tamanho de cada caixa e
cada desconto, então o ruído dela é muito maior e o teste precisaria de muito mais visitantes para
ver a mesma mudança. Retenção depois de três meses é a mais relevante de todas, e chega três meses
tarde demais para um teste de algumas semanas. As duas são boas **métricas secundárias**:
informadas, não usadas para decidir.

O puxa-puxa entre relevante e sensível é permanente. A resposta de sempre é uma métrica primária
sensível com uma ligação bem entendida com a relevante, aqui que um primeiro pedido leva, em média,
às coortes das aulas 12 e 13.

## A unidade de análise

**A métrica é contada na mesma unidade que o teste sorteou.** A Panela sorteia visitantes, então a
conversão é pedidos divididos por visitantes, cada visitante contado uma vez. Contar sessões no
lugar, com um visitante que voltou três vezes contado três vezes, faz as observações dos grupos
dependerem umas das outras e deixa a aritmética da aula 10 errada. A aula 9 volta a isso, porque
escolher a unidade também decide como o teste pode ser contaminado.
