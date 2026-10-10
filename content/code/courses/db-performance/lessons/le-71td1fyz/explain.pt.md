---
title: O que o EXPLAIN mostra, e o que ele não faz
version: 1
---

A aula 10 de `sql-databases` apresentou o `EXPLAIN`: ponha-o na frente de uma consulta e o
PostgreSQL **planeja a consulta sem executá-la** e imprime o plano, uma árvore de passos chamados
nós, cada um com a previsão do planejador ao lado. Esta seção recapitula isso numa página, com a
consulta que a carga de trabalho da aula 2 mais envia, e depois acrescenta a parte que aquela aula
deixou de lado: por que todo custo são dois números, e para que serve o primeiro.

A crença a largar primeiro é a de que o `EXPLAIN` diz quanto tempo uma consulta leva. Ele diz o
que o planejador **espera**, numa unidade própria, e nada rodou quando ele responde.

## Os dez últimos pedidos de um cliente

Metade do tráfego da aula 2 era esta consulta, a tela "meus pedidos". Abra o `psql market` e peça
o plano dela, para o cliente 4242:

```
market=# EXPLAIN SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
                                            QUERY PLAN                                            
--------------------------------------------------------------------------------------------------
 Limit  (cost=47.99..48.02 rows=10 width=29)
   ->  Sort  (cost=47.99..48.02 rows=11 width=29)
         Sort Key: placed_at DESC
         ->  Bitmap Heap Scan on orders  (cost=4.51..47.80 rows=11 width=29)
               Recheck Cond: (customer_id = 4242)
               ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0)
                     Index Cond: (customer_id = 4242)
(7 rows)

Time: 2.787 ms
```

Sete linhas, quatro nós. Um nó é a linha que começa com um nome — `Limit`, `Sort`,
`Bitmap Heap Scan`, `Bitmap Index Scan` — e cada `->` pendura um nó embaixo do que está acima. As
linhas recuadas sem seta são detalhes do nó logo acima delas: a chave pela qual ele ordena, a
condição que ele aplica. Como ler a ordem dos quatro é assunto da próxima seção; aqui, leia uma
linha de ponta a ponta.

```
Bitmap Heap Scan on orders  (cost=4.51..47.80 rows=11 width=29)
```

**`rows=11` é quantas linhas o nó espera passar para cima**, para o nó acima dele, e não quantas
ele lê. O planejador acha que o cliente 4242 tem uns onze pedidos, a partir de estatísticas que
mantém sobre a coluna; as aulas 6 e 7 tratam de onde vem esse número e do que acontece quando ele
está errado.

**`width=29` é o tamanho médio de uma dessas linhas, em bytes.** Foram pedidas quatro colunas,
então 29. O `Bitmap Index Scan` abaixo diz `width=0`, porque não passa linha nenhuma: entrega ao pai
uma lista de páginas a visitar, e a aula 4 desmonta isso. A largura importa onde quer que linhas
tenham de ficar na memória, numa ordenação ou num hash, e é por isso que um `SELECT *` custa mais
do que as quatro colunas que uma tela mostra.

**`cost=4.51..47.80` são dois números, e nenhum deles é tempo.** Estão na unidade do próprio
planejador, que a última seção desta aula calcula à mão. O planejador põe preço em todo plano que
consegue imaginar e fica com o mais barato, então o custo é o motivo de o plano que você está lendo
ter sido o escolhido.

## O `EXPLAIN` sozinho não executa nada

Isso inclui comandos que alteram dados. Peça o plano de um delete e depois conte o que ele teria
apagado:

```
market=# EXPLAIN DELETE FROM order_lines WHERE order_id = 7;
                                        QUERY PLAN                                         
-------------------------------------------------------------------------------------------
 Delete on order_lines  (cost=0.43..11.98 rows=0 width=0)
   ->  Index Scan using order_lines_pkey on order_lines  (cost=0.43..11.98 rows=3 width=6)
         Index Cond: (order_id = 7)
(3 rows)

Time: 1.841 ms

market=# SELECT count(*) FROM order_lines WHERE order_id = 7;
 count 
-------
     4
(1 row)

Time: 0.878 ms
```

