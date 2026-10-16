---
title: Full, diferencial e incremental
version: 1
---

O pgBackRest faz três tipos de backup. Comece pelo tipo de que todos os outros dependem:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main backup --type=full
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info
stanza: main
    status: ok
    cipher: none

    db (current)
        wal archive min/max (16): 000000010000000000000002/000000010000000000000004

        full backup: 20261010-162731F
            timestamp start/stop: 2026-10-10 16:27:31-03 / 2026-10-10 16:27:35-03
            wal start/stop: 000000010000000000000003 / 000000010000000000000004
            database size: 33.8MB, database backup size: 33.8MB
            repo1: backup set size: 4.4MB, backup size: 4.4MB
```

O `info` é o relato que o repositório faz de si mesmo. Um backup **full**, identificado pela hora em
que começou e terminando em `F`. O banco ocupa 33,8 MB em disco e o backup **4,4 MB no repositório**,
comprimido com zstd. O `wal start/stop` são os segmentos necessários para deixá-lo consistente, e o
`wal archive min/max` o trecho de log arquivado que a stanza guarda.

## Diferencial

Altere mil pedidos e faça um backup **diferencial**, que copia tudo o que mudou desde o último full:

```
ana@vm:~$ psql shop -c "UPDATE orders SET total_cents = total_cents + 1 WHERE id <= 1000"
UPDATE 1000
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --log-level-console=info backup --type=diff
2026-10-10 16:27:35.660 P00   INFO: backup command begin 2.50: --compress-type=zst --exec-id=1023-5b94a0ff --log-level-console=info --pg1-path=/var/lib/postgresql/16/main --repo1-path=/var/lib/pgbackrest --repo1-retention-full=2 --stanza=main --start-fast --type=diff
2026-10-10 16:27:36.372 P00   INFO: last backup label = 20261010-162731F, version = 2.50
2026-10-10 16:27:36.372 P00   INFO: execute non-exclusive backup start: backup begins after the requested immediate checkpoint completes
2026-10-10 16:27:37.074 P00   INFO: backup start archive = 000000010000000000000006, lsn = 0/6000028
2026-10-10 16:27:37.074 P00   INFO: check archive for prior segment 000000010000000000000005
2026-10-10 16:27:38.544 P00   INFO: execute non-exclusive backup stop and wait for all WAL segments to archive
2026-10-10 16:27:38.744 P00   INFO: backup stop archive = 000000010000000000000006, lsn = 0/6000100
2026-10-10 16:27:38.746 P00   INFO: check archive for segment(s) 000000010000000000000006:000000010000000000000006
2026-10-10 16:27:38.753 P00   INFO: new backup label = 20261010-162731F_20261010-162736D
2026-10-10 16:27:38.780 P00   INFO: diff backup size = 5MB, file total = 1271
2026-10-10 16:27:38.780 P00   INFO: backup command end: completed successfully (3121ms)
2026-10-10 16:27:38.780 P00   INFO: expire command begin 2.50: --exec-id=1023-5b94a0ff --log-level-console=info --repo1-path=/var/lib/pgbackrest --repo1-retention-full=2 --stanza=main
2026-10-10 16:27:38.782 P00   INFO: expire command end: completed successfully (2ms)
```

Desta vez o log aparece, e ele conta a história inteira de um backup: um checkpoint imediato, o
segmento de início, uma conferência de que o segmento anterior está no arquivo, a cópia, o segmento
final, uma espera até chegar cada segmento de que o backup precisa, e um rótulo feito do rótulo do
full e do seu próprio, terminando em `D`. Depois roda o `expire`, como acontece depois de todo
backup, e não encontra nada para apagar.

`diff backup size = 5MB` para mil linhas alteradas. **Por padrão, o pgBackRest decide o que mudou
arquivo por arquivo**: o arquivo de dados da tabela foi modificado, então ele foi copiado inteiro,
junto com os índices. Duas configurações, `repo-bundle` e `repo-block`, fazem o pgBackRest dividir
os arquivos em blocos e copiar só os blocos que mudaram. Elas vêm desligadas, e este curso as deixa
desligadas para que a conta continue visível.

## Incremental

Um **incremental** copia o que mudou desde o último backup de qualquer tipo. Acrescente um pedido e
faça um:

```
ana@vm:~$ psql shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (1, 700, '2026-09-01 11:00-03')"
INSERT 0 1
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main backup --type=incr
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info
stanza: main
    status: ok
    cipher: none

    db (current)
        wal archive min/max (16): 000000010000000000000002/000000010000000000000008

        full backup: 20261010-162731F
            timestamp start/stop: 2026-10-10 16:27:31-03 / 2026-10-10 16:27:35-03
            wal start/stop: 000000010000000000000003 / 000000010000000000000004
            database size: 33.8MB, database backup size: 33.8MB
            repo1: backup set size: 4.4MB, backup size: 4.4MB

        diff backup: 20261010-162731F_20261010-162736D
            timestamp start/stop: 2026-10-10 16:27:36-03 / 2026-10-10 16:27:38-03
            wal start/stop: 000000010000000000000006 / 000000010000000000000006
            database size: 33.9MB, database backup size: 5MB
            repo1: backup set size: 4.4MB, backup size: 854.5KB
            backup reference list: 20261010-162731F

        incr backup: 20261010-162731F_20261010-162739I
            timestamp start/stop: 2026-10-10 16:27:39-03 / 2026-10-10 16:27:41-03
            wal start/stop: 000000010000000000000008 / 000000010000000000000008
            database size: 33.9MB, database backup size: 4.5MB
            repo1: backup set size: 4.4MB, backup size: 817.9KB
            backup reference list: 20261010-162731F, 20261010-162731F_20261010-162736D
```

Agora são três backups, e o fim de cada um diz do que ele precisa. O diferencial se refere ao full;
o incremental se refere ao full **e** ao diferencial. Para restaurar o incremental, o pgBackRest
pega os arquivos inalterados do full, os que o diferencial copiou a partir dele, e os que o próprio
incremental copiou. Um pedido, e ainda assim 4,5 MB de arquivos, porque ele foi parar no mesmo
arquivo de tabela de 3 MB que as mil alterações já tinham tocado.

## Qual fazer, e quando

Os três trocam o tempo e o espaço que um backup ocupa por aquilo de que uma restauração depende:

| | copia | uma restauração precisa de |
|---|---|---|
| **full** | tudo | só desse backup |
| **diferencial** | o que mudou desde o último full | desse backup e do full dele |
| **incremental** | o que mudou desde o último backup de qualquer tipo | desse backup, do full dele e de cada backup no meio |

Um ritmo comum é **um full por semana e um diferencial por dia**, e incrementais com mais frequência
se o banco muda muito. Cada backup de que uma restauração depende é mais uma coisa que precisa estar
intacta: um full danificado inutiliza todo diferencial e todo incremental construído sobre ele, como
a última seção desta lição mostra. Cadeias longas de incrementais são baratas de fazer e frágeis
para confiar.
