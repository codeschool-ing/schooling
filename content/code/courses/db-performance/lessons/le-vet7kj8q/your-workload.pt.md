---
title: Uma carga com o formato da sua
version: 1
---

A aula 2 escreveu seis scripts e lhes deu os pesos 50, 25, 10, 10, 4 e 1, e disse com todas as
letras que os pesos eram um palpite. Um palpite serve para gerar tráfego para olhar. Não serve para
um benchmark cujo número vai decidir alguma coisa, porque **a mistura é a carga**: os mesmos seis
scripts em outras proporções são outra carga, com outro gargalo.

Uma carga reproduz a real em quatro frentes, e cada uma pode ser conferida:

| o quê | de onde vem o valor real |
|---|---|
| **quais comandos**, em que proporção | o `pg_stat_statements` do servidor de produção |
| **quais parâmetros** — que clientes, que vendedores, que datas | os logs da própria aplicação, ou o formato dos dados |
| **quantos ao mesmo tempo** | o número de conexões ativas na hora de pico |
| **contra quantos dados** | o tamanho do banco de produção, ou uma cópia dele |

As duas últimas são armadilhas à parte, e a seção 05 trata delas. Esta seção faz as duas primeiras.

## Pesos a partir da contagem

O `pg_stat_statements` já conta quantas vezes cada comando rodou. Zere-o no começo de um período que
represente a carga que importa — a hora de pico de um dia útil comum, não a madrugada calma — e leia
no fim. Cada script precisa de um comando que o identifique, e a fração de chamadas dele é o peso do
script. Este arquivo faz a leitura:

```sh
cat > ~/workload/weights.sql <<'SQL'
-- weights.sql: each script's share of the calls pg_stat_statements counted,
-- read through the one statement that identifies the script.
SELECT CASE
         WHEN query LIKE 'SELECT id, placed_at%'          THEN 'customer-orders.sql'
         WHEN query LIKE 'SELECT p.title%'                THEN 'order-page.sql'
         WHEN query LIKE 'SELECT id, title%'              THEN 'tag-search.sql'
         WHEN query LIKE 'INSERT INTO orders%'            THEN 'place-order.sql'
         WHEN query LIKE 'SELECT date_trunc%'             THEN 'seller-dashboard.sql'
         WHEN query LIKE 'SELECT count(*) FROM orders WHERE status%' THEN 'pending-count.sql'
       END AS script,
       calls,
       round(100.0 * calls / sum(calls) OVER (), 1) AS weight
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'market')
  AND (query LIKE 'SELECT id, placed_at%' OR query LIKE 'SELECT p.title%'
       OR query LIKE 'SELECT id, title%' OR query LIKE 'INSERT INTO orders%'
       OR query LIKE 'SELECT date_trunc%'
       OR query LIKE 'SELECT count(*) FROM orders WHERE status%')
ORDER BY calls DESC;
SQL
```

O `place-order.sql` é contado pelo primeiro `INSERT`, porque o `BEGIN`, o segundo `INSERT`, o
`UPDATE` e o `COMMIT` dele contariam a mesma transação mais quatro vezes.

Na sua máquina não há produção, então o tráfego a ler precisa ser gerado, e o substituto honesto é a
própria carga da aula 2: se a consulta estiver certa, ela tem de devolver os pesos que a aula 2
colocou. Zere a contagem, rode a carga por um minuto jogando a saída fora, e leia:

```
market=# SELECT pg_stat_statements_reset();
 pg_stat_statements_reset 
--------------------------
 
(1 row)

Time: 2.049 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 60 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market > /dev/null
ana@vm:~$ psql market -f ~/workload/weights.sql
        script        | calls | weight 
----------------------+-------+--------
 customer-orders.sql  | 33449 |   50.0
 order-page.sql       | 16668 |   24.9
 place-order.sql      |  6728 |   10.1
 tag-search.sql       |  6706 |   10.0
 seller-dashboard.sql |  2629 |    3.9
 pending-count.sql    |   695 |    1.0
(6 rows)

Time: 3.941 ms
```

**50.0, 24.9, 10.1, 10.0, 3.9 e 1.0** — os pesos que a aula 2 escreveu, recuperados só a partir do que
o servidor contou. Essa ida e volta é a prova de que a leitura funciona. Num servidor real o mesmo
arquivo imprime a mistura real, e esses números viram o `@50`, o `@25` e os demais da linha de comando
do `pgbench`.

## Os parâmetros importam tanto quanto os comandos

A linha `\set` de um script decide **quais linhas** cada execução toca, e `random(a, b)` deixa todo
valor igualmente provável. O tráfego real nunca é assim. No `market`, o vendedor 1 tem um quarto de
todos os pedidos, e o script do painel da aula 2 o evita discretamente com `random(2, 1000)`. Um
painel consultado do jeito que vendedores reais consultariam — o maior com frequência, a cauda longa
raramente — é este arquivo, que difere do da aula 2 só na linha `\set`:

```sh
cat > ~/workload/seller-dashboard-skewed.sql <<'SQL'
-- The seller dashboard, asked about sellers the way real traffic does:
-- the biggest seller most often, the long tail rarely.
\set s random_zipfian(1, 1000, 1.07)
SELECT date_trunc('day', placed_at) AS day, count(*), sum(total_cents)
FROM orders
WHERE seller_id = :s AND placed_at >= '2025-12-01'
GROUP BY 1 ORDER BY 1;
SQL
```

`random_zipfian(1, 1000, 1.07)` sorteia o vendedor 1 com mais frequência, o vendedor 2 cerca de
metade das vezes, e assim por diante cauda abaixo. Rode cada versão sozinha por vinte segundos:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 20 -f seller-dashboard.sql market | grep -E "^(tps|latency)"
latency average = 9.016 ms
tps = 887.320360 (without initial connection time)
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 20 -f seller-dashboard-skewed.sql market | grep -E "^(tps|latency)"
latency average = 15.233 ms
tps = 525.177215 (without initial connection time)
```

**887 painéis por segundo com todo vendedor igualmente provável, 525 com a assimetria** — 9
milissegundos cada contra 15. O mesmo comando, os mesmos índices, o mesmo servidor; a única mudança é
sobre quais vendedores se perguntou, e o dezembro do vendedor grande tem muito mais linhas para
contar. Um benchmark montado sobre a versão uniforme teria prometido 70% mais capacidade de painel do
que a loja tem.

A mesma pergunta vale para todo `\set` de uma carga. Clientes que voltam têm mais chance de abrir os
seus pedidos do que clientes que compraram uma vez; os pedidos de hoje são lidos muito mais que os de
2023. Quando os parâmetros não podem ser lidos de logs, o formato dos dados é a melhor fonte seguinte:
as contagens por vendedor, por cliente, por dia, de um `GROUP BY` nas tabelas reais.

## Quantos clientes

O `-c 8` de toda execução deste curso é uma escolha para uma máquina de quatro processadores, não um
fato sobre a loja. O número de produção é a contagem de conexões **ativas** na hora de pico — o
`pg_stat_activity` com `state = 'active'`, amostrado a cada poucos segundos —, não o tamanho do pool
de conexões, cuja maior parte fica ociosa. A aula 16 trata do que conexões demais custam; aqui a
regra é só que o benchmark deve oferecer ao servidor a concorrência que ele de fato vê.
