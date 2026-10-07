---
title: Medir a qualidade dos alertas
version: 1
---

A qualidade de uma regra se mede com o desfecho de cada alerta, registrado pelo analista que o fechou:
**verdadeiro positivo** (era o que a regra disse), **falso positivo** (não era) e, descoberto depois e com
dor, **falso negativo** (algo aconteceu e nenhum alerta disparou).

A aula 4 dá duas regras sobre a mesma semana, e os desfechos são conhecidos:

| regra | alertas | verdadeiros | falsos | precisão |
|---|---|---|---|---|
| v1, falha e depois sucesso | 5 | 2 | 3 | 2 / 5 = **40%** |
| v2, muitas contas e depois sucesso | 2 | 2 | 0 | 2 / 2 = **100%** |

**Precisão** é a fração dos alertas de uma regra que eram verdadeiros. É o que sente quem lê a fila: a 40%,
mais da metade do trabalho com aquela regra é desperdiçado. Uma regra que fica abaixo de, digamos, 20% por
um mês é uma regra para reescrever ou aposentar, e a decisão deve ser escrita com os números dela.

A precisão tem um lado cego: ignora o que a regra deixou passar. Uma regra que nunca dispara não tem falsos
positivos. É por isso que um SOC também conta, por incidente, **qual regra o pegou, ou que nenhuma pegou**;
os incidentes de um trimestre descobertos por um telefonema de cliente e não por um alerta são o número
mais importante que a equipe tem, e a aula 15 o põe em toda revisão.

Mais dois números mantêm uma fila saudável: **alertas por analista por turno**, que diz se as pessoas
conseguem ler o que recebem, e **a fração fechada sem ser aberta**, que diz se elas já pararam.
