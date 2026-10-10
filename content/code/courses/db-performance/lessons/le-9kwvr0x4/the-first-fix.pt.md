---
title: O primeiro conserto, e o caminho de volta
version: 1
---

O placar apontou três comandos. Dois deles precisam de ferramentas que aulas seguintes ensinam: a
busca por etiqueta quer um tipo de índice que entenda arrays (aula 8), e a contagem de pendentes
quer um índice sobre uma parte pequena de uma tabela (aula 9). O terceiro dá para consertar hoje,
com o que a aula 1 mostrou.

O painel do vendedor pede os pedidos de dezembro de um vendedor. `orders` tem um índice em
`placed_at`, então o servidor acha dezembro depressa:

```
market=# SELECT count(*) FROM orders WHERE placed_at >= '2025-12-01';
 count  
--------
 107780
(1 row)

Time: 9.945 ms
```

Mas depois tem de olhar cada um desses 107780 pedidos para ficar com os vinte e nove que são deste
vendedor. Não há índice em `seller_id`. A aula 1 seção 05 criou um e o apagou de novo; desta vez o
placar disse que ele é necessário, que é o motivo certo para criá-lo.

## Conserte uma coisa, depois meça do mesmo jeito

Zere o placar, para que os próximos números contem a partir de zero, crie o índice e rode a mesma
carga pelo mesmo minuto:

```
market=# SELECT pg_stat_statements_reset();
 pg_stat_statements_reset 
--------------------------
 
(1 row)

Time: 1.787 ms

market=# CREATE INDEX orders_seller_id_idx ON orders (seller_id);
CREATE INDEX
Time: 1221.753 ms (00:01.222)
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 60 -P 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
progress: 20.0 s, 994.0 tps, lat 8.030 ms stddev 26.556, 0 failed
progress: 40.0 s, 913.0 tps, lat 8.771 ms stddev 30.397, 0 failed
progress: 60.0 s, 1013.4 tps, lat 7.889 ms stddev 26.561, 0 failed
transaction type: multiple scripts
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 58416
number of failed transactions: 0 (0.000%)
latency average = 8.218 ms
latency stddev = 27.827 ms
initial connection time = 8.056 ms
tps = 972.682647 (without initial connection time)
SQL script 1: customer-orders.sql
 - weight: 50 (targets 50.0% of total)
 - 29131 transactions (49.9% of total, tps = 485.059199)
 - number of failed transactions: 0 (0.000%)
 - latency average = 0.975 ms
 - latency stddev = 2.153 ms
SQL script 2: order-page.sql
 - weight: 25 (targets 25.0% of total)
 - 14585 transactions (25.0% of total, tps = 242.854293)
 - number of failed transactions: 0 (0.000%)
 - latency average = 1.065 ms
 - latency stddev = 2.118 ms
SQL script 3: tag-search.sql
 - weight: 10 (targets 10.0% of total)
 - 5926 transactions (10.1% of total, tps = 98.673606)
 - number of failed transactions: 0 (0.000%)
 - latency average = 34.316 ms
 - latency stddev = 13.558 ms
SQL script 4: place-order.sql
 - weight: 10 (targets 10.0% of total)
 - 5721 transactions (9.8% of total, tps = 95.260159)
 - number of failed transactions: 0 (0.000%)
 - latency average = 9.738 ms
 - latency stddev = 6.880 ms
SQL script 5: seller-dashboard.sql
 - weight: 4 (targets 4.0% of total)
 - 2458 transactions (4.2% of total, tps = 40.928067)
 - number of failed transactions: 0 (0.000%)
 - latency average = 12.498 ms
 - latency stddev = 6.868 ms
SQL script 6: pending-count.sql
 - weight: 1 (targets 1.0% of total)
 - 591 transactions (1.0% of total, tps = 9.840719)
 - number of failed transactions: 0 (0.000%)
 - latency average = 247.697 ms
 - latency stddev = 74.672 ms
market=# SELECT calls, round(total_exec_time) AS total_ms, round(mean_exec_time::numeric, 2) AS mean_ms, round(100 * total_exec_time / sum(total_exec_time) OVER ()) AS pct, left(regexp_replace(query, '\s+', ' ', 'g'), 50) AS query FROM pg_stat_statements WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'market') ORDER BY total_exec_time DESC LIMIT 8;
 calls | total_ms | mean_ms | pct |                       query                        
-------+----------+---------+-----+----------------------------------------------------
  5926 |   196013 |   33.08 |  52 | SELECT id, title, price_cents FROM products WHERE 
   591 |   145822 |  246.74 |  39 | SELECT count(*) FROM orders WHERE status = $1
  2458 |    27667 |   11.26 |   7 | SELECT date_trunc($1, placed_at) AS day, count(*),
 29132 |     3344 |    0.11 |   1 | SELECT id, placed_at, status, total_cents FROM ord
 14585 |     1448 |    0.10 |   0 | SELECT p.title, l.quantity, l.price_cents FROM ord
  5724 |     1418 |    0.25 |   0 | INSERT INTO orders (customer_id, seller_id, placed
     1 |     1211 | 1210.89 |   0 | CREATE INDEX orders_seller_id_idx ON orders (selle
  5724 |      696 |    0.12 |   0 | INSERT INTO order_lines (order_id, line, product_i
(8 rows)

Time: 3.428 ms
```

Compare a linha do painel do vendedor com a de antes do conserto:

| | antes | depois |
|---|---|---|
| média por execução | 35,49 ms | 11,26 ms |
| total em um minuto | 76810 ms | 27667 ms |
| fatia do servidor | 21% | 7% |
| latência do script no pgbench | 36,674 ms | 12,498 ms |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Duas barras horizontais, cada uma o tempo do servidor num minuto da carga, dividido por comando. Antes do índice: busca por etiqueta 45%, contagem de pendentes 32%, painel do vendedor 21%, todo o resto 2%. Depois: busca por etiqueta 52%, contagem de pendentes 39%, painel do vendedor 7%, todo o resto 2%.\"><text x=\"110\" y=\"72\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--paper)\">antes</text><rect x=\"120\" y=\"58\" width=\"261.0\" height=\"28\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"250.5\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">45%</text><rect x=\"381.0\" y=\"58\" width=\"185.6\" height=\"28\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"473.8\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">32%</text><rect x=\"566.6\" y=\"58\" width=\"121.8\" height=\"28\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"627.5\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">21%</text><rect x=\"688.4\" y=\"58\" width=\"11.6\" height=\"28\" rx=\"0\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"110\" y=\"132\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--paper)\">depois</text><rect x=\"120\" y=\"118\" width=\"301.6\" height=\"28\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"270.8\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">52%</text><rect x=\"421.6\" y=\"118\" width=\"226.2\" height=\"28\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"534.7\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">39%</text><rect x=\"647.8\" y=\"118\" width=\"40.6\" height=\"28\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"668.1\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">7%</text><rect x=\"688.4\" y=\"118\" width=\"11.6\" height=\"28\" rx=\"0\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"166\" width=\"12\" height=\"12\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"138\" y=\"172\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">busca por etiqueta</text><rect x=\"270\" y=\"166\" width=\"12\" height=\"12\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"288\" y=\"172\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">contagem de pendentes</text><rect x=\"420\" y=\"166\" width=\"12\" height=\"12\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"438\" y=\"172\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">painel do vendedor</text><rect x=\"570\" y=\"166\" width=\"12\" height=\"12\" rx=\"0\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"588\" y=\"172\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o resto</text><text x=\"120\" y=\"22\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fatia do tempo do servidor em um minuto</text></svg>", "caption": "O minuto do servidor, dividido por comando, antes e depois do índice em seller_id. A fatia do painel encolheu; as outras duas só cresceram porque o todo encolheu."}
```

**Cerca de um terço do tempo por execução, e dois terços da fatia dele no servidor devolvidos.** A
medida foi tomada do mesmo jeito nas duas vezes — mesma carga, mesmo minuto, mesma máquina, placar
zerado antes de cada uma —, e é isso que torna as duas colunas comparáveis. Mude duas coisas de uma
vez, ou meça o depois de um jeito diferente do antes, e a tabela não significa nada.

Repare no que não mudou. A busca por etiqueta e a contagem de pendentes continuam no alto, maiores
agora em fatia porque o total encolheu em volta delas. E a taxa geral mal se mexeu, de 912 para 972
transações por segundo: o painel do vendedor é quatro de cada cem transações, então uma grande
melhora nele é uma pequena melhora no todo. A aula 24 trata de distinguir as duas coisas antes de
você gastar uma semana na errada.

O índice também custou algo: **1221 milissegundos para ser criado**, e todo pedido gravado daqui em
diante paga um pouco para mantê-lo em dia. O script `place-order.sql` está na carga para que esse
custo apareça, e a aula 11 é onde ele é medido.

## De volta às linhas conhecidas

A carga gravou pedidos. Cada execução do `place-order.sql` acrescentou um, então o `market` agora
tem vários milhares de pedidos que o `market.sql` nunca fez, e as contagens das transcrições das
próximas aulas deixariam de bater com as suas. A aula 1 guardou uma cópia do banco como foi
carregado; este script põe o `market` de volta como essa cópia e acrescenta as duas coisas que esta
aula construiu, a extensão e o índice:

```sh
cat > ~/reset-market.sh <<'SH'
#!/bin/sh
# Put market back as lesson 3 starts: the rows market.sql made, plus
# lesson 2's extension and index. Close every psql on market first.
set -e
dropdb --if-exists market
createdb -T market_base market
psql -q market -c 'CREATE EXTENSION pg_stat_statements' \
               -c 'CREATE INDEX orders_seller_id_idx ON orders (seller_id)'
SH
chmod +x ~/reset-market.sh
```

Rode-o sempre que seus números se afastarem das transcrições, e sempre que uma aula mandar. Ele
precisa que todo `psql` conectado ao `market` esteja fechado antes, porque um banco não pode ser
apagado enquanto tem alguém dentro:

```
ana@vm:~$ ~/reset-market.sh
CREATE EXTENSION
Time: 10.039 ms
CREATE INDEX
Time: 1429.029 ms (00:01.429)
market=# SELECT count(*) FROM orders;
  count  
---------
 2000000
(1 row)

Time: 66.883 ms

market=# \di orders*
                    List of relations
 Schema |          Name          | Type  | Owner | Table  
--------+------------------------+-------+-------+--------
 public | orders_customer_id_idx | index | ana   | orders
 public | orders_pkey            | index | ana   | orders
 public | orders_placed_at_idx   | index | ana   | orders
 public | orders_seller_id_idx   | index | ana   | orders
(4 rows)
EXIT 0
```

Dois milhões de pedidos de novo, e os quatro índices com que toda aula a partir da 3 começa. As
linhas `Time:` vêm do `~/.psqlrc`, que o `psql` lê até quando roda um único comando.
