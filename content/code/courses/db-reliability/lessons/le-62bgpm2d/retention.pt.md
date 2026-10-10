---
title: Retenção: o que é apagado, e quando
version: 1
---

A configuração diz `repo1-retention-full=2`: manter dois backups full. Faça mais dois e observe o
`expire` do segundo:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main backup --type=full
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --log-level-console=info backup --type=full
2026-10-10 16:27:46.502 P00   INFO: backup command begin 2.50: --compress-type=zst --exec-id=1078-73b31b1a --log-level-console=info --pg1-path=/var/lib/postgresql/16/main --repo1-path=/var/lib/pgbackrest --repo1-retention-full=2 --stanza=main --start-fast --type=full
2026-10-10 16:27:47.240 P00   INFO: execute non-exclusive backup start: backup begins after the requested immediate checkpoint completes
2026-10-10 16:27:47.741 P00   INFO: backup start archive = 00000001000000000000000C, lsn = 0/C0000D0
2026-10-10 16:27:47.741 P00   INFO: check archive for prior segment 00000001000000000000000B
2026-10-10 16:27:50.100 P00   INFO: execute non-exclusive backup stop and wait for all WAL segments to archive
2026-10-10 16:27:50.301 P00   INFO: backup stop archive = 00000001000000000000000C, lsn = 0/C0362A8
2026-10-10 16:27:50.303 P00   INFO: check archive for segment(s) 00000001000000000000000C:00000001000000000000000C
2026-10-10 16:27:50.309 P00   INFO: new backup label = 20261010-162747F
2026-10-10 16:27:50.333 P00   INFO: full backup size = 33.9MB, file total = 1271
2026-10-10 16:27:50.333 P00   INFO: backup command end: completed successfully (3833ms)
2026-10-10 16:27:50.333 P00   INFO: expire command begin 2.50: --exec-id=1078-73b31b1a --log-level-console=info --repo1-path=/var/lib/pgbackrest --repo1-retention-full=2 --stanza=main
2026-10-10 16:27:50.336 P00   INFO: repo1: expire full backup set 20261010-162731F, 20261010-162731F_20261010-162736D, 20261010-162731F_20261010-162739I
2026-10-10 16:27:50.338 P00   INFO: repo1: remove expired backup 20261010-162731F_20261010-162739I
2026-10-10 16:27:50.341 P00   INFO: repo1: remove expired backup 20261010-162731F_20261010-162736D
2026-10-10 16:27:50.343 P00   INFO: repo1: remove expired backup 20261010-162731F
2026-10-10 16:27:50.534 P00   INFO: repo1: 16-1 remove archive, start = 000000010000000000000003, stop = 000000010000000000000009
2026-10-10 16:27:50.534 P00   INFO: expire command end: completed successfully (201ms)
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info
stanza: main
    status: ok
    cipher: none

    db (current)
        wal archive min/max (16): 00000001000000000000000A/00000001000000000000000C

        full backup: 20261010-162742F
            timestamp start/stop: 2026-10-10 16:27:42-03 / 2026-10-10 16:27:46-03
            wal start/stop: 00000001000000000000000A / 00000001000000000000000A
            database size: 33.9MB, database backup size: 33.9MB
            repo1: backup set size: 4.4MB, backup size: 4.4MB

        full backup: 20261010-162747F
            timestamp start/stop: 2026-10-10 16:27:47-03 / 2026-10-10 16:27:50-03
            wal start/stop: 00000001000000000000000C / 00000001000000000000000C
            database size: 33.9MB, database backup size: 33.9MB
            repo1: backup set size: 4.4MB, backup size: 4.4MB
```

Leia as quatro linhas do `expire` em ordem. Com um terceiro backup full no repositório, o mais antigo
passou do limite, então o pgBackRest expirou **o conjunto inteiro que dependia dele**: o full, o
diferencial e o incremental, numa decisão só, removendo primeiro os dependentes. Depois removeu os
segmentos arquivados de que só esse conjunto precisava, de `…03` a `…09`, e nada depois deles. O
`info` confirma: dois backups full, e o `wal archive min/max` agora começando em `…0A`, o primeiro
segmento de que o backup mais antigo que sobrou precisa.

Esse último passo é o que um script feito em casa erra. Os segmentos de `…0A` em diante ficam
porque uma restauração a partir do full mais antigo que sobrou precisa de cada um deles; apagar por
idade (tudo o que tiver mais de uma semana, por exemplo) teria apagado log de que um backup mantido
ainda depende, e **nada teria avisado até alguém tentar recuperar além da lacuna**.

## A janela que você realmente tem

A retenção decide até onde dá para voltar. Com dois backups full mantidos, e um feito a cada
domingo, o momento mais antigo que dá para restaurar fica entre oito e catorze dias atrás,
dependendo do dia em que você olha: logo depois de um backup de domingo, o full mais antigo tem uma
semana; logo antes do próximo, tem quase duas. Contar backups full em vez de dias significa que a
janela encolhe se um full semanal é feito duas vezes por engano, e cresce se um deles falha.

O pgBackRest também sabe contar em dias (`repo1-retention-full-type=time`). Qual usar depende do que
foi prometido, e a promessa é assunto da lição 8: "conseguimos restaurar qualquer momento dos últimos
14 dias" é uma frase que alguém assina, e a retenção é a configuração que a mantém verdadeira.

## Apagando à mão

O `expire` também remove um backup específico, com `--set`. É isso que se faz com um backup que se
sabe estar ruim, e a seção de verificação usa esse recurso. É a única remoção desta lição que não é
automática, e mesmo nela o pgBackRest se recusa a deixar um backup dependente sem o backup de que ele
precisa.
