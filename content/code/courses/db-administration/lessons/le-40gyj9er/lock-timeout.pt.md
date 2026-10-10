---
title: Esperar por um lock, por pouco tempo
version: 1
---

Nem sempre dá para saber o que segura uma tabela quando você a muda. **Dá para decidir quanto tempo a
sua mudança pode esperar**, e isso transforma uma queda numa tentativa que falhou. O `lock_timeout` é
a configuração: um comando que esperou esse tanto por um lock desiste com um erro, sai da fila e deixa
passar tudo o que estava atrás dele.

Os mesmos três terminais, com uma diferença: o segundo define `lock_timeout` antes do `ALTER`.

```
ana@db:~$ psql shop
shop=# BEGIN;
BEGIN

shop=*# SELECT count(*) FROM orders_live;
  count  
---------
 1000000
(1 row)
```

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# SET lock_timeout = '2s';
SET
Time: 0.252 ms

shop=# ALTER TABLE orders_live ADD COLUMN source text;
ERROR:  canceling statement due to lock timeout
Time: 2000.671 ms (00:02.001)
```

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# SELECT status FROM orders_live WHERE id = 1;
 status 
--------
 paid
(1 row)

Time: 1238.296 ms (00:01.238)
```

**O `ALTER` desistiu depois de dois segundos**, com `canceling statement due to lock timeout`, e o
`SELECT` do terceiro terminal rodou no momento em que ele saiu da fila. O terceiro terminal ainda
esperou, por parte desses dois segundos, e esse é o preço: o `lock_timeout` não impede a fila de se
formar, ele limita quanto ela dura. Dois segundos de páginas lentas são um incidente que ninguém
reporta. Vinte minutos são o que acorda você.

**`lock_timeout` não é `statement_timeout`.** O primeiro conta só o tempo esperando por um lock; o
segundo conta o comando inteiro, trabalho incluído. **Uma reescrita que precisa de um minuto de
trabalho e recebe o lock na hora passa bem com um `lock_timeout` de dois segundos**, e seria morta
por um `statement_timeout` de dois segundos.

## Tentar de novo

Uma mudança que desistiu não aconteceu, então alguma coisa precisa tentá-la de novo. Numa tabela
movimentada o lock está livre na maior parte do tempo, e uma tentativa alguns segundos depois costuma
consegui-lo. Salve isto como `retry-ddl.sh`:

```schooling-example
{"language": "bash", "file": "retry-ddl.sh", "parts": [{"code": "#!/usr/bin/env bash\n# retry-ddl.sh: one schema change, retried until it gets its lock quickly.\n# Run it with: bash retry-ddl.sh\nddl=\"ALTER TABLE orders_live ADD COLUMN source text\"", "note": "A mudança fica numa variável no topo, então o script é o mesmo para toda mudança que você fizer com ele."}, {"code": "for attempt in 1 2 3 4 5; do\n  if PGOPTIONS='-c lock_timeout=2s' psql -X -q shop -c \"$ddl\"; then\n    echo \"attempt $attempt: done\"\n    exit 0\n  fi", "note": "`PGOPTIONS` define o `lock_timeout` só para esta conexão, então o `ALTER` espera na fila por dois segundos no máximo. `-X` ignora o seu `.psqlrc` e `-q` deixa o psql quieto, então as únicas linhas são o erro e as do próprio script."}, {"code": "  echo \"attempt $attempt: gave up the queue; trying again in 3 s\" >&2\n  sleep 3\ndone", "note": "Entre tentativas ele espera mais do que esperou na fila. O que estava bloqueado atrás do `ALTER` roda nesse intervalo, e a transação que segura a tabela pode terminar."}, {"code": "echo \"no luck after $attempt attempts; find what holds the lock\" >&2\nexit 1", "note": "Cinco falhas seguidas significam que alguma coisa segura a tabela por muito tempo. Essa é uma pergunta para o `pg_stat_activity`, não para uma sexta tentativa."}]}
```

Para vê-lo funcionar, segure a tabela num terminal como antes, rode o script em outro e faça o commit
no primeiro alguns segundos depois:

```
ana@db:~$ psql shop
shop=# BEGIN;
BEGIN

shop=*# SELECT count(*) FROM orders_live;
  count  
---------
 1000000
(1 row)

shop=*# COMMIT;
COMMIT
```

```
ana@db:~$ bash retry-ddl.sh
ERROR:  canceling statement due to lock timeout
attempt 1: gave up the queue; trying again in 3 s
ERROR:  canceling statement due to lock timeout
attempt 2: gave up the queue; trying again in 3 s
attempt 3: done
```

Duas tentativas desistiram enquanto a transação estava aberta; a seguinte, depois do commit, recebeu
o lock e a coluna foi acrescentada. Nada esperou atrás do `ALTER` por mais de dois segundos em momento
nenhum.

**Toda mudança de esquema numa tabela em produção passa por algo assim**, seja este script, uma
configuração da ferramenta de migração que a sua aplicação usa, ou um `SET lock_timeout` no topo de
um arquivo de migração. O número é um julgamento sobre a aplicação: quanto tempo uma consulta pode
esperar antes que alguém perceba. De dois a cinco segundos é comum, e o
`idle_in_transaction_session_timeout` da lição 10 é a configuração que impede a transação esquecida
de segurar a tabela, para começo de conversa.
