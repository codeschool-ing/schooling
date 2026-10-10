---
title: Inchaço, medido
version: 1
---

Uma versão morta é uma curiosidade. Uma tabela atualizada alguns milhares de vezes por segundo
produz alguns milhares delas por segundo, e enquanto o horizonte está preso nenhuma pode sair. A
tabela cresce, e **toda consulta que lê a tabela paga pelo crescimento**, inclusive consultas que
não têm nada a ver com a transação que segura o horizonte. É esse o custo que o título desta aula
promete, e dá para medi-lo em um minuto.

## Uma tabela atualizada o dia inteiro

A carga da aula 2 escreve, mas sobretudo linhas novas. O que produz versões antigas depressa são as
mesmas linhas atualizadas sem parar: um contador de estoque, o último acesso de uma sessão, um preço.
Acrescente mais um script em `~/workload`, um robô que mexe no preço de um produto por vez:

```sh
cat > ~/workload/reprice.sql <<'SQL'
-- A pricing robot: one product's price nudged up or down, all day long.
\set p random(1, 50000)
\set delta random(-10, 10)
UPDATE products SET price_cents = price_cents + :delta WHERE id = :p;
SQL
```

Ele muda preços em `market`, então o fim desta aula põe o banco de volta com `~/reset-market.sh`.
Antes de rodá-lo, meça duas coisas: o tamanho de `products`, e quanto tempo leva a busca por tag da
aula 2, porque essa busca lê `products` inteira a cada execução (a aula 8 lhe dá um índice; até lá é
uma leitura sequencial, o que faz dela uma boa testemunha aqui):

```
market=# SELECT pg_size_pretty(pg_table_size('products')) AS size, n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'products';
  size   | n_live_tup | n_dead_tup 
---------+------------+------------
 5232 kB |      50000 |          0
(1 row)

Time: 9.243 ms
```

```
ana@vm:~/workload$ pgbench -n -T 10 -f tag-search.sql market | tail -3
latency average = 14.475 ms
initial connection time = 3.117 ms
tps = 69.084194 (without initial connection time)
```

**5232 kB** e **14,5 milissegundos** por busca. Agora deixe o robô rodar por trinta segundos, sem
mais nada aberto:

```
ana@vm:~/workload$ pgbench -n -c 4 -j 4 -T 30 -f reprice.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: reprice.sql
scaling factor: 1
query mode: simple
number of clients: 4
number of threads: 4
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 141981
number of failed transactions: 0 (0.000%)
latency average = 0.845 ms
initial connection time = 12.377 ms
tps = 4734.588470 (without initial connection time)
market=# SELECT pg_size_pretty(pg_table_size('products')) AS size, n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'products';
  size   | n_live_tup | n_dead_tup 
---------+------------+------------
 5544 kB |      50000 |       3341
(1 row)

Time: 5.729 ms
```

**141981 updates**, quase cinco mil por segundo, e a tabela passou de 5232 para 5544 kB. A maioria
das versões antigas foi limpa enquanto o robô trabalhava: quando uma página enche, o próximo comando
que a toca remove as versões que ninguém mais vê, sem esperar o `VACUUM`, e as novas reaproveitam o
espaço. As **3341** versões mortas que sobraram são as feitas desde a última arrumação da página
delas.

## Os mesmos trinta segundos, com uma transação aberta

Abra a Sessão A de novo e deixe-a quieta, exatamente como na seção anterior:

```
market=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
Time: 0.371 ms

market=*# SELECT count(*) FROM products;
 count 
-------
 50000
(1 row)

Time: 7.940 ms
```

e rode o robô outra vez, pelos mesmos trinta segundos:

```
ana@vm:~/workload$ pgbench -n -c 4 -j 4 -T 30 -f reprice.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: reprice.sql
scaling factor: 1
query mode: simple
number of clients: 4
number of threads: 4
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 139519
number of failed transactions: 0 (0.000%)
latency average = 0.860 ms
initial connection time = 7.677 ms
tps = 4651.674843 (without initial connection time)
market=# SELECT pg_size_pretty(pg_table_size('products')) AS size, n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'products';
 size  | n_live_tup | n_dead_tup 
-------+------------+------------
 19 MB |      49902 |     139122
(1 row)

Time: 4.456 ms
```

