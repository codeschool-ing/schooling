---
title: Medindo quanto uma cópia está atrasada
version: 1
---

A aula 8 disse que o que um failover assíncrono perde é o atraso de replicação no momento da falha, e a
aula 9 que uma cópia atrasada não falha, então tem de ser medida. Esta seção mede. O laboratório é de
novo o par de servidores da aula 8, num diretório próprio:

```sh
mkdir -p ~/lab/replication && cd ~/lab/replication
```

`replication.sh`:

```schooling-example
{"language": "sh", "file": "replication.sh", "parts": [{"code": "#!/bin/bash\nset -e\npsql -v ON_ERROR_STOP=1 -U \"$POSTGRES_USER\" -c \"CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator'\"\necho \"host replication replicator all scram-sha-256\" >> \"$PGDATA/pg_hba.conf\"", "note": "Roda uma vez, quando o diretório de dados do primário é criado: um papel autorizado a transmitir o log de escrita antecipada, e uma linha no `pg_hba.conf` que o deixa se conectar para replicação a partir da rede do laboratório."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  primary:\n    image: postgres:17\n    environment:\n      POSTGRES_PASSWORD: quitanda\n    volumes:\n      - ./replication.sh:/docker-entrypoint-initdb.d/replication.sh:ro\n      - primary:/var/lib/postgresql/data", "note": "Os mesmos dois servidores da aula 8: PostgreSQL 17, um primário que recebe as escritas e roda `replication.sh` na primeira partida, e um standby que o segue."}, {"code": "  standby:\n    image: postgres:17\n    user: postgres\n    environment:\n      PGPASSWORD: replicator\n    command: >\n      bash -c \"until pg_basebackup -h primary -U replicator -D /var/lib/postgresql/data -R -X stream;\n               do sleep 1; done; chmod 700 /var/lib/postgresql/data; exec postgres\"\n    volumes:\n      - standby:/var/lib/postgresql/data\n    depends_on:\n      - primary\nvolumes:\n  primary:\n  standby:", "note": "O standby começa vazio, copia o primário com `pg_basebackup`, e `-R` grava as configurações que o fazem seguir o primário dali em diante, recebendo cada mudança. Ele aceita leituras e recusa escritas."}]}
```

Suba os dois, dê quinze segundos, e defina as duas variáveis de shell que a aula 8 usou, uma para cada
servidor:

```sh
docker compose up -d
P="docker compose exec -T primary psql -U postgres"
S="docker compose exec -T standby psql -U postgres"
```

O primário informa sobre cada standby conectado a ele no `pg_stat_replication`:

```
ana@vm:~/lab/replication$ $P -x -c "SELECT state, sent_lsn, write_lsn, flush_lsn, replay_lsn, write_lag, flush_lag, replay_lag FROM pg_stat_replication"
-[ RECORD 1 ]---------
state      | streaming
sent_lsn   | 0/3000000
write_lsn  | 0/3000000
flush_lsn  | 0/3000000
replay_lsn | 0/3000000
write_lag  | 
flush_lag  | 
replay_lag | 
```

As quatro posições no log de escrita antecipada são as que importam. `sent_lsn` é até onde o primário
enviou o log para este standby, e `replay_lsn` até onde o standby o aplicou; um LSN, *log sequence
number*, é uma posição no log, em bytes. Entre os dois ficam `write_lsn` e `flush_lsn`, e as três colunas
`_lag` transformam os mesmos passos em tempo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma faixa de log de escrita antecipada, crescendo para a direita. Quatro marcas ao longo dela: a posição atual do primário, na ponta direita, depois sent, o ponto que o standby recebeu pela rede, depois flushed, o que o standby gravou no disco, e replayed, o que o standby aplicou e consegue mostrar a um leitor, mais à esquerda. A distância de sent até replayed é o que o standby já tem e ainda não aplicou.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"90\" width=\"640\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">log de escrita antecipada</text><path d=\"M660 124 L660 150\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"660\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">current</text><text x=\"660\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o primário está aqui</text><path d=\"M520 124 L520 150\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"520\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sent</text><text x=\"520\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a caminho do standby</text><path d=\"M400 124 L400 150\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"400\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">flush</text><text x=\"400\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">no disco do standby</text><path d=\"M220 124 L220 150\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"220\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">replay</text><text x=\"220\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o que os leitores do standby veem</text><rect x=\"220\" y=\"92\" width=\"300\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"370\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">recebido, ainda não aplicado</text></svg>", "caption": "Cada posição no `pg_stat_replication` responde uma pergunta diferente: o que a rede levou, o que está seguro no disco do standby, e o que um leitor do standby consegue ver."}
```

## Sob carga

O `pgbench`, que vem com o PostgreSQL, roda uma carga padrão no estilo de um banco. Crie as tabelas dele,
rode-o por vinte segundos com oito clientes em segundo plano, e olhe o atraso enquanto ele roda:

```
ana@vm:~/lab/replication$ docker compose exec -T primary pgbench -i -q -U postgres postgres
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) of pgbench_accounts done (elapsed 0.10 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.29 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.13 s, vacuum 0.11 s, primary keys 0.05 s).
ana@vm:~/lab/replication$ docker compose exec -d primary pgbench -T 20 -c 8 -U postgres postgres
ana@vm:~/lab/replication$ sleep 8; $P -c "SELECT write_lag, flush_lag, replay_lag, pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind FROM pg_stat_replication"
    write_lag    |    flush_lag    |   replay_lag    | bytes_behind 
