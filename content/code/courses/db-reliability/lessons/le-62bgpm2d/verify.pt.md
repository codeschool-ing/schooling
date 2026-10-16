---
title: Verify, e um sucesso que não diz nada
version: 1
---

Cada arquivo que o pgBackRest grava no repositório ganha um checksum na hora do backup, e cada
segmento arquivado também. O `verify` relê tudo e compara. Aqui está ele no repositório saudável:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main verify
ana@vm:~$ echo $?
0
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main verify --verbose --output=text
stanza: main
status: ok
  archiveId: 16-1, total WAL checked: 3, total valid WAL: 3
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162742F, status: valid, total files checked: 1271, total valid files: 1271
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162747F, status: valid, total files checked: 1271, total valid files: 1271
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
```

Rodado sem mais nada, **o `verify` não imprimiu nada e saiu com 0.** Quando pedimos o relatório
completo, ele disse o que conferiu: três segmentos de log, dois backups de 1271 arquivos cada, todos
os arquivos válidos, `status: ok`.

Agora danifique um arquivo dentro do backup full mais novo, do jeito que faria um disco falhando,
uma cópia malfeita ou uma pessoa descuidada:

```
ana@vm:~$ sudo ls /var/lib/pgbackrest/backup/main
20261010-162742F
20261010-162747F
backup.history
backup.info
backup.info.copy
latest
ana@vm:~$ sudo sh -c 'echo junk >> /var/lib/pgbackrest/backup/main/20261010-162747F/pg_data/PG_VERSION.zst'
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main verify
ana@vm:~$ echo $?
0
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main verify --verbose --output=text
stanza: main
status: error
  archiveId: 16-1, total WAL checked: 3, total valid WAL: 3
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162742F, status: valid, total files checked: 1271, total valid files: 1271
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162747F, status: invalid, total files checked: 1271, total valid files: 1270
    missing: 0, checksum invalid: 1, size invalid: 0, other: 0
ana@vm:~$ echo $?
0
```

Leia isso duas vezes. O `verify` simples **não imprimiu nada e saiu com 0 de novo**, com um backup
danificado no repositório. O relatório completo sabe exatamente o que está errado (um arquivo de um
backup com checksum inválido, `status: error`) e mesmo assim sai com 0.

É assim que se comporta a versão 2.50, a que vem no Ubuntu 24.04, e é a falha silenciosa da lição 1
dentro de uma ferramenta feita para evitar falhas silenciosas. Uma rotina que roda o `verify` e
confere o status de saída fica verde para sempre. **O relatório é o resultado**, e o único teste
confiável é lê-lo: a rotina da última seção aceita exatamente a linha `status: ok` e mais nada, para
que o silêncio seja uma falha e não uma aprovação.

## Jogando fora um backup ruim

Um backup que falha na verificação não tem conserto; ele pode ser removido e feito de novo:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --log-level-console=info expire --set=20261010-162747F
2026-10-10 16:27:51.965 P00   INFO: expire command begin 2.50: --exec-id=1164-bcb4b129 --log-level-console=info --repo1-path=/var/lib/pgbackrest --repo1-retention-full=2 --set=20261010-162747F --stanza=main
WARN: repo1: expiring latest backup 20261010-162747F - the ability to perform point-in-time-recovery (PITR) may be affected
      HINT: non-default settings for 'repo1-retention-archive'/'repo1-retention-archive-type' (even in prior expires) can cause gaps in the WAL.
2026-10-10 16:27:51.968 P00   INFO: repo1: expire adhoc backup 20261010-162747F
2026-10-10 16:27:51.970 P00   INFO: repo1: remove expired backup 20261010-162747F
2026-10-10 16:27:52.138 P00   INFO: expire command end: completed successfully (175ms)
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main backup --type=full
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main verify --verbose --output=text
stanza: main
status: ok
  archiveId: 16-1, total WAL checked: 5, total valid WAL: 5
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162742F, status: valid, total files checked: 1271, total valid files: 1271
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162752F, status: valid, total files checked: 1271, total valid files: 1271
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
```

O `expire --set` o removeu, com um aviso que vale ler: era o backup mais novo, e removê-lo estreita
os momentos para os quais dá para recuperar até o próximo existir. Um novo backup full resolve isso,
e o relatório volta a ser `ok`, com dois backups válidos.

Duas coisas continuam fora do que o `verify` enxerga. Ele confere se o repositório guarda o que o
pgBackRest gravou, não se o que ele gravou era um banco saudável; e ele nunca subiu um servidor em
cima de nada disso. A próxima seção faz isso.
