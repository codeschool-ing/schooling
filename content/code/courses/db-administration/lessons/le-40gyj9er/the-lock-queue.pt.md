---
title: A fila de locks
version: 1
---

O medo comum ao mudar uma tabela em produção é o medo errado. As pessoas se preocupam com o tempo
que o próprio `ALTER TABLE` vai levar. **Muitos comandos `ALTER TABLE` terminam em milissegundos e
mesmo assim derrubam um site**, por causa do que acontece enquanto eles esperam para começar.

Quase toda forma de `ALTER TABLE` precisa de um lock **`ACCESS EXCLUSIVE`** na tabela: ninguém mais
pode ler nem escrever nela enquanto a mudança é feita. Um `SELECT` comum segura um lock `ACCESS
SHARE` enquanto a transação dele durar, e os dois conflitam. Então o `ALTER` espera o `SELECT`. Essa
parte é esperada. A parte que surpreende é a seguinte: **toda consulta que chega depois do `ALTER`
espera atrás dele**, até um `SELECT` que não conflitaria em nada com o primeiro `SELECT`. O
PostgreSQL concede locks na ordem em que foram pedidos, então nada fura a fila passando à frente de
um `ACCESS EXCLUSIVE` que espera.

## Uma cópia para trabalhar

Esta lição muda uma tabela, então ela trabalha numa cópia de `orders` e não na própria `orders`.
Toda lição seguinte espera o `shop` como a lição 4 o deixou, e a última seção apaga a cópia:

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# CREATE TABLE orders_live AS SELECT * FROM orders;
SELECT 1000000
Time: 859.081 ms

shop=# \q
```

Um milhão de linhas, copiadas em menos de um segundo na máquina da gravação. `CREATE TABLE … AS`
copia as colunas e as linhas e mais nada: nem chave primária, nem índice, nem `NOT NULL`. A seção
sobre restrições devolve a chave primária sem bloquear ninguém.

## Três terminais

Abra três terminais no servidor e rode `psql shop` em cada um. Peça primeiro o id de processo de
cada um, para distingui-los depois. O primeiro abre uma transação e lê a tabela, como faz um
relatório ou uma página lenta, e depois fica dentro da transação:

```
ana@db:~$ psql shop
shop=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
            201
(1 row)

shop=# BEGIN;
BEGIN

shop=*# SELECT count(*) FROM orders_live;
  count  
---------
 1000000
(1 row)
```

O `*` em `shop=*#` é o psql dizendo que há uma transação aberta. O `SELECT` terminou, e o lock dele
não foi liberado: **um lock dura até o fim da transação**, não até o fim do comando.

No segundo terminal, a mudança de esquema. Acrescentar uma coluna sem default é uma das mudanças mais
baratas que existem, como mede a seção depois da próxima:

```
ana@db:~$ psql shop
shop=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
            203
(1 row)

shop=# \timing on
Timing is on.

shop=# ALTER TABLE orders_live ADD COLUMN note text;
ALTER TABLE
Time: 3913.761 ms (00:03.914)
```

Ele não volta. E no terceiro terminal, o tipo de consulta que um site manda cem vezes por segundo:

```
ana@db:~$ psql shop
shop=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
            205
(1 row)

shop=# \timing on
Timing is on.

shop=# SELECT status FROM orders_live WHERE id = 1;
 status 
--------
 paid
(1 row)

Time: 2666.672 ms (00:02.667)
```

Essa também não volta.

## Vendo a fila

Um quarto terminal enxerga a fila inteira. O `pg_stat_activity` tem uma linha por conexão, e
`pg_blocking_pids()` dá os processos pelos quais um processo está esperando:

```
ana@db:~$ psql shop
shop=# SELECT pid, pg_blocking_pids(pid) AS blocked_by, state, wait_event_type, wait_event, left(query, 45) AS query FROM pg_stat_activity WHERE datname = 'shop' AND pid <> pg_backend_pid() ORDER BY backend_start;
 pid | blocked_by |        state        | wait_event_type | wait_event |                     query                     
-----+------------+---------------------+-----------------+------------+-----------------------------------------------
 201 | {}         | idle in transaction | Client          | ClientRead | SELECT count(*) FROM orders_live;
 203 | {201}      | active              | Lock            | relation   | ALTER TABLE orders_live ADD COLUMN note text;
 205 | {203}      | active              | Lock            | relation   | SELECT status FROM orders_live WHERE id = 1;
(3 rows)

shop=# SELECT pid, mode, granted FROM pg_locks WHERE relation = 'orders_live'::regclass ORDER BY granted DESC, pid;
 pid |        mode         | granted 
-----+---------------------+---------
 201 | AccessShareLock     | t
 203 | AccessExclusiveLock | f
 205 | AccessShareLock     | f
(3 rows)
```

