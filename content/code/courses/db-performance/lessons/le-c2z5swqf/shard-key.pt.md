---
title: A chave de shard, que se escolhe uma vez
version: 1
---

Toda tabela dividida em shards tem uma **chave de shard**: a coluna cujo valor decide em qual
servidor uma linha mora. Todas as outras decisões desta aula podem ser revistas depois, com algum
custo. Esta é quase permanente, porque trocá-la significa mudar quase toda linha de servidor,
enquanto a aplicação continua rodando.

O jeito tentador de escolher é olhar os dados e perguntar qual coluna os divide por igual. Isso é
metade da pergunta. A outra metade é **por qual coluna as consultas perguntam**, e quando as duas
metades discordam, as consultas ganham.

## O que uma boa chave faz

Uma consulta que cita um valor da chave de shard vai para **um** servidor. Uma consulta que não a
cita vai para **todos**, espera o mais lento e junta as respostas. Então a chave deve ser a coluna
pela qual a maior parte do tráfego já filtra, e deve dividir por igual tanto as linhas quanto o
trabalho, sem nenhum valor grande o bastante para encher um servidor sozinho.

No `market` há duas candidatas. As telas de um vendedor leem por `seller_id`. As de um cliente leem
por `customer_id`. As duas são plausíveis, as duas são chaves estrangeiras que todo pedido carrega,
e se comportam de jeitos bem diferentes.

## O vendedor 1 é um quarto de tudo

Pergunte como os pedidos se distribuem entre vendedores, e depois o que quatro shards divididos por
vendedor guardariam. O `% 4` faz o papel da função de roteamento de verdade; um hash espalharia os
outros vendedores de outro jeito, e nenhuma função consegue dividir um vendedor entre dois shards:

```
market=# SELECT seller_id, count(*), round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct FROM orders GROUP BY seller_id ORDER BY count(*) DESC LIMIT 3;
 seller_id | count  | pct  
-----------+--------+------
         1 | 500114 | 25.0
       178 |   1648 |  0.1
       480 |   1630 |  0.1
(3 rows)

Time: 100.275 ms

market=# SELECT seller_id % 4 AS shard, count(*), round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct FROM orders GROUP BY 1 ORDER BY 1;
 shard | count  | pct  
-------+--------+------
     0 | 374915 | 18.7
     1 | 873427 | 43.7
     2 | 375683 | 18.8
     3 | 375975 | 18.8
(4 rows)

Time: 150.905 ms
```

**O vendedor 1 tem 500114 pedidos, exatamente 25,0% da tabela**, e o segundo maior tem 1648. É a
loja própria do marketplace, e todo marketplace tem uma: a marca grande, o rótulo da casa, a conta
que é um terço do faturamento. Dividido por vendedor, o shard que guarda o vendedor 1 fica com
**43,7%** de todos os pedidos, os 25% do vendedor 1 mais a sua quarta parte de todos os outros,
contra 18,7% em cada um dos demais. Esse é o **shard quente**: recebe mais que o dobro das escritas
de qualquer outro, o disco dele enche primeiro, e é ele que acorda alguém de madrugada. Pôr mais
shards não ajuda, porque o vendedor 1 continua num só deles, quantos forem. Com cem shards, um deles
ainda guarda um quarto dos pedidos.

Agora a mesma divisão por cliente:

```
market=# SELECT customer_id % 4 AS shard, count(*), round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct FROM orders GROUP BY 1 ORDER BY 1;
 shard | count  | pct  
-------+--------+------
     0 | 500615 | 25.0
     1 | 498862 | 24.9
     2 | 500759 | 25.0
     3 | 499764 | 25.0
(4 rows)

Time: 193.114 ms

market=# SELECT max(n) AS busiest_customer FROM (SELECT count(*) AS n FROM orders GROUP BY customer_id) AS per_customer;
 busiest_customer 
------------------
               27
(1 row)

Time: 219.365 ms
```

**25,0, 24,9, 25,0 e 25,0 por cento.** Duzentos mil clientes, e o que mais compra tem 27 pedidos.
Nenhum cliente é grande o bastante para desequilibrar nada, e nenhum vai ser: uma pessoa só consegue
comprar até certo ponto.

## Quais consultas ficam num shard só

Distribuição igual é necessária, não suficiente. A carga da aula 2 diz o que a aplicação pergunta,
e com que frequência:

| script | fatia | filtra por | dividido por cliente | dividido por vendedor |
|---|---|---|---|---|
| `customer-orders.sql` | 50% | `customer_id` | um shard | todos os shards |
| `order-page.sql` | 25% | `order_id` | veja abaixo | veja abaixo |
| `place-order.sql` | 10% | grava um pedido | um shard | um shard |
| `seller-dashboard.sql` | 4% | `seller_id` | todos os shards | um shard |
| `pending-count.sql` | 1% | nada | todos os shards | todos os shards |

Dividido por cliente, metade do tráfego mais todas as escritas ficam num shard só. Dividido por
vendedor, fica o painel, com 4%, e a lista de pedidos do cliente se espalha por todos os servidores
a cada visita à página. **`customer_id` é a chave**, pelos dados e pelas consultas. O painel do
vendedor vira a consulta que paga: a seção 04 mede quanto.

A página do pedido é a linha que ensina. Ela lê `order_lines` por `order_id`, e `order_id` não é a
chave de shard. Para mantê-la num shard só, `order_lines` precisa morar no mesmo shard que o seu
pedido, ou seja, `order_lines` também é dividida **pelo cliente do pedido**: a coluna precisa estar
na tabela, ou o roteador precisa procurar o pedido antes. Isso se chama **colocalização**: tabelas
que são unidas em join são divididas pela mesma chave, para que o join aconteça dentro de um
servidor. `products` e `sellers` são o caso oposto, pequenas e lidas por todo mundo, e a resposta
de costume é copiá-las inteiras para cada shard, uma **tabela de referência**, aceitando que uma
mudança num produto agora é uma escrita em todos os servidores.

## Três jeitos de rotear

Alguma coisa precisa transformar uma chave num servidor. O roteamento por **hash**, usado na seção
04, calcula um hash da chave e tira o resto pelo número de shards: uniforme, e cego ao que os
valores significam. O roteamento por **faixa** dá a cada shard uma faixa de chaves, clientes de 1 a
100000 aqui e o resto ali, o que mantém vizinhos juntos e deixa uma faixa esquentar quando todos os
clientes novos ganham ids altos. Um **diretório** é uma tabela que diz, chave por chave, qual shard a
guarda. É o mais flexível, já que um único cliente pode ser movido atualizando uma linha, e custa
uma consulta a mais em toda requisição, a uma tabela que agora é a coisa mais importante do sistema.

Nenhum deles salva uma chave ruim. Se a chave é `seller_id`, o shard quente existe nos três, porque
o problema é um valor e não a função.