Um plano para apagar as linhas do pedido 7, e as quatro linhas continuam lá. É isso que torna o
`EXPLAIN` puro seguro de digitar num servidor de produção, e é exatamente a propriedade que a
palavra `ANALYZE` tira, duas seções adiante.

## Custo inicial e custo total

**O primeiro número é quanto o nó custa antes de conseguir entregar a primeira linha; o segundo é
quanto custa entregar todas.** Na maioria dos nós os dois ficam longe um do outro, e a distância é
justamente o ponto. Duas consultas que querem os dez pedidos mais antigos e os dez mais baratos
mostram isso. A primeira linha abaixo desliga os planos paralelos nesta sessão do `psql`, para que
cada plano seja uma árvore simples; a aula 4 explica a versão paralela, e fechar o `psql` desfaz o
ajuste:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.441 ms

market=# EXPLAIN SELECT id, placed_at, total_cents FROM orders ORDER BY placed_at LIMIT 10;
                                             QUERY PLAN                                             
----------------------------------------------------------------------------------------------------
 Limit  (cost=0.43..0.77 rows=10 width=20)
   ->  Index Scan using orders_placed_at_idx on orders  (cost=0.43..68618.43 rows=2000000 width=20)
(2 rows)

Time: 1.928 ms

market=# EXPLAIN SELECT id, placed_at, total_cents FROM orders ORDER BY total_cents LIMIT 10;
                                 QUERY PLAN                                  
-----------------------------------------------------------------------------
 Limit  (cost=79886.28..79886.31 rows=10 width=20)
   ->  Sort  (cost=79886.28..84886.28 rows=2000000 width=20)
         Sort Key: total_cents
         ->  Seq Scan on orders  (cost=0.00..36667.00 rows=2000000 width=20)
(4 rows)

Time: 0.716 ms
```

O primeiro plano percorre o índice em `placed_at` desde o começo. Essa varredura do índice, levada
até o fim, devolveria os dois milhões de pedidos a um custo total de `68618.43`. Mas o custo inicial
dela é `0.43` — a primeira linha sai quase de imediato, porque o índice já está na ordem que a
consulta quer — e o `Limit` acima para de pedir depois de dez. Então o planejador cobra do `Limit`
dez dois-milionésimos da varredura: `0.43 + (68618.43 − 0.43) × 10 / 2000000`, que é o `0.77` da
linha dele.

O segundo plano não tem índice em `total_cents` para percorrer, então lê todos os pedidos e
ordena. **Uma ordenação não consegue entregar a primeira linha antes de ter visto a última**,
porque a última linha lida pode ser a mais barata de todas. Assim o `Sort` tem custo inicial de
`79886.28`, mais que o dobro do custo total da varredura inteira embaixo dele, e o `Limit` herda
esse custo inicial. Dez linhas pedidas, e o plano ainda paga pelos dois milhões antes de a primeira
aparecer.

A mesma pergunta — dez pedidos — custa `0.77` de um jeito e `79886.31` do outro, e a diferença não
está no `LIMIT`, mas em haver ou não algo embaixo dele capaz de parar cedo. É por isso que o
planejador olha o custo inicial sempre que a consulta só quer as primeiras linhas: um `LIMIT`, um
`EXISTS`, um cursor buscando uma página por vez. Um plano de total alto e custo inicial baixo pode
ganhar nesses casos, e um plano de custo inicial alto nunca ganha.

## O que levar para a próxima seção

- **Todo nó carrega uma previsão**: custo do começo ao fim, linhas, largura.
- **O `EXPLAIN` sozinho não executa nada**, nem um `DELETE`.
- **Um nó com custo inicial perto do total é um nó que precisa terminar antes de começar** — uma
  ordenação, um hash sendo montado, uma agregação. Reconhecer esses nós é metade da leitura de um
  plano.
