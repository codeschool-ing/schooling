---
title: Chegando ao max_connections
version: 1
---

Como cada conexão é um processo com memória e uma vaga reservada para ela na memória compartilhada,
o número delas é fixado quando o servidor inicia. Três configurações decidem isso:

```
shop=# SHOW max_connections;
 max_connections 
-----------------
 100
(1 row)

shop=# SHOW superuser_reserved_connections;
 superuser_reserved_connections 
--------------------------------
 3
(1 row)

shop=# SHOW reserved_connections;
 reserved_connections 
----------------------
 0
(1 row)

shop=# SHOW shared_memory_size;
 shared_memory_size 
--------------------
 143MB
(1 row)
```

**O `max_connections` é o total, e as três últimas vagas dele são guardadas para superusuários.** O
`reserved_connections`, novo no PostgreSQL 16, guarda mais vagas para papéis que receberam
`pg_use_reserved_connections`, como um papel de monitoramento, e é zero por padrão. O
`shared_memory_size` é o que o servidor pediu ao kernel ao iniciar, e ele volta na próxima seção.

Cem é muito mais do que cinco terminais conseguem encher, então baixe o valor por um tempo. O
`max_connections` tem o contexto `postmaster` na `pg_settings`, que a lição 5 mostrou que quer dizer
reinício e não reload. Você também precisa de um papel comum para ocupar as vagas comuns, porque a
`ana` é superusuária. O mais simples para conectar é um usuário do sistema operacional com um papel
do mesmo nome, para que a autenticação peer da lição 3 o deixe entrar:

```
ana@db:~$ sudo useradd --create-home app
ana@db:~$ createuser app
ana@db:~$ psql shop -c "GRANT SELECT, UPDATE ON customers, orders TO app"
GRANT
ana@db:~$ psql shop -c "ALTER SYSTEM SET max_connections = 5"
ALTER SYSTEM
ana@db:~$ sudo systemctl restart postgresql@16-main
ana@db:~$ psql shop -c "SHOW max_connections" -c "SHOW shared_memory_size"
 max_connections 
-----------------
 5
(1 row)

 shared_memory_size 
--------------------
 139MB
(1 row)
```

O `GRANT` deixa o `app` ler e mudar as duas tabelas, o que uma seção adiante precisa; a lição 12
trata de grants. Cinco vagas, três delas reservadas, deixam duas para o `app`.

## A primeira recusa

Abra dois terminais como `app`, cada um com uma consulta longa, para que as duas vagas comuns fiquem
ocupadas:

```sh
sudo -u app psql shop -c "SELECT pg_sleep(600)"
```

Depois tente um terceiro:

```
ana@db:~$ sudo -u app psql shop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  remaining connection slots are reserved for roles with the SUPERUSER attribute
ana@db:~$ psql shop -c "SELECT usename, count(*) FROM pg_stat_activity WHERE backend_type = 'client backend' GROUP BY usename"
 usename | count 
---------+-------
 ana     |     1
 app     |     2
(2 rows)
```

**O `app` é recusado, e a `ana` ainda entra**, numa das vagas reservadas, que é exatamente para o
que elas servem: quando uma aplicação gastou todas as vagas comuns, um administrador ainda consegue
conectar, olhar e agir. A contagem mostra as duas sessões do `app` e a que pergunta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 200\" role=\"img\" aria-label=\"Cinco vagas de conexão com max_connections igual a 5. As duas primeiras servem a qualquer papel e estão ocupadas por app. As três últimas são reservadas a superusuários; uma está ocupada por ana e duas estão livres. Uma terceira conexão como app é recusada; ana é aceita numa vaga reservada; com as cinco ocupadas, todo papel é recusado.\"><rect x=\"40\" y=\"60\" width=\"116\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"98.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vaga 1</text><text x=\"98.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">app</text><rect x=\"168\" y=\"60\" width=\"116\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"226.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vaga 2</text><text x=\"226.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">app</text><rect x=\"296\" y=\"60\" width=\"116\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"354.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vaga 3</text><text x=\"354.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">ana</text><rect x=\"424\" y=\"60\" width=\"116\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"482.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vaga 4</text><text x=\"482.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">livre</text><rect x=\"552\" y=\"60\" width=\"116\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"610.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vaga 5</text><text x=\"610.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">livre</text><text x=\"162.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">max_connections − 3: qualquer papel</text><text x=\"482.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">superuser_reserved_connections = 3</text><text x=\"40\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Uma terceira conexão como app: recusada, as vagas livres são reservadas a superusuários.</text><text x=\"40\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Uma conexão como ana, superusuária: aceita numa vaga reservada.</text><text x=\"40\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Com as cinco ocupadas, por quem for: \"sorry, too many clients already\", para todo papel.</text></svg>", "caption": "Cinco vagas, três delas guardadas para superusuários. A reserva só ajuda enquanto os papéis que ocupam as outras vagas não são superusuários."}
```

## A segunda recusa

A reserva só protege você de papéis que não são superusuários. Abra mais três terminais como `ana`,
cada um com o seu `pg_sleep`, e as cinco vagas ficam ocupadas. Agora ninguém entra, nem o papel
`postgres`:

```
ana@db:~$ psql shop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  sorry, too many clients already
ana@db:~$ sudo -u postgres psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  sorry, too many clients already
```

**`sorry, too many clients already` quer dizer que a reserva também acabou.** Uma aplicação que
conecta como superusuária ocupa vagas reservadas como quaisquer outras, e no dia em que ela vazar
conexões não sobra porta para a pessoa que tenta consertar. Só isso já é motivo para aplicações
nunca serem superusuárias, antes dos outros motivos da lição 11.

## Voltando a entrar

Sem conexão não há SQL, então a entrada é pelo shell. Um backend é um processo, e **`SIGTERM` para
um backend é exatamente o que o `pg_terminate_backend` manda**: o backend desfaz a transação e sai
de forma limpa. O `pkill` manda `SIGTERM` por padrão; o `--full` casa com o nome que o `ps` mostrou,
e o `--oldest` escolhe um:

```
ana@db:~$ sudo pkill --oldest --full 'postgres: 16/main: ana shop'
ana@db:~$ psql shop -c "SELECT count(pg_terminate_backend(pid)) FROM pg_stat_activity WHERE backend_type = 'client backend' AND pid <> pg_backend_pid()"
 count 
-------
     4
(1 row)
```

Uma vaga liberada bastou para uma sessão, e essa sessão encerrou as outras quatro: todo backend de
cliente menos o dela, `pg_backend_pid()`. **Nunca use `kill -9` num backend.** Um backend que morre
sem arrumar a casa pode ter deixado a memória compartilhada mudada pela metade, então o postmaster
trata isso como uma queda e reinicia todos os processos, a recuperação que a lição 8 mostrou. O
`SIGTERM` custa uma sessão; o `SIGKILL` custa todas. Reiniciar o serviço inteiro também faz você
entrar, pelo mesmo preço.
