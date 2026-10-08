---
title: O que o expurgo guarda
version: 1
---

Apagar 950 pedidos perde algo que o negócio quer: quanto foi vendido, do quê, e quando. O artigo 16,
IV da LGPD permite guardar dados depois que a finalidade acaba **para uso exclusivo do controlador,
vedado o acesso por terceiro, e desde que anonimizados**. Então, antes de os pedidos saírem, o expurgo
escreve o que eles dizem sobre vendas numa tabela que não diz nada sobre ninguém:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT count(*) AS orders_kept_by_the_hold FROM sales.orders WHERE customer_id = 4407 AND ordered_at < DATE '2021-01-01'" -c "SELECT * FROM gov.sales_monthly WHERE month = DATE '2020-03-01' ORDER BY category"
SET
 orders_kept_by_the_hold 
-------------------------
                      13
(1 row)

   month    |    category    | orders | units | revenue_cts 
------------+----------------+--------+-------+-------------
 2020-03-01 | analgesic      |      4 |     4 |        6060
 2020-03-01 | antibiotic     |      7 |     8 |       25920
 2020-03-01 | baby           |      2 |     2 |        9980
 2020-03-01 | cardiovascular |      8 |     9 |       15810
 2020-03-01 | contraceptive  |      1 |     2 |        4980
 2020-03-01 | diabetes       |      8 |    10 |       36900
 2020-03-01 | diagnostic     |      2 |     3 |        5970
 2020-03-01 | first aid      |     12 |    14 |       18760
 2020-03-01 | neurology      |      1 |     1 |        3190
 2020-03-01 | personal care  |      9 |     9 |       20610
 2020-03-01 | psychiatric    |      5 |     7 |       25030
 2020-03-01 | supplement     |      5 |     5 |       24050
 2020-03-01 | thyroid        |      1 |     1 |        1690
(13 rows)
```

O último resultado acima é março de 2020: treze categorias de produto, quantos pedidos, quantas
unidades, quanto de receita. Nenhum cliente, nenhum número de pedido, nenhum dia mais fino que o mês,
nenhum estado. Ela é classificada como `none` no `gov.column_class`, com o motivo, para a verificação
de classificação da aula 6 concordar que ela não guarda nada sobre uma pessoa.

## Ela é anônima mesmo?

A pergunta da aula 5 vale aqui, e a resposta honesta tem duas partes.

**Dentro da Ipê, sim.** Não há coluna que ligue uma linha de volta a alguém, e os pedidos de que ela
veio não existem mais. Ninguém na Ipê consegue perguntar "quem comprou o único anticoncepcional de
março de 2020?", porque não sobrou registro que possa responder.

**Publicada, ela pediria outra olhada.** Três linhas de março de 2020 contam **um** pedido. Uma célula
de um não é dado pessoal por si só, mas, somada a conhecimento de fora — uma cidade pequena, um cliente
conhecido —, uma contagem de um pode dizer algo sobre uma pessoa. A regra da aula 5 era suprimir ou
juntar células pequenas antes de o dado sair da empresa. A tabela serve para o uso da própria Ipê, que
é o que o artigo 16, IV permite; um relatório feito a partir dela para qualquer outra pessoa aplicaria
a regra antes.

## O movimento geral

**Agregar, depois apagar** é o padrão para a maior parte do histórico que um negócio quer guardar: as
estatísticas sobrevivem e as pessoas saem delas. É o mesmo desenho da plataforma em que você estuda,
em que eliminar uma pessoa apaga as linhas que dão significado aos identificadores dela e deixa as
contagens intactas.
