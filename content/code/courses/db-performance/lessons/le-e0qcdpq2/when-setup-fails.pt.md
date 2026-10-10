---
title: Quando a instalação não funciona
version: 1
---

Tudo na seção anterior pode dar errado, e quase todo jeito de dar errado imprime uma frase dizendo
qual. Leia a frase antes de qualquer outra coisa: a parte depois de `FATAL:` ou `ERROR:` é o
servidor dizendo exatamente o que recusou.

## `role "…" does not exist`

```
ana@vm:~$ psql market
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

O servidor está rodando e não conhece você. O passo do `createuser` foi pulado, ou foi rodado numa
máquina diferente daquela em que você está digitando. Rode-o:

```sh
sudo -u postgres createuser --superuser $USER
```

Se a próxima tentativa disser `database "market" does not exist`, você avançou: agora o servidor
conhece você, e o passo que falta é o `createdb market`.

## `No such file or directory` no socket

```
ana@vm:~$ sudo systemctl stop postgresql
ana@vm:~$ psql market
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  the database system is shutting down
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@vm:~$ sudo systemctl start postgresql
```

O `psql` procurou o arquivo de socket do servidor, que é como dois programas no mesmo computador
conversam, e não havia nenhum, porque o servidor não está rodando. O `pg_lsclusters` diz isso na
quarta coluna: `down`. A transcrição o parou de propósito; na sua máquina, a causa comum é a
máquina virtual ter reiniciado e o serviço não ter voltado, ou uma configuração que você mudou ter
impedido a partida. `sudo systemctl start postgresql` o liga, e se ele voltar direto para `down`,
as últimas linhas do arquivo de log na última coluna dizem por quê:

```sh
sudo tail -n 20 /var/log/postgresql/postgresql-16-main.log
```

## `relation "…" already exists`

```
ana@vm:~$ psql market -v ON_ERROR_STOP=1 -f market.sql
 setseed 
---------
 
(1 row)

Time: 1.615 ms
psql:market.sql:10: ERROR:  relation "sellers" already exists
Time: 4.440 ms
```

O `market.sql` foi carregado num banco que já tinha as tabelas, em geral porque a primeira carga
foi interrompida, ou porque é a segunda vez. O `ON_ERROR_STOP` parou na primeira tabela, então nada
foi acrescentado duas vezes. Não tente terminar à mão uma carga pela metade. Jogue o banco fora e
faça de novo; são dois comandos e dois minutos:

```sh
dropdb market
createdb market
psql market -v ON_ERROR_STOP=1 -f market.sql
```

## A carga está muito lenta, ou a máquina para de responder

A carga grava 1,3 GB e depois lê tudo de volta para o `VACUUM ANALYZE`. Numa máquina virtual com
2 GB de memória e um disco lento, pode levar dez minutos ou mais, e isso é lentidão, não falha: as
linhas de `INSERT` continuam chegando, uma a uma. Duas coisas pioram a situação e valem a
conferência:

- **O disco está cheio.** `df -h /` mostra o espaço que sobra. O banco precisa de cerca de 1,5 GB
  durante a carga, e as cópias que o curso faz dele depois, de mais; o disco de 30 GB que a
  instalação recomenda deixa espaço para todas.
- **A máquina tem memória de menos**, e o computador hospedeiro está usando swap. Feche o que
  puder no hospedeiro, ou dê 2 GB à máquina virtual e aceite tempos mais lentos o curso inteiro.

## Quando não é nenhum desses

Copie o erro inteiro, a partir da linha que diz `ERROR` ou `FATAL`, e pesquise-o entre aspas. As
mensagens do PostgreSQL são frases fixas, então alguém já encontrou a sua; a parte entre aspas
depois dela — um papel, uma tabela, um arquivo — é a parte que é específica do seu caso, e
costuma ser onde está a resposta.