Um número parecido de updates, **139519**, e desta vez a tabela foi de 5544 kB para **19 MB**, mais
de três vezes o tamanho, com **139122** versões mortas dentro. Nada pôde ser limpo no caminho, então
cada update pôs a versão nova em espaço novo no fim da tabela. O `VACUUM` confirma que não é questão
de esperar:

```
market=# VACUUM (VERBOSE) products;
INFO:  vacuuming "market.public.products"
INFO:  finished vacuuming "market.public.products": index scans: 0
pages: 0 removed, 2484 remain, 2484 scanned (100.00% of total)
tuples: 0 removed, 189519 remain, 139519 are dead but not yet removable
removable cutoff: 1240919, which was 139520 XIDs old when operation ended
frozen: 0 pages from table (0.00% of total) had 0 tuples frozen
index scan not needed: 0 pages from table (0.00% of total) had 0 dead item identifiers removed
avg read rate: 0.000 MB/s, avg write rate: 0.000 MB/s
buffer usage: 5020 hits, 0 misses, 0 dirtied
WAL usage: 1 records, 0 full page images, 188 bytes
system usage: CPU: user: 0.02 s, system: 0.00 s, elapsed: 0.02 s
INFO:  vacuuming "market.pg_toast.pg_toast_16498"
INFO:  finished vacuuming "market.pg_toast.pg_toast_16498": index scans: 0
```

`139519 are dead but not yet removable`, e o corte tem `139520 XIDs old`: as transações do robô,
todas elas posteriores ao snapshot da Sessão A. E a testemunha, a busca por tag da aula 2, que nunca
tocou a Sessão A nem mudou preço nenhum:

```
ana@vm:~/workload$ pgbench -n -T 10 -f tag-search.sql market | tail -3
latency average = 21.121 ms
initial connection time = 3.176 ms
tps = 47.345969 (without initial connection time)
```

**21,1 milissegundos** contra 14,5 antes, porque uma leitura sequencial lê todas as páginas da
tabela, e agora são mais de três vezes mais páginas. Toda consulta que varre `products`, todo
relatório, todo backup, agora lê 19 MB para achar 5 MB de linhas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um gráfico de números de transação ao longo do tempo. O número da transação mais nova sobe de 1240919 para 1380439 enquanto o robô de preços roda por trinta segundos. O horizonte, o removable cutoff do VACUUM, fica parado em 1240919 enquanto a transação da Sessão A está aberta, e salta para 1380439 quando a Sessão A faz commit. O vão entre as duas linhas são as 139519 versões mortas que o VACUUM teve de manter.\"><text x=\"14\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">número da transação</text><path d=\"M100 230 L690 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M100 40 L100 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"94\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">1380439</text><text x=\"94\" y=\"220\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">1240919</text><path d=\"M190 220 L430 70 L520 70 L520 220 Z\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></path><path d=\"M110 220 L190 220 L430 70 L690 70\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><path d=\"M110 220 L520 220 L520 70 L690 70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"6 3\"></path><text x=\"310\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">transação mais nova</text><text x=\"528\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">horizonte (removable cutoff)</text><text x=\"510\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"end\" fill=\"var(--paper)\">139519 versões mortas</text><text x=\"510\" y=\"166\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">que o VACUUM não pode remover</text><path d=\"M110 230 L110 236\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M190 230 L190 236\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M430 230 L430 236\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M520 230 L520 236\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"110\" y=\"250\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">a Sessão A começa</text><text x=\"190\" y=\"268\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">o robô começa</text><text x=\"430\" y=\"250\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">o robô para, 30 s depois</text><text x=\"520\" y=\"268\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">a Sessão A faz commit</text></svg>", "caption": "O horizonte ao longo dos trinta segundos do robô. Tudo entre as duas linhas é uma versão morta que o VACUUM não pode remover."}
```

## Fechar a transação não encolhe a tabela

Faça commit na Sessão A e rode o `VACUUM` de novo:

```
market=*# COMMIT;
COMMIT
Time: 0.271 ms
```

```
market=# VACUUM (VERBOSE) products;
INFO:  vacuuming "market.public.products"
INFO:  finished vacuuming "market.public.products": index scans: 1
pages: 0 removed, 2484 remain, 2484 scanned (100.00% of total)
tuples: 139519 removed, 50000 remain, 0 are dead but not yet removable
removable cutoff: 1380439, which was 0 XIDs old when operation ended
frozen: 0 pages from table (0.00% of total) had 0 tuples frozen
index scan needed: 2473 pages from table (99.56% of total) had 137869 dead item identifiers removed
index "products_pkey": pages: 499 in total, 0 newly deleted, 0 currently deleted, 0 reusable
avg read rate: 0.000 MB/s, avg write rate: 0.000 MB/s
buffer usage: 7998 hits, 0 misses, 0 dirtied
WAL usage: 7929 records, 0 full page images, 1468201 bytes
system usage: CPU: user: 0.10 s, system: 0.00 s, elapsed: 0.11 s
INFO:  vacuuming "market.pg_toast.pg_toast_16498"
INFO:  finished vacuuming "market.pg_toast.pg_toast_16498": index scans: 0
pages: 0 removed, 0 remain, 0 scanned (100.00% of total)
tuples: 0 removed, 0 remain, 0 are dead but not yet removable
removable cutoff: 1380439, which was 0 XIDs old when operation ended
new relfrozenxid: 1380439, which is 139520 XIDs ahead of previous value
frozen: 0 pages from table (100.00% of total) had 0 tuples frozen
index scan not needed: 0 pages from table (100.00% of total) had 0 dead item identifiers removed
avg read rate: 0.000 MB/s, avg write rate: 0.000 MB/s
buffer usage: 28 hits, 0 misses, 0 dirtied
WAL usage: 1 records, 0 full page images, 188 bytes
system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
VACUUM
Time: 116.511 ms
market=# SELECT pg_size_pretty(pg_table_size('products')) AS size, n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'products';
 size  | n_live_tup | n_dead_tup 
