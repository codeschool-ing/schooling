---
title: Uma manhã de tráfego, em um minuto
version: 1
---

Um banco sozinho não roda nada. Os comandos dele vêm de uma aplicação: telas que as pessoas abrem,
botões que apertam, tarefas que rodam de madrugada. Para descobrir o que mais custa ao servidor, é
preciso esse tráfego, e numa máquina só sua não há nenhum — então você o fabrica, com o `pgbench`.

O `pgbench` vem com o PostgreSQL e costuma ser conhecido como um benchmark com tabelas próprias. Ele
também roda **scripts que você escreve**: um arquivo de SQL, com variáveis sorteadas a cada
execução, executado de novo e de novo por quantos clientes simulados você pedir. Seis arquivos
compõem a manhã de um pequeno marketplace. Cada um é uma coisa que uma pessoa ou uma tela faz, com
um comentário dizendo qual:

```sh
mkdir -p ~/workload && cd ~/workload

cat > customer-orders.sql <<'SQL'
-- A customer opens "my orders": the last ten, newest first.
\set c random(1, 200000)
SELECT id, placed_at, status, total_cents
FROM orders WHERE customer_id = :c
ORDER BY placed_at DESC LIMIT 10;
SQL

cat > order-page.sql <<'SQL'
-- One order's page: its lines, with each product's title.
\set o random(1, 2000000)
SELECT p.title, l.quantity, l.price_cents
FROM order_lines AS l JOIN products AS p ON p.id = l.product_id
WHERE l.order_id = :o;
SQL

cat > tag-search.sql <<'SQL'
-- Browsing a tag: twenty products, cheapest first.
\set t random(1, 5)
SELECT id, title, price_cents FROM products
WHERE tags @> ARRAY[(ARRAY['home', 'kitchen', 'office', 'outdoor', 'kids'])[:t]]
ORDER BY price_cents LIMIT 20;
SQL

cat > place-order.sql <<'SQL'
-- Somebody buys something: one order, one line, the total filled in.
\set c random(1, 200000)
\set s random(1, 1000)
\set p random(1, 50000)
BEGIN;
INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents)
VALUES (:c, :s, now(), 'pending', 0) RETURNING id AS order_id \gset
INSERT INTO order_lines (order_id, line, product_id, quantity, price_cents)
SELECT :order_id, 1, id, 1, price_cents FROM products WHERE id = :p;
UPDATE orders SET total_cents = (SELECT sum(quantity * price_cents)
                                 FROM order_lines WHERE order_id = :order_id)
WHERE id = :order_id;
COMMIT;
SQL

cat > seller-dashboard.sql <<'SQL'
-- A seller's dashboard: December, day by day.
\set s random(2, 1000)
SELECT date_trunc('day', placed_at) AS day, count(*), sum(total_cents)
FROM orders
WHERE seller_id = :s AND placed_at >= '2025-12-01'
GROUP BY 1 ORDER BY 1;
SQL

cat > pending-count.sql <<'SQL'
-- The operations screen, refreshed by everybody who has it open.
SELECT count(*) FROM orders WHERE status = 'pending';
SQL
```

Copie o bloco inteiro e cole no seu prompt: ele cria o diretório e grava os seis arquivos dentro.

```
ana@vm:~$ ls ~/workload
customer-orders.sql
order-page.sql
pending-count.sql
place-order.sql
seller-dashboard.sql
tag-search.sql
```

## Um minuto de tráfego

