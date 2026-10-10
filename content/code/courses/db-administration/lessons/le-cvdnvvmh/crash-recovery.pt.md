---
title: Matando o servidor no meio de uma escrita
version: 1
---

O medo depois de uma queda do banco é que os dados estejam danificados e agora alguém tenha de
achar um backup. Para uma queda do processo do servidor, isso quase nunca é verdade. **Você o sobe
de novo, e ele se conserta sozinho a partir do log**, porque tudo o que esta lição e a anterior
descreveram existe para este momento. A lição 3 prometeu fazer isso de propósito, e esta seção faz:
um fluxo de commits, um `kill -9` no meio deles, e uma verificação de que todo commit avisado a
alguém sobreviveu.

Uma coisa a deixar clara antes. O `kill -9` encerra os processos do servidor e mais nada. O sistema
operacional continua rodando, e o cache dele, com dados que recebeu e ainda não pôs no disco, também.
Uma queda de energia perde esse cache também, e sobreviver a ela é trabalho do `fsync` da próxima
seção. A recuperação que você vai ver é a mesma nos dois casos; o que muda é se o log que ela refaz
estava mesmo no disco.

## Um cliente que mantém um registro

Crie uma tabela e depois inicie um cliente que insere números nela um de cada vez, cada um na sua
própria transação, e anota todo número que o servidor confirmou:

```
shop=# CREATE TABLE acks (id int PRIMARY KEY);
CREATE TABLE
ana@db:~$ seq 1 1000000 | sed 's/.*/INSERT INTO acks VALUES (&) RETURNING id;/' | psql -XAtq shop > acked.txt 2> acked.err &
ana@db:~$ pgbench -n -c 4 -T 120 bench > bench.out 2>&1 &
ana@db:~$ wc -l acked.txt
12910 acked.txt
```

O `seq` conta, o `sed` transforma cada número num `INSERT`, e o `psql` roda um depois do outro. O
`RETURNING id` faz ele imprimir o número, e o `psql` só imprime o resultado de um comando quando o
comando terminou, o que, para um comando fora de um bloco de transação, inclui o commit. Então **o
`acked.txt` é a lista do próprio cliente dos commits que lhe foram confirmados**. O `&` no fim de
cada linha roda o comando em segundo plano; a segunda linha acrescenta o `pgbench` por dois minutos
como o resto da carga de escrita. Dez segundos depois a lista tinha 12910 números.

Agora mate o processo principal do servidor, o postmaster, cujo número de processo é a primeira
linha do `postmaster.pid` (a lição 4 mostrou esse arquivo):

```
ana@db:~$ sudo kill -9 $(sudo head -n 1 /var/lib/postgresql/16/main/postmaster.pid)
ana@db:~$ tail -n 1 acked.txt
13003
ana@db:~$ cat acked.err
FATAL:  terminating connection due to unexpected postmaster exit
no connection to the server
connection to server was lost
ana@db:~$ tail -n 2 bench.out
tps = 2183.802426 (without initial connection time)
pgbench: error: Run was aborted; the above results are incomplete.
ana@db:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

O último commit de que o cliente soube foi o **13003**. A sessão dele foi encerrada com
`unexpected postmaster exit`: os processos que atendiam conexões perceberam que o pai tinha ido
embora e pararam, porque nenhum deles pode continuar sozinho. O `pgbench` foi cortado também, e o
cluster está parado. Nada o reiniciou. A unit que o roda não pede reinício automático ao systemd,
então neste servidor uma queda fica parada até alguém agir — que é quando um administrador é
chamado.

## A recuperação, linha por linha

Suba do jeito normal e leia o que ele escreveu:

```
ana@db:~$ sudo systemctl start postgresql@16-main
ana@db:~$ sudo tail -n 11 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:29:00.013 -03 [332] LOG:  starting PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit
2026-10-10 04:29:00.013 -03 [332] LOG:  listening on IPv4 address "127.0.0.1", port 5432
2026-10-10 04:29:00.014 -03 [332] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2026-10-10 04:29:00.019 -03 [335] LOG:  database system was interrupted; last known up at 2026-10-10 04:28:27 -03
2026-10-10 04:29:00.294 -03 [335] LOG:  database system was not properly shut down; automatic recovery in progress
2026-10-10 04:29:00.298 -03 [335] LOG:  redo starts at 0/420F91E0
2026-10-10 04:29:01.032 -03 [335] LOG:  invalid record length at 0/535AA2E0: expected at least 24, got 0
2026-10-10 04:29:01.032 -03 [335] LOG:  redo done at 0/535AA2B8 system usage: CPU: user: 0.42 s, system: 0.30 s, elapsed: 0.73 s
2026-10-10 04:29:01.039 -03 [333] LOG:  checkpoint starting: end-of-recovery immediate wait
2026-10-10 04:29:01.581 -03 [333] LOG:  checkpoint complete: wrote 16289 buffers (99.4%); 0 WAL file(s) added, 0 removed, 17 recycled; write=0.110 s, sync=0.421 s, total=0.543 s; sync files=52, longest=0.179 s, average=0.009 s; distance=283332 kB, estimate=283332 kB; lsn=0/535AA2E0, redo lsn=0/535AA2E0
2026-10-10 04:29:01.593 -03 [332] LOG:  database system is ready to accept connections
```

Depois das três linhas que toda subida escreve, a história vem em ordem:

- `database system was interrupted; last known up at …` — o `pg_control` ainda dizia
  `in production`, então a última parada não foi limpa. A hora é a do último checkpoint.
- `automatic recovery in progress` — ninguém escolhe isso; é o que uma subida depois de uma queda faz.
- `redo starts at 0/420F91E0` — o ponto de redo do último checkpoint, lido do `pg_control`,
  exatamente como a figura da primeira seção desenhou.
- `invalid record length at …: expected at least 24, got 0` — o fim do log. A recuperação lê
  registros até o próximo não ser válido, e aqui os bytes seguintes eram zeros, nunca escritos. Vem
  como uma linha `LOG`, não um erro, porque toda recuperação termina assim.
- `redo done at … elapsed: 0.73 s` — toda alteração desde o ponto de redo foi feita de novo.
  `distance=283332 kB`, na linha seguinte, é quanto log isso foi.
- `end-of-recovery immediate wait` — um checkpoint, para que as páginas consertadas estejam no disco
  antes de alguém se conectar, e a próxima queda não tenha de refazer o mesmo log de novo.

Depois, a única verificação que importa:

```
shop=# SELECT max(id), count(*) FROM acks;
  max  | count 
-------+-------
 13003 | 13003
(1 row)
```

**Todo número que o cliente ouviu como confirmado está na tabela: 13003 deles, o último incluído, e
sem buraco.** A linha da última confirmação não tinha chegado ao arquivo da tabela quando o servidor
morreu; ela foi reconstruída a partir do log. Uma contagem uma acima da lista do cliente também
estaria certa: um commit pode chegar ao disco no instante antes de o servidor conseguir mandar a
resposta. Uma contagem abaixo quereria dizer que um commit confirmado se perdeu, e esse é o único
resultado que um PostgreSQL configurado corretamente nunca dá.

Quanto isso demora depende de quanto log há para refazer, que é a distância desde o último
checkpoint. Aqui foram 283332 kB, refeitos em menos de um segundo. Um servidor com `max_wal_size`
grande e `checkpoint_timeout` longo, sob muita escrita, pode refazer por minutos, e **essa espera é
o preço de ter menos checkpoints**, pago só no dia em que algo cai.