-------+------------+------------
 19 MB |      50000 |          0
(1 row)

Time: 4.601 ms
```

`139519 removed`, nenhuma versão morta sobrando. E **a tabela continua com 19 MB.** O `VACUUM`
transforma o espaço das versões mortas em espaço livre dentro das páginas da tabela, pronto para
versões novas, mas não o devolve ao sistema operacional, a não ser páginas vazias no finalzinho do
arquivo — e as linhas vivas do robô estão espalhadas pela tabela toda. A busca quase não melhora,
porque continua lendo todas as páginas, e a maioria delas agora está quase vazia:

```
ana@vm:~/workload$ pgbench -n -T 10 -f tag-search.sql market | tail -3
latency average = 19.440 ms
initial connection time = 4.648 ms
tps = 51.439456 (without initial connection time)
```

**19,4 milissegundos**, contra 14,5 antes de tudo isso. O espaço livre vai ser reaproveitado pelos
próximos updates, então a tabela para de crescer; ela não volta sozinha a 5 MB. Recuperar o espaço
é reescrever a tabela, com `VACUUM FULL` ou uma ferramenta como o `pg_repack`, cada um com travas e
custos próprios. As aulas 14 e 15 de `db-administration` tratam do autovacuum e de medir e remover o
**inchaço** (bloat), o nome desse peso morto. O que importa aqui é a ordem dos fatos: meio minuto de
uma transação esquecida deixou uma tabela com mais de três vezes o seu tamanho, e o preço é pago por
toda consulta sobre ela até alguém reescrevê-la.

## Por que trinta segundos é o caso brando

O robô rodou por trinta segundos, a cerca de **4650 updates por segundo**. Uma transação esquecida
por uma pessoa ou por um bug fica aberta por horas, e a conta é cruel: nesse ritmo, uma hora são mais
de dezesseis milhões de versões mortas numa só tabela, todas mantidas, e toda outra tabela atualizada
naquela hora cresce do mesmo jeito. O sintoma que as pessoas notam não é a transação, para a qual
ninguém está olhando; é uma tela que lê `products` ficando mais lenta a tarde toda, sem motivo que
alguém encontre na própria consulta.

**Dois números** reconhecem isso sempre: a idade do corte que o `VACUUM VERBOSE` imprime, e uma
contagem de linhas mortas em `pg_stat_user_tables` que não diminui depois que o `VACUUM` rodou. A
seção 05 desta aula transforma o primeiro numa consulta que dá para rodar a cada minuto.
