---
title: A pergunta que um esquema não responde
version: 1
---

O modelo de Ana tem doze tabelas e 92 colunas, cada uma com nome e tipo. `net_cents BIGINT` diz que a coluna guarda
um número inteiro e que alguém pensou nela como centavos. Não diz se o frete está dentro, se os descontos foram
tirados, se um pedido cancelado conta, nem a que dia uma venda pertence. Essas são as perguntas que as pessoas de fato
fazem, e **o esquema não responde a nenhuma delas**.

A lição 11 mostrou quanto isso custa. Três marts, três sentidos de "receita", uma reunião que gastou a hora discutindo
qual número estava certo, e um defeito, as vendas de todas as lojas faltando no número do marketing, que ninguém tinha
visto porque ninguém tinha comparado as definições. Cada definição estava na cabeça de alguém, ou num SQL que só o
autor lia.

O remédio é antigo e sem glamour: **escrever o que cada coluna significa, ao lado da coluna, e manter isso
verdadeiro**. A lista escrita se chama **dicionário de dados** ou dicionário de campos. Na escala de um warehouse, é
um documento; na escala de uma empresa, vira um **catálogo de dados**, um serviço pesquisável sobre todo conjunto de
dados, com donos e linhagem. Esta lição constrói o primeiro e mostra como ele cresce até virar o segundo.

O dicionário é também onde se encontram duas obrigações que parecem não ter relação. Uma é analítica: um número que
ninguém consegue explicar é um número com base no qual ninguém deveria agir. A outra é legal: a lei brasileira de
proteção de dados pede que a empresa saiba quais dados pessoais tem e onde, e **um dicionário que classifica cada
coluna é o lugar onde essa resposta mora**. As seções 9 e 10 chegam lá.
