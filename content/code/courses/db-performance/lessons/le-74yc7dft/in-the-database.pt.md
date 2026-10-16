---
title: Um cache que o banco mantém para você
version: 1
---

Tudo até aqui pôs um segundo sistema ao lado do PostgreSQL e fez a aplicação responsável por manter
os dois em sintonia. Existe um cache que mora **dentro** do banco, não precisa de segundo servidor e
não pode ser esquecido por um caminho de código que escreve: a **visão materializada**. É a
ferramenta errada para um valor que precisa estar fresco, e muitas vezes a certa para um resumo lido
o dia todo que pode ter alguns minutos de idade, o que descreve a maioria dos painéis.

Uma visão é uma consulta guardada: toda leitura a roda de novo. Uma visão materializada roda a
consulta uma vez, guarda as linhas como uma tabela e serve essas linhas a toda leitura até que alguém
mande rodar a consulta de novo. A crença a derrubar é a de que ela acompanha as suas tabelas, como um
índice acompanha. **Não acompanha.** É uma fotografia, atualizada só quando pedem.

## O painel de todos os vendedores, de uma vez

O painel do vendedor pergunta, por vendedor, quantos pedidos e quanto dinheiro em cada dia desde 1º de
dezembro. Em vez de perguntar uma vez por vendedor a cada recarga, calcule para todos os vendedores de
uma vez:

```
market=# SELECT sum(count) FROM (SELECT count(*) FROM orders WHERE seller_id = 42 AND placed_at >= '2025-12-01' GROUP BY date_trunc('day', placed_at)) AS d;
 sum 
-----
  81
(1 row)

Time: 5.667 ms

market=# CREATE MATERIALIZED VIEW seller_days AS SELECT seller_id, date_trunc('day', placed_at)::date AS day, count(*) AS orders, sum(total_cents)::bigint AS total FROM orders WHERE placed_at >= '2025-12-01' GROUP BY 1, 2;
SELECT 27942
Time: 67.329 ms
```

A consulta ao vivo para o vendedor 42 levou **5,7 milissegundos** e achou **81** pedidos. A visão
materializada calculou o mesmo resumo para todos os vendedores em **67 milissegundos**: **27942**
linhas, uma por vendedor por dia. É todo o custo de preenchê-la, pago uma vez, por um comando.

## Atualizar sem trancar todo mundo do lado de fora

Uma atualização pode ser feita de dois jeitos. Um `REFRESH MATERIALIZED VIEW` simples reconstrói a
visão e a troca, segurando uma trava (lock) que **bloqueia toda leitura da visão** enquanto trabalha:
num painel lido o dia todo, é uma pausa para todo mundo a cada atualização. O `REFRESH MATERIALIZED
VIEW CONCURRENTLY` calcula as linhas novas ao lado das antigas e aplica só as diferenças, então os
leitores seguem lendo as linhas antigas até ele terminar. Ele precisa de um jeito de casar uma linha
nova com uma antiga, e diz isso:

```
market=# REFRESH MATERIALIZED VIEW CONCURRENTLY seller_days;
ERROR:  cannot refresh materialized view "public.seller_days" concurrently
HINT:  Create a unique index with no WHERE clause on one or more columns of the materialized view.
Time: 0.957 ms

market=# CREATE UNIQUE INDEX ON seller_days (seller_id, day);
CREATE INDEX
Time: 17.745 ms
```

**`cannot refresh materialized view "public.seller_days" concurrently`**, com a dica de criar um
índice único sem cláusula `WHERE`. `(seller_id, day)` identifica uma linha desta visão, então esse é
o índice, e ele também serve à busca do próprio painel por vendedor.

## Velha até pedirem, e o custo de pedir

Leia o vendedor 42 na visão, faça um pedido para o vendedor 42, leia de novo, atualize, leia de novo:

```
market=# SELECT sum(orders) FROM seller_days WHERE seller_id = 42;
 sum 
-----
  81
(1 row)

Time: 0.961 ms

market=# INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (42, 42, now(), 'pending', 1990);
INSERT 0 1
Time: 5.647 ms

market=# SELECT sum(orders) FROM seller_days WHERE seller_id = 42;
 sum 
-----
  81
(1 row)

Time: 0.537 ms

market=# REFRESH MATERIALIZED VIEW CONCURRENTLY seller_days;
REFRESH MATERIALIZED VIEW
Time: 318.175 ms

market=# SELECT sum(orders) FROM seller_days WHERE seller_id = 42;
 sum 
-----
  82
(1 row)

Time: 0.972 ms
```

Pela visão, o painel do vendedor 42 custa **0,96 milissegundo**, contra 5,7 da consulta ao vivo. O
pedido novo não apareceu, **81** antes e depois dele, até a atualização, e então **82**. A atualização
concorrente levou **318 milissegundos**, durante os quais todo leitor continuou recebendo respostas.
Compare com a atualização simples:

```
market=# REFRESH MATERIALIZED VIEW seller_days;
REFRESH MATERIALIZED VIEW
Time: 112.877 ms
```

**113 milissegundos**, cerca de um terço da concorrente, porque ela só reconstrói, enquanto a
concorrente ainda compara as linhas antigas com as novas. A concorrente é mais lenta e não bloqueia
leitores; a simples é mais rápida e os bloqueia. Para uma visão lida o dia todo, mais lenta e
invisível é a troca melhor.

## Quando usar cada um

A atualização é algo que você agenda: pelo `cron`, pela aplicação depois de um lote de escritas, ou
com uma extensão como o `pg_cron`. Toda atualização recalcula a visão inteira, então o custo dela é o
custo da consulta completa, por menos linhas que tenham mudado, e a visão está tão velha quanto o
tempo desde a última atualização. Isso faz dos dois tipos de cache complementos, não rivais:

| | uma visão materializada | Redis, cache-aside |
|---|---|---|
| onde mora | dentro do PostgreSQL | num segundo servidor |
| quem o mantém em sintonia | uma atualização agendada | todo caminho de código que escreve |
| quão velho | desde a última atualização, para todas as chaves de uma vez | até o TTL, por chave |
| custo de uma atualização ou de uma falta | a consulta inteira, para todos os vendedores | uma consulta, para um vendedor |
| o que economiza | o trabalho, mas cada leitura ainda é uma consulta | o trabalho e a ida ao banco |

Uma loja movimentada costuma ter os dois: uma visão materializada para que o resumo caro seja
calculado uma vez por minuto em vez de uma vez por vendedor, e um cache na frente dela para que as
leituras deixem de chegar ao PostgreSQL.

## Pondo a máquina de volta

Pare o Redis, que o `apt` deixou para subir em todo boot, e ponha o `market` de volta:

```
ana@vm:~$ sudo systemctl stop redis-server
```

O `sudo systemctl disable redis-server` impede que ele suba no próximo boot; as aulas depois desta
não o usam. A visão materializada, o índice dela e os pedidos que esta aula fez vão embora com o
`~/reset-market.sh`.
