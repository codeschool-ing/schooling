---
title: Seletividade, e o ponto em que o plano vira
version: 1
---

**Seletividade** é a fração das linhas de uma tabela que uma condição mantém: um dia de pedidos é
uma fração pequena, um ano é mais da metade. A crença comum é que existe um número — "o índice é
usado abaixo de 5%", ou 10, ou 15 — e que o planejador troca do índice para a tabela nessa linha.
Não existe esse número. Existe um ponto de virada, e onde ele fica depende tanto da coluna quanto da
fração.

## Alargando uma faixa de datas

Com os planos paralelos permitidos de novo, como o servidor vem, peça o plano da mesma soma para um
dia, um mês e um ano:

```
market=# EXPLAIN SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-06-01' AND placed_at < '2025-06-02';
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=135.56..135.57 rows=1 width=8)
   ->  Index Scan using orders_placed_at_idx on orders  (cost=0.43..127.77 rows=3117 width=4)
         Index Cond: ((placed_at >= '2025-06-01 00:00:00-03'::timestamp with time zone) AND (placed_at < '2025-06-02 00:00:00-03'::timestamp with time zone))
(3 rows)

Time: 2.262 ms

market=# EXPLAIN SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-06-01' AND placed_at < '2025-07-01';
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=3780.99..3781.00 rows=1 width=8)
   ->  Index Scan using orders_placed_at_idx on orders  (cost=0.43..3555.15 rows=90336 width=4)
         Index Cond: ((placed_at >= '2025-06-01 00:00:00-03'::timestamp with time zone) AND (placed_at < '2025-07-01 00:00:00-03'::timestamp with time zone))
(3 rows)

Time: 1.007 ms

market=# EXPLAIN SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-01-01' AND placed_at < '2026-01-01';
                                                                              QUERY PLAN                                                                              
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=31313.85..31313.86 rows=1 width=8)
   ->  Gather  (cost=31313.64..31313.85 rows=2 width=8)
         Workers Planned: 2
         ->  Partial Aggregate  (cost=30313.64..30313.65 rows=1 width=8)
               ->  Parallel Seq Scan on orders  (cost=0.00..29167.00 rows=458656 width=4)
                     Filter: ((placed_at >= '2025-01-01 00:00:00-03'::timestamp with time zone) AND (placed_at < '2026-01-01 00:00:00-03'::timestamp with time zone))
(6 rows)

Time: 0.736 ms
```

Um dia e um mês são varreduras de índice; o ano é uma varredura sequencial paralela. O planejador
não consultou um limite. Ele precificou cada caminho de acesso para cada faixa e ficou com o mais
barato, e entre um mês e um ano o preço de percorrer o índice passou o de ler a tabela.

## Alargando uma faixa de clientes

Agora o mesmo com clientes, cem, vinte mil e sessenta mil deles:

```
market=# EXPLAIN SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1000 AND 1100;
                                          QUERY PLAN                                           
-----------------------------------------------------------------------------------------------
 Aggregate  (cost=3453.67..3453.68 rows=1 width=8)
   ->  Bitmap Heap Scan on orders  (cost=19.56..3450.95 rows=1086 width=4)
         Recheck Cond: ((customer_id >= 1000) AND (customer_id <= 1100))
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..19.29 rows=1086 width=0)
               Index Cond: ((customer_id >= 1000) AND (customer_id <= 1100))
(5 rows)

Time: 1.914 ms

market=# EXPLAIN SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 20000;
                                                  QUERY PLAN                                                   
---------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=22170.23..22170.24 rows=1 width=8)
   ->  Gather  (cost=22170.02..22170.23 rows=2 width=8)
         Workers Planned: 2
         ->  Partial Aggregate  (cost=21170.02..21170.03 rows=1 width=8)
               ->  Parallel Bitmap Heap Scan on orders  (cost=3017.14..20957.75 rows=84907 width=4)
                     Recheck Cond: ((customer_id >= 1) AND (customer_id <= 20000))
                     ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..2966.20 rows=203777 width=0)
                           Index Cond: ((customer_id >= 1) AND (customer_id <= 20000))
(8 rows)

Time: 0.627 ms

market=# EXPLAIN SELECT sum(total_cents) FROM orders WHERE customer_id BETWEEN 1 AND 60000;
                                        QUERY PLAN                                        
------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=30793.77..30793.78 rows=1 width=8)
   ->  Gather  (cost=30793.55..30793.76 rows=2 width=8)
         Workers Planned: 2
         ->  Partial Aggregate  (cost=29793.55..29793.56 rows=1 width=8)
               ->  Parallel Seq Scan on orders  (cost=0.00..29167.00 rows=250621 width=4)
                     Filter: ((customer_id >= 1) AND (customer_id <= 60000))
(6 rows)

Time: 0.475 ms
```

