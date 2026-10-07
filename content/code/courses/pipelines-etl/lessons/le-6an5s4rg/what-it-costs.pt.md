---
title: Quanto uma carga custa, e o que fazer a respeito
version: 1
---

As quatro medições, lado a lado, com o fator entre os métodos nesta máquina:

| decisão | jeito lento | jeito rápido | fator |
| --- | --- | --- | --- |
| escrever linhas | um `INSERT` por linha | `COPY` | cerca de 60 |
| achar um dia | ler a tabela inteira | um índice na data | cerca de 650 |
| atualizar a tabela | refazê-la inteira | trocar uma janela de 30 dias | cerca de 75 |
| responder por um mês | ler seis anos | ler o mês | cerca de 120, em páginas lidas |

Nenhuma delas precisou de uma máquina mais rápida, de outro banco ou de um cluster. Cada uma é uma
decisão sobre **quanto trabalho pedir**. Cada uma também foi tomada em algum ponto deste curso por um
motivo que não era velocidade: o `COPY` porque o carregador do raw tinha de ser uma transação, a janela
porque a tabela derivava, o mart porque relatórios não devem fazer join de tabelas fato. Desempenho
vem quase sempre de não fazer trabalho, e o trabalho que mais vale não fazer é o que um desenho pede
sem que ninguém perceba.

A ordem para atacar um pipeline lento ou caro é a ordem desta lição. **Medir** primeiro, com `\timing`
e `EXPLAIN ANALYZE`, e acreditar na medição mais que na intuição. Depois **escrever em lote**, **achar
por um índice**, **refazer só o que mudou** e **ler só o que é preciso** — e medir de novo, porque cada
correção leva o gargalo para outro lugar. Hardware maior vem depois disso, se vier.

E toda economia tem um preço que as lições anteriores já nomearam. Um índice deixa mais lenta a carga
que enche a tabela. Uma janela perde o que cai fora dela. Um mart é mais uma coisa para manter certa.
**Faça a troca de propósito, com os números na frente**, e escreva o motivo onde a próxima pessoa vai
olhar: no modelo, ao lado da configuração que ele explica.
