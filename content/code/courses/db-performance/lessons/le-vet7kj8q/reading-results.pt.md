---
title: Lendo o que o pgbench relata
version: 1
---

Um relatório do `pgbench` tem quarenta linhas, e a maioria das pessoas lê uma: `tps`. Esse número é
real e é a linha menos informativa do relatório, porque diz quanto trabalho foi feito e nada sobre
como foi para quem estava esperando. Duas opções põem o resto na tela: `-P 10` imprime o progresso a
cada dez segundos, e `-r` informa a latência de cada comando de cada script. A carga da aula 2, trinta
segundos:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -P 10 -r -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
progress: 10.0 s, 1263.4 tps, lat 6.303 ms stddev 22.251, 0 failed
progress: 20.0 s, 1156.7 tps, lat 6.900 ms stddev 24.618, 0 failed
progress: 30.0 s, 1288.9 tps, lat 6.190 ms stddev 21.487, 0 failed
transaction type: multiple scripts
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 37131
number of failed transactions: 0 (0.000%)
latency average = 6.465 ms
latency stddev = 22.826 ms
initial connection time = 8.671 ms
tps = 1234.090860 (without initial connection time)
SQL script 1: customer-orders.sql
 - weight: 50 (targets 50.0% of total)
 - 18707 transactions (50.4% of total, tps = 621.748343)
 - number of failed transactions: 0 (0.000%)
 - latency average = 0.986 ms
 - latency stddev = 2.972 ms
 - statement latencies in milliseconds and failures:
         0.001           0  \set c random(1, 200000)
         0.984           0  SELECT id, placed_at, status, total_cents
SQL script 2: order-page.sql
 - weight: 25 (targets 25.0% of total)
 - 9274 transactions (25.0% of total, tps = 308.231899)
 - number of failed transactions: 0 (0.000%)
 - latency average = 1.025 ms
 - latency stddev = 2.540 ms
 - statement latencies in milliseconds and failures:
         0.001           0  \set o random(1, 2000000)
         1.023           0  SELECT p.title, l.quantity, l.price_cents
SQL script 3: tag-search.sql
 - weight: 10 (targets 10.0% of total)
 - 3597 transactions (9.7% of total, tps = 119.550371)
 - number of failed transactions: 0 (0.000%)
 - latency average = 25.944 ms
 - latency stddev = 20.190 ms
 - statement latencies in milliseconds and failures:
         0.001           0  \set t random(1, 5)
        25.943           0  SELECT id, title, price_cents FROM products