Cem clientes já ganham uma varredura bitmap, e não uma varredura de índice. Vinte mil ganham uma
varredura bitmap paralela; sessenta mil, uma varredura sequencial paralela. Lado a lado, com a
fração da tabela que cada condição mantém:

| condição | linhas estimadas | fração de `orders` | plano |
|---|---|---|---|
| um dia de `placed_at` | 3117 | 0,16% | Index Scan |
| um mês de `placed_at` | 90336 | 4,5% | Index Scan |
| um ano de `placed_at` | cerca de 1,1 milhão | 55% | Parallel Seq Scan |
| 100 valores de `customer_id` | 1086 | 0,05% | Bitmap Heap Scan |
| 20000 valores de `customer_id` | 203777 | 10% | Parallel Bitmap Heap Scan |
| 60000 valores de `customer_id` | cerca de 600000 | 30% | Parallel Seq Scan |

Os planos paralelos imprimem as estimativas de linhas por processo, e é por isso que a tabela
arredonda essas duas em vez de copiar um número da tela.

**Um mês de pedidos, 4,5% da tabela, é buscado uma linha por vez pelo índice, e os pedidos de cem
clientes, um centésimo dessa fração, não são.** A diferença é a correlação da seção anterior. Em
`placed_at` as linhas de um mês ficam juntas em umas 750 páginas consecutivas, então seguir o
índice custa mais ou menos o que custaria ler essas páginas em ordem. Em `customer_id`, mil linhas
são mil páginas espalhadas pelo arquivo, e o planejador as reúne num bitmap para pelo menos lê-las
em ordem.

## O que move o ponto de virada

O planejador pesa quatro coisas, e cada uma apareceu nesta aula ou na anterior:

- **quantas linhas** a condição mantém, que o planejador só conhece como estimativa, a partir das
  estatísticas;
- **em quantas páginas** essas linhas estão, que é o que a correlação prevê;
- **a tabela de preços** — `random_page_cost` a 4 contra `seq_page_cost` a 1 diz que uma página
  fora de ordem custa quatro leituras em ordem, e essa razão decide quão cedo uma varredura de
  índice espalhada perde;
- **o que a consulta faz com as linhas**: um `ORDER BY` que o índice já atende, ou um `LIMIT` que
  para cedo, deixa uma varredura de índice mais barata do que a contagem de linhas sugere.

A tabela de preços merece uma palavra, porque é a entrada que as pessoas mudam. O 4 padrão descreve
um disco giratório, em que um posicionamento da cabeça é caro. Num armazenamento de estado sólido
uma leitura aleatória custa bem mais perto de uma sequencial, e baixar o `random_page_cost` em
direção a 1 move todo ponto de virada em direção ao índice. Isso é uma afirmação sobre a máquina,
feita uma vez na configuração do servidor depois de medir, e `db-administration` é o lugar dela.
Mudá-lo para fazer uma consulta escolher um plano é o erro de que trata a próxima seção.

## A estimativa é uma entrada como qualquer outra

Toda contagem de linhas da tabela acima é uma estimativa, e o planejador escolheu cada plano com
base nela. Aqui as estimativas estão perto: 3117 esperadas para um dia que tinha 2801, 1086 para
991. Quando uma estimativa erra por um fator de cem, o planejador escolhe o plano para uma
seletividade que não existe. Um bom índice é ignorado, ou uma boa varredura sequencial é trocada por
dez mil leituras aleatórias. **Ler o caminho de acesso é só metade de ler um plano; a outra metade é
conferir a estimativa com que ele foi escolhido.** A aula 6 trata da estimativa errada, e a aula 7
das estatísticas de onde ela vem.
