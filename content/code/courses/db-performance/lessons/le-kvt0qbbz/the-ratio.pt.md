---
title: Dois números em cada nó
version: 1
---

A aula 3 pôs dois parênteses em cada nó de um plano: o palpite do planejador, `cost=… rows=…`, e o
que aconteceu, `actual time=… rows=… loops=…`. Esta aula é sobre os dois `rows` lado a lado. Eles são
o par de números mais útil de um plano, porque **toda escolha do planejador foi feita para a
estimativa**: o scan, o join, a ordem dos joins, se uma ordenação ou um hash cabe na memória. Quando
a estimativa acerta, essas escolhas foram feitas para os dados que apareceram. Quando erra, foram
feitas para outros dados.

A crença a abandonar primeiro é que um plano lento é lento porque o planejador escolheu mal. Em geral
ele escolheu bem, para os números que recebeu. O conserto quase nunca é passar por cima da escolha; é
achar o número que estava errado.

Uma configuração para a aula inteira. Planos paralelos dividem as linhas de cada nó entre processos,
como a aula 3 mostrou. Isso deixa a comparação mais difícil de ler, então desligue-os na sua sessão
antes de cada consulta:

```sql
SET max_parallel_workers_per_gather = 0;
```

## Um nó que bate

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.653 ms

market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE seller_id = 42;
                                                                  QUERY PLAN                                                                   
-----------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=38.25..38.26 rows=1 width=8) (actual time=0.332..0.367 rows=1 loops=1)
   ->  Index Only Scan using orders_seller_id_idx on orders  (cost=0.43..34.52 rows=1491 width=0) (actual time=0.099..0.275 rows=1532 loops=1)
         Index Cond: (seller_id = 42)
         Heap Fetches: 0
 Planning Time: 3.227 ms
 Execution Time: 0.597 ms
(6 rows)

Time: 7.175 ms
```

**1491 estimadas, 1532 reais.** Divida uma pela outra e a **razão** é 1,03: a estimativa ficou 3%
abaixo. A aula 7 mostra de onde vem o 1491; aqui basta que os dois batam. Uma razão entre cerca de
meio e dois é normal e não muda nada. Dez merece leitura. Cem é um plano feito para outra tabela.

Dois cuidados da aula 3 valem antes de dividir qualquer coisa. Num nó com `loops` acima de um, os dois
números são **por loop**, então se comparam diretamente entre si. E um nó debaixo de um `Limit` pode
parar cedo, então a contagem real pode ficar muito abaixo da estimativa sem nada estar errado.

## Um nó que não bate

Quantos pedidos fizeram os clientes de Curitiba? Junte as duas tabelas e conte:

```
market=# EXPLAIN ANALYZE SELECT count(*) FROM orders o JOIN customers c ON c.id = o.customer_id WHERE c.city = 'Curitiba' AND c.state = 'PR';
                                                                       QUERY PLAN                                                                       
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=9103.19..9103.20 rows=1 width=8) (actual time=69.567..69.569 rows=1 loops=1)
   ->  Nested Loop  (cost=0.43..9079.74 rows=9380 width=0) (actual time=0.033..63.401 rows=135717 loops=1)
         ->  Seq Scan on customers c  (cost=0.00..5283.00 rows=938 width=4) (actual time=0.025..18.451 rows=13578 loops=1)
               Filter: ((city = 'Curitiba'::text) AND (state = 'PR'::text))
               Rows Removed by Filter: 186422
         ->  Index Only Scan using orders_customer_id_idx on orders o  (cost=0.43..3.94 rows=11 width=4) (actual time=0.002..0.002 rows=10 loops=13578)
               Index Cond: (customer_id = c.id)
               Heap Fetches: 0
 Planning Time: 1.989 ms
 Execution Time: 69.694 ms
(10 rows)

Time: 72.886 ms
```

Leia **de baixo para cima**, do jeito que as linhas correm.

1. **`Seq Scan on customers`**: 938 estimadas, **13.578** reais. Uma razão de 14,5. Este é o primeiro
   nó, subindo, em que os dois números se separam.
2. **`Index Only Scan on orders`**: 11 estimadas, 10 reais, por loop. Tudo bem: cada cliente tem uns
   dez pedidos, como esperado. Mas ele rodou **13.578 vezes** em vez de 938.
3. **`Nested Loop`**: 9380 estimadas, **135.717** reais. Errado pelo mesmo fator de 14,5, e não por
   nada que este nó tenha feito. Ele multiplicou as linhas que vinham de baixo pelos dez pedidos de
   cada uma, e as linhas de baixo já estavam erradas.

Essa é a regra para ler uma estimativa errada: **ache o nó mais baixo em que estimado e real se
separam**. Tudo acima dele herda o erro, muitas vezes multiplicado, e parece culpado sem ser a causa.
Um join três níveis acima mostrando razão cinquenta é um sintoma; o scan lá embaixo mostrando quinze é
a doença.

Aqui a doença é a da aula 7: `city` e `state` dizem a mesma coisa duas vezes, e o planejador
multiplicou duas frações que não eram independentes. O plano sobreviveu, um nested loop sobre 13.578
clientes leva 70 milissegundos, mas o mesmo erro numa consulta maior escolheria um nested loop onde
cabia um hash join. A aula 7 mostra o conserto. Esta aula trata da outra causa comum, a que não tem
nada de errado no desenho: estatísticas que descrevem uma tabela que já mudou.