SQL script 4: place-order.sql
 - weight: 10 (targets 10.0% of total)
 - 3704 transactions (10.0% of total, tps = 123.106637)
 - number of failed transactions: 0 (0.000%)
 - latency average = 9.368 ms
 - latency stddev = 9.327 ms
 - statement latencies in milliseconds and failures:
         0.002           0  \set c random(1, 200000)
         0.001           0  \set s random(1, 1000)
         0.001           0  \set p random(1, 50000)
         0.829           0  BEGIN;
         0.474           0  INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents)
         0.585           0  INSERT INTO order_lines (order_id, line, product_id, quantity, price_cents)
         0.540           0  UPDATE orders SET total_cents = (SELECT sum(quantity * price_cents)
         6.939           0  COMMIT;
SQL script 5: seller-dashboard.sql
 - weight: 4 (targets 4.0% of total)
 - 1486 transactions (4.0% of total, tps = 49.388894)
 - number of failed transactions: 0 (0.000%)
 - latency average = 8.289 ms
 - latency stddev = 10.027 ms
 - statement latencies in milliseconds and failures:
         0.002           0  \set s random(2, 1000)
         8.287           0  SELECT date_trunc('day', placed_at) AS day, count(*), sum(total_cents)
SQL script 6: pending-count.sql
 - weight: 1 (targets 1.0% of total)
 - 363 transactions (1.0% of total, tps = 12.064716)
 - number of failed transactions: 0 (0.000%)
 - latency average = 197.742 ms
 - latency stddev = 67.727 ms
 - statement latencies in milliseconds and failures:
       197.742           0  SELECT count(*) FROM orders WHERE status = 'pending';
```

Leia em quatro camadas.

## A execução como um todo

- **`number of transactions actually processed: 37131`** em **`duration: 30 s`**, e
  **`number of failed transactions: 0`**. Confira as falhas primeiro: uma execução em que transações
  falharam mediu outra coisa que não a sua carga, por melhores que pareçam os outros números.
- **`tps = 1234.090860 (without initial connection time)`** é a vazão: 37131 transações em trinta
  segundos, deixando de fora os 8,7 milissegundos gastos para abrir as oito conexões. Uma aplicação
  real mantém as conexões abertas, então deixá-los de fora está certo.
- **`latency average = 6.465 ms`** é o tempo médio entre enviar uma transação e receber a última
  resposta. Com oito clientes, cada um enviando a próxima transação no instante em que a anterior
  volta, 8 dividido por 0,006465 segundo dá uns 1237 por segundo — o `tps` de novo, e é por isso que
  nesse modo os dois números são um fato escrito duas vezes.

## A dispersão

**`latency stddev = 22.826 ms`**: o desvio-padrão é **três vezes e meia a média**. Isso não acontece
com uma dispersão simétrica em torno de 6,5 milissegundos, já que nenhuma transação leva menos que
zero. Quer dizer que a maioria das transações é rápida e algumas são muito lentas, e a média fica
entre dois grupos que ela descreve mal. Os blocos por script, mais abaixo, dizem quem são os dois
grupos.

A média e o desvio-padrão são o único resumo que o `pgbench` imprime, e para latência são o resumo
errado. O que um usuário sente é um percentil: o tempo abaixo do qual chegam 95 ou 99 de cada cem
transações. O `pgbench -l` grava a latência de cada transação num log, e a aula 23 monta um script
curto que lê esses logs e imprime os percentis 50, 95 e 99; use-o sempre que o desvio-padrão for
maior que a média, o que numa carga mista é quase sempre.

O `pgbench` só imprime o desvio-padrão quando `-P` ou uma taxa estão em vigor; as execuções adiante
que não usam nenhum dos dois mostram só a média.

## As linhas de progresso

`progress: 10.0 s, 1263.4 tps … progress: 20.0 s, 1156.7 tps … progress: 30.0 s, 1288.9 tps`. A mesma
execução, dez segundos por vez, variou uns 10%. Nada mudou entre os intervalos além do que sempre muda
— quais linhas foram pedidas, o que mais o computador estava fazendo —, e essa é a primeira visão do
ruído que a última seção desta aula mede. Uma execução cujas linhas de progresso **têm tendência** em
vez de oscilar, subindo sem parar ou descendo sem parar, ainda não se acomodou, e o total dela é a
média de dois estados diferentes.

## Por script, por comando

Cada script ganha um bloco: o peso dele e a fração que de fato recebeu, o `tps` próprio e a média e o
desvio-padrão próprios de latência. Depois o `-r` acrescenta uma linha por comando, com a latência
média em milissegundos e as falhas:

| script | média de latência | onde vai o tempo |
|---|---|---|
| `customer-orders.sql` | 0.986 ms | o `SELECT`, 0.984 |
| `order-page.sql` | 1.025 ms | o `SELECT`, 1.023 |
| `tag-search.sql` | 25.944 ms | o `SELECT`, 25.943 |
| `place-order.sql` | 9.368 ms | o `COMMIT`, 6.939 |
| `seller-dashboard.sql` | 8.289 ms | o `SELECT`, 8.287 |
| `pending-count.sql` | 197.742 ms | o `SELECT`, 197.742 |

Duas delas merecem uma frase cada. **A compra passa três quartos do tempo no `COMMIT`**: os dois
`INSERT` e o `UPDATE` juntos levam uns 1,6 milissegundo, e o commit 6,9. Um commit espera até o
registro da transação estar gravado em disco com segurança, então é para lá que vai o tempo de uma
transação de escrita na maioria das máquinas, e nenhum índice mexeria nisso. **As linhas `\set` custam
um milésimo de milissegundo**: o trabalho do próprio cliente, pequeno demais para importar nesta
carga.

E o quadro que o resumo escondia agora aparece: três quartos das transações levam cerca de um
milissegundo, um décimo leva 26, e uma em cem leva 198. Os 6,5 milissegundos da média não são a
experiência de ninguém. Era isso que o desvio-padrão dizia, e os percentis da aula 23 são o jeito de
dizê-lo por usuário em vez de por script.