-----------------+-----------------+-----------------+--------------
 00:00:00.000135 | 00:00:00.000135 | 00:00:00.000135 |          512
(1 row)
```

Numa máquina só, com os dois servidores em contêineres, o standby estava **0,14 milissegundo** atrasado,
e 512 bytes. Através de uma rede, entre data centers, as mesmas colunas mostram a ida e volta e o que o
disco do standby acrescentar. São os números a pôr num gráfico, e sobre os quais alertar.

## Um standby que para de aplicar

O atraso que importa vem de um standby que não dá conta: um disco lento, uma consulta longa no standby
segurando a reaplicação, uma rede que cai. O PostgreSQL consegue imitar o último caso de propósito, com
`pg_wal_replay_pause()`, que faz o standby parar de aplicar o log enquanto continua a recebê-lo. Pause-o,
grave 200.000 linhas no primário, e olhe os dois lados:

```
ana@vm:~/lab/replication$ $S -c "SELECT pg_wal_replay_pause()"
 pg_wal_replay_pause 
---------------------
 
(1 row)

ana@vm:~/lab/replication$ $P -c "INSERT INTO pgbench_history SELECT 1, 1, 1, 0, now() FROM generate_series(1, 200000)"
INSERT 0 200000
ana@vm:~/lab/replication$ $P -c "SELECT replay_lag, pg_size_pretty(pg_wal_lsn_diff(sent_lsn, replay_lsn)) AS behind FROM pg_stat_replication"
   replay_lag    | behind 
-----------------+--------
 00:00:00.284866 | 15 MB
(1 row)

ana@vm:~/lab/replication$ $S -c "SELECT count(*) FROM pgbench_history" -c "SELECT now() - pg_last_xact_replay_timestamp() AS last_replayed"
 count 
-------
 24699
(1 row)

  last_replayed  
-----------------
 00:00:04.689435
(1 row)
```

O primário mostra o standby **15 MB atrasado**. O standby ainda conta o número antigo de linhas, e a
última transação que ele aplicou tem vários segundos. Mas `replay_lag` diz 0,3 segundo, o que engana: é
o atraso da última mudança que o standby *aplicou*, e enquanto nada é aplicado ele não cresce. **A
diferença em bytes e o relógio do próprio standby dizem a verdade aqui**; a coluna de tempo sozinha teria
dito que estava tudo bem.

Retome, e o standby se atualiza num instante:

```
ana@vm:~/lab/replication$ $S -c "SELECT pg_wal_replay_resume()"
 pg_wal_replay_resume 
----------------------
 
(1 row)

ana@vm:~/lab/replication$ sleep 3; $P -c "SELECT replay_lag, pg_size_pretty(pg_wal_lsn_diff(sent_lsn, replay_lsn)) AS behind FROM pg_stat_replication"
   replay_lag    | behind  
-----------------+---------
 00:00:00.955551 | 0 bytes
(1 row)

ana@vm:~/lab/replication$ $S -c "SELECT count(*) FROM pgbench_history"
 count  
--------
 224699
(1 row)
```

## O que observar

| pergunta | onde ler |
| --- | --- |
| quanto um failover perderia agora | `pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn)` no primário: o que nem saiu |
| quão velha é uma leitura do standby | `now() - pg_last_xact_replay_timestamp()` no standby, enquanto o primário escreve |
| o standby está conectado | uma linha no `pg_stat_replication` com `state = streaming`; nenhuma linha é o alarme |

A última linha é a mais esquecida. Um standby que se desconectou some da visão, e um painel que desenha
o atraso das linhas que encontra traça uma linha reta e saudável. E `pg_last_xact_replay_timestamp`
cresce sozinho quando o primário está parado, já que não há nada novo para reaplicar, então só significa
alguma coisa enquanto há escritas.
