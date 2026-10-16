---
title: Perdendo o primeiro repositório de propósito
version: 1
---

O segundo repositório existe para o dia em que o primeiro some. Faça esse dia acontecer: apague o
repositório local inteiro, como faria um disco com defeito ou um comando descuidado.

```
ana@vm:~$ sudo rm -rf /var/lib/pgbackrest/archive /var/lib/pgbackrest/backup
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info
stanza: main
    status: mixed
        repo1: error (missing stanza path)
        repo2: ok
    cipher: mixed
        repo1: none
        repo2: aes-256-cbc

    db (current)
        wal archive min/max (16): 000000010000000000000004/000000010000000000000007

        full backup: 20261015-214449F
            timestamp start/stop: 2026-10-15 21:44:49-03 / 2026-10-15 21:44:53-03
            wal start/stop: 000000010000000000000006 / 000000010000000000000007
            database size: 33.8MB, database backup size: 33.8MB
            repo2: backup set size: 4.4MB, backup size: 4.4MB
shop=# SELECT archived_count, failed_count, last_failed_wal FROM pg_stat_archiver;
 archived_count | failed_count |     last_failed_wal      
----------------+--------------+--------------------------
              9 |            3 | 000000010000000000000008
(1 row)
```

O `info` agora mostra o `repo1` como erro, `missing stanza path`, e o `repo2` como saudável, com o
seu backup. O banco em produção nem percebeu, e a última consulta mostra o único lugar onde percebeu:
um pedido e uma troca de segmento depois, `failed_count` está em 3 e `last_failed_wal` dá o nome
desse segmento. O pgBackRest manda cada segmento para todo repositório que consegue alcançar e
**informa o envio como falho se qualquer repositório falhou**, então o servidor continua tentando de
novo, os alertas da lição 4 disparam, e alguém fica sabendo que uma cópia sumiu enquanto a outra
continua sendo escrita.

Restaure a partir do sobrevivente. O `--repo=2` diz de onde, e a senha na configuração descriptografa
no caminho:

```
ana@vm:~$ sudo pg_ctlcluster 16 restore stop
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/restore
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --repo=2 --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off restore
ana@vm:~$ sudo pg_ctlcluster 16 restore start
ana@vm:~$ psql -X -A -t shop -f verify.sql > live.txt
ana@vm:~$ psql -X -A -t -p 5433 shop -f verify.sql > restored.txt
ana@vm:~$ diff live.txt restored.txt && echo identical
identical
```

O mesmo relatório, a mesma resposta: o segundo repositório sozinho trouxe o shop de volta. É a
restauração da lição 5 com uma opção a mais, e esse é o ponto. Um segundo repositório que precisa de
um procedimento diferente no pior dia do ano é uma segunda coisa para dar errado.

Traga o primeiro de volta do jeito que ele voltaria depois de uma falha de verdade, criando a stanza
de novo e fazendo nele um backup full novo:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main stanza-create
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --repo=1 backup --type=full
shop=# SELECT archived_count, failed_count, last_archived_wal, last_failed_wal FROM pg_stat_archiver;
 archived_count | failed_count |            last_archived_wal             |     last_failed_wal      
----------------+--------------+------------------------------------------+--------------------------
             13 |            3 | 00000001000000000000000A.00000028.backup | 000000010000000000000008
(1 row)
```

O arquivamento se recupera sozinho: `archived_count` avança, `failed_count` fica nas 3 tentativas
feitas enquanto o `repo1` estava faltando, e o próximo backup em qualquer um dos repositórios é um
backup comum.