O `pgbench` recebe os arquivos com `-f`, cada um com um **peso** depois do `@`: de cada cem
transações, cinquenta são a lista de pedidos de um cliente, vinte e cinco uma página de pedido, dez
buscas por etiqueta, dez compras, quatro painéis de vendedor e uma atualização da tela de operações.
As outras opções dizem com que força empurrar: `-c 8` são oito clientes ao mesmo tempo, `-j 4` os
roda em quatro threads, `-T 60` por sessenta segundos, `-P 20` imprime o progresso a cada vinte, e
`-n` pula a limpeza que o `pgbench` tentaria fazer nas tabelas do benchmark dele, que o `market` não
tem:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 60 -P 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
progress: 20.0 s, 796.5 tps, lat 9.986 ms stddev 31.316, 0 failed
progress: 40.0 s, 972.7 tps, lat 8.247 ms stddev 25.464, 0 failed
progress: 60.0 s, 972.0 tps, lat 8.238 ms stddev 24.896, 0 failed
transaction type: multiple scripts
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 54833
number of failed transactions: 0 (0.000%)
latency average = 8.756 ms
latency stddev = 27.129 ms
initial connection time = 9.223 ms
tps = 912.697830 (without initial connection time)
SQL script 1: customer-orders.sql
 - weight: 50 (targets 50.0% of total)
 - 27488 transactions (50.1% of total, tps = 457.539036)
 - number of failed transactions: 0 (0.000%)
 - latency average = 0.912 ms
 - latency stddev = 2.028 ms
SQL script 2: order-page.sql
 - weight: 25 (targets 25.0% of total)
 - 13786 transactions (25.1% of total, tps = 229.468610)
 - number of failed transactions: 0 (0.000%)
 - latency average = 1.027 ms
 - latency stddev = 2.113 ms
SQL script 3: tag-search.sql
 - weight: 10 (targets 10.0% of total)
 - 5496 transactions (10.0% of total, tps = 91.481175)
 - number of failed transactions: 0 (0.000%)
 - latency average = 31.417 ms
 - latency stddev = 12.690 ms
SQL script 4: place-order.sql
 - weight: 10 (targets 10.0% of total)
 - 5354 transactions (9.8% of total, tps = 89.117579)
 - number of failed transactions: 0 (0.000%)
 - latency average = 12.862 ms
 - latency stddev = 31.163 ms
SQL script 5: seller-dashboard.sql
 - weight: 4 (targets 4.0% of total)
 - 2164 transactions (3.9% of total, tps = 36.019880)
 - number of failed transactions: 0 (0.000%)
 - latency average = 36.674 ms
 - latency stddev = 15.144 ms
SQL script 6: pending-count.sql
 - weight: 1 (targets 1.0% of total)
 - 540 transactions (1.0% of total, tps = 8.988325)
 - number of failed transactions: 0 (0.000%)
 - latency average = 222.128 ms
 - latency stddev = 59.235 ms
```

Umas novecentas transações por segundo durante um minuto, **54833** no total, nenhuma com falha. O
relatório termina com um bloco por script, e dois números nele já valem a leitura. A latência média
da lista de pedidos de um cliente é **0,912 milissegundo**, e a da contagem da tela de operações,
**222 milissegundos**, duzentas e quarenta vezes mais. E mesmo assim o script de que as pessoas se
queixariam não é necessariamente o que mais custa ao servidor, e é isso que a próxima seção pergunta
ao placar.

**Seus números vão diferir** destes em todos os dígitos, porque dependem dos seus processadores e do
seu disco. O que deve bater é o formato: a lista de pedidos e a página de pedido abaixo de um par de
milissegundos, a busca por etiqueta e o painel nas dezenas, a contagem de pendentes nas centenas.

## Por que tem este formato

Os pesos não foram medidos numa loja real. São um palpite sobre uma loja plausível: muitas leituras
baratas, algumas caras, um fio de escritas. Isso basta para dar ao placar um quadro realista para
mostrar, e é o motivo de a aula 22 dedicar uma seção inteira ao que torna uma carga
**representativa** — no dia em que você precisar medir uma mudança que importa, uma carga de palpite
é a primeira coisa a trocar.

Dois dos scripts mudam o banco. O `place-order.sql` insere um pedido e uma linha e atualiza o total
numa transação, o que torna as escritas desta carga escritas de verdade, com travas e índices para
manter. Cada execução dele acrescenta uma linha a `orders`. A seção 05 desta aula mostra como pôr o
`market` de volta nas linhas que o `market.sql` fez.