Leia de cima para baixo:

- A primeira sessão está **`idle in transaction`**. A espera dela é `ClientRead`, esperando o
  cliente mandar o próximo comando: ela não está fazendo nada, e segura um `AccessShareLock` que foi
  concedido.
- O `ALTER` está `active` e esperando: `wait_event_type` é `Lock` e `wait_event` é `relation`, um
  lock numa tabela. `blocked_by` aponta a primeira sessão.
- O `SELECT` também espera, e **`blocked_by` aponta o `ALTER`**, não a primeira sessão. O
  `AccessShareLock` dele não conflita com o que já foi concedido; conflita com o
  `AccessExclusiveLock` na fila à frente dele.

O `pg_locks` diz o mesmo numa coluna: `granted` é `t` para o lock que a primeira sessão segura e `f`
para os dois atrás dele. Numa tabela movimentada essa lista de `f` cresce a cada consulta que chega,
as conexões se acumulam até o `max_connections` recusar a próxima, e o site está fora do ar enquanto
o `ALTER` ainda não fez nada.

## Soltando

Faça o commit no primeiro terminal:

```
shop=*# COMMIT;
COMMIT
```

O `ALTER` recebe o lock, acrescenta a coluna num instante e o libera; o `SELECT` roda logo depois.
Volte ao segundo e ao terceiro terminais: cada um informa `Time:` em segundos, e quase tudo foi
espera. O trabalho em si levou milissegundos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Uma linha do tempo de três sessões. A sessão 1 segura um lock compartilhado até o commit. A sessão 2, o ALTER, espera da chegada até esse commit e depois roda por um instante. A sessão 3 chega depois do ALTER e espera atrás dele, embora não conflite com a sessão 1, e só roda depois que o ALTER termina.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"16\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">1  o relatório</text><line x1=\"150\" y1=\"40\" x2=\"700\" y2=\"40\" stroke=\"var(--scan)\" stroke-width=\"1\"></line><text x=\"16\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">2  o ALTER</text><line x1=\"150\" y1=\"90\" x2=\"700\" y2=\"90\" stroke=\"var(--scan)\" stroke-width=\"1\"></line><text x=\"16\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">3  uma página</text><line x1=\"150\" y1=\"140\" x2=\"700\" y2=\"140\" stroke=\"var(--scan)\" stroke-width=\"1\"></line><rect x=\"160\" y=\"28\" width=\"360\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">segura ACCESS SHARE, idle in transaction</text><rect x=\"250\" y=\"78\" width=\"270\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"260\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">espera por ACCESS EXCLUSIVE</text><rect x=\"520\" y=\"78\" width=\"14\" height=\"24\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">roda</text><rect x=\"330\" y=\"128\" width=\"204\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"340\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">espera atrás do ALTER</text><rect x=\"534\" y=\"128\" width=\"10\" height=\"24\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">roda</text><line x1=\"520\" y1=\"18\" x2=\"520\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"2 3\"></line><text x=\"520\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">COMMIT</text><line x1=\"150\" y1=\"200\" x2=\"700\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"700\" y=\"214\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "O ALTER precisa de poucos milissegundos de trabalho e espera segundos pelo lock. Tudo o que chega depois dele espera o mesmo tanto, e essa espera é a queda do sistema.", "same": ["COMMIT"]}
```

**O perigo nunca é só o `ALTER`.** É o `ALTER` multiplicado pelo que estiver segurando a tabela quando
ele chega, e a transação longa que você não sabia que existia é a culpada de costume. As lições 12 e
13 de `db-performance` tratam dos modos de lock a fundo e de como achar quem bloqueia num servidor
movimentado; a próxima seção é o hábito que torna seguro tentar uma mudança de esquema sem saber
isso de antemão.
