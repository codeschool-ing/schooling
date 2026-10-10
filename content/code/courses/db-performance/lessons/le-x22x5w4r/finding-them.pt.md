---
title: Encontrando as transações mais antigas
version: 1
---

Os timeouts encerram o que passar por eles. Antes de configurá-los, e em qualquer servidor onde
outra pessoa os configurou, você precisa da outra metade: uma consulta que responda **quem está
segurando o horizonte agora, e há quanto tempo**. É um `SELECT` na `pg_stat_activity`, que vale
guardar num arquivo:

```sh
cat > ~/oldest.sql <<'SQL'
-- oldest.sql: every session holding the horizon back, oldest first.
SELECT pid, state, backend_xid AS xid, backend_xmin AS xmin,
       greatest(age(backend_xid), age(backend_xmin)) AS xid_age,
       date_trunc('second', now() - xact_start) AS open_for,
       left(query, 40) AS last_query
FROM pg_stat_activity
WHERE (backend_xid IS NOT NULL OR backend_xmin IS NOT NULL)
  AND pid <> pg_backend_pid()
ORDER BY xid_age DESC;
SQL
```

Duas colunas seguram o horizonte. **`backend_xid`** é o número da própria transação da sessão, que
uma transação só ganha quando escreve; **`backend_xmin`** é o snapshot mais antigo que ela está
usando. `age()` transforma qualquer um dos dois em "quantas transações atrás", que é a unidade que
importa: um horizonte não é velho por causa do relógio, é velho por causa de quanto foi escrito
desde então. `open_for` é a visão do relógio, a partir de `xact_start`, e `last_query` é o último
comando que a sessão mandou — numa sessão ociosa, o que ela terminou, não um que esteja rodando. O
`WHERE` tira a sua própria sessão, que sempre tem um snapshot enquanto roda a consulta.

## Quatro sessões, três suspeitos

Para ver cada tipo de uma vez, abra mais quatro terminais e deixe cada um num estado diferente:

1. `BEGIN;` e `SELECT count(*) FROM sellers;` — uma transação no nível padrão que só leu;
2. `BEGIN;` e `UPDATE sellers SET name = 'Seller 2 (verified)' WHERE id = 2;` — uma transação que
   escreveu;
3. `BEGIN ISOLATION LEVEL REPEATABLE READ;` e `SELECT count(*) FROM sellers;` — o tipo da Sessão A;
4. `SELECT pg_sleep(40);` — um comando que ainda está rodando, no papel de um relatório longo.

Rode o robô da seção 03 por alguns segundos para que algumas transações passem, e então o arquivo:

```
market=# \i oldest.sql
 pid  |        state        |   xid   |  xmin   | xid_age | open_for |                last_query                
------+---------------------+---------+---------+---------+----------+------------------------------------------
  963 | idle in transaction | 1380441 |         |   30733 | 00:00:07 | UPDATE sellers SET name = 'Seller 2 (ver
  988 | idle in transaction |         | 1380441 |   30733 | 00:00:06 | SELECT count(*) FROM sellers;
 1002 | active              |         | 1380441 |   30733 | 00:00:06 | SELECT pg_sleep(40)
(3 rows)

Time: 3.701 ms
```

**Três linhas para quatro sessões**, e a que falta é a primeira: a transação `READ COMMITTED` que só
leu não segura nada, como a seção 02 disse. As outras três estão aqui, e são as três coisas a
procurar num servidor de verdade.

- A **que escreveu** tem um número de transação próprio, `1380441`, e nenhum snapshot enquanto está
  ociosa. Tudo o que foi escrito depois dela espera por ela.
- A sessão **`REPEATABLE READ`** não tem número próprio, porque não escreveu, e tem um snapshot que
  começou no mesmo ponto.
- O **comando em execução** está `active`, não ocioso, e segura o snapshot enquanto roda. O
  `idle_in_transaction_session_timeout` nunca o tocaria; o `statement_timeout`, sim.

As três têm `30733` transações de idade, os poucos segundos de trabalho do robô, e é por isso que
`xid_age` é a coluna pela qual ordenar e alertar: **ela cresce com o estrago**, enquanto `open_for`
cresce com o relógio, haja escrita ou não.

## Encerrando uma

Achada a sessão, a correção é encerrar a transação dela: pedir a quem a abriu, ou cancelá-la ou
terminá-la pelo servidor. `pg_cancel_backend` e `pg_terminate_backend`, e a diferença entre eles, são
o assunto da aula 13; aqui a ordem importa mais que a ferramenta. Primeiro a **que escreveu**, porque
ela segura travas além do horizonte. Depois o snapshot mais antigo. Depois olhe de novo, porque a
próxima mais antiga vira o horizonte no instante em que a primeira sai, e ela pode ser só um pouco
mais nova.

## Dois que seguram e não são sessões

Nem todo horizonte pertence a uma conexão, e os que não pertencem são os fáceis de deixar passar,
porque a `pg_stat_activity` não tem linha para eles:

```
market=# SELECT gid, prepared, owner FROM pg_prepared_xacts;
 gid | prepared | owner 
-----+----------+-------
(0 rows)

Time: 2.138 ms

market=# SELECT slot_name, xmin, catalog_xmin FROM pg_replication_slots;
 slot_name | xmin | catalog_xmin 
-----------+------+--------------
(0 rows)

Time: 0.866 ms

market=# BEGIN;
BEGIN
Time: 0.185 ms

market=*# PREPARE TRANSACTION 'pay-1';
ERROR:  prepared transactions are disabled
HINT:  Set max_prepared_transactions to a nonzero value.
Time: 0.966 ms
```

- **Transações preparadas.** `PREPARE TRANSACTION` é a primeira metade de um commit em duas fases: a
  transação está terminada do ponto de vista do cliente e guardada pelo servidor, com as travas e o
  horizonte, até alguém rodar `COMMIT PREPARED` ou `ROLLBACK PREPARED` — depois de qualquer
  reinício, e pelo tempo que for. Um coordenador que cai entre as duas metades deixa uma para trás de
  que ninguém se lembra. Elas vêm **desligadas**, como o erro diz, com `max_prepared_transactions` em
  0, e uma `pg_prepared_xacts` vazia é o que você quer ver num servidor onde estão ligadas.
- **Slots de replicação.** Um slot guarda o que uma réplica ou um consumidor de mudanças ainda
  precisa, e as colunas `xmin` e `catalog_xmin` dele são um horizonte como qualquer outro. Um slot
  cujo consumidor sumiu segura o horizonte, e o WAL, para sempre. Montar replicação e slots é assunto
  de `db-reliability`; aqui, uma lista vazia é a resposta saudável.

Uma réplica também pode segurar o horizonte do primário através do `hot_standby_feedback`, que
devolve o snapshot mais antigo da réplica para que os relatórios longos dela não sejam cancelados; a
aula 20 encontra essa troca pelo lado da réplica.

Então a verificação completa são três consultas — `~/oldest.sql`, `pg_prepared_xacts` e
`pg_replication_slots` — e o número a vigiar em todas é a idade em transações. Termine as quatro
sessões, com `ROLLBACK` na segunda para que o vendedor 2 mantenha o nome, e feche todo terminal em
`market`. O robô de preços mudou `products` durante toda esta aula, então ponha o banco de volta como
a aula 16 começa:

```
ana@vm:~$ ~/reset-market.sh
CREATE EXTENSION
Time: 18.503 ms
CREATE INDEX
Time: 1162.979 ms (00:01.163)
```
