---
title: Um segundo repositório, criptografado, com retenção própria
version: 1
---

O pgBackRest consegue manter a mesma stanza em até quatro repositórios ao mesmo tempo. Todo segmento
arquivado vai para todos eles; cada backup vai para o que você indicar; cada repositório tem a sua
própria retenção e a sua própria criptografia. É esse o mecanismo do "1 em outro lugar" da seção
anterior, e ele muda um arquivo.

Neste laboratório o segundo repositório é um diretório, `/srv/offsite`, na mesma máquina, fazendo as
vezes de um bucket num provedor de armazenamento ou de um disco em outro prédio. O que vem a seguir
funciona sem mudança quando o `repo2` é um bucket S3, um container do Azure ou um bucket do Google
Cloud, com as configurações desse serviço no lugar de `repo2-path`; este laboratório não tem nenhum
desses serviços, então essas configurações não foram rodadas aqui.

## Primeiro a senha

A cópia offsite vai ser criptografada, então precisa de uma senha (uma passphrase), e ela tem que
ser longa, aleatória e **anotada em algum lugar que não seja esta máquina** antes que o primeiro byte
seja criptografado com ela. Gere uma:

```sh
openssl rand -base64 48
```

Sessenta e quatro caracteres de ruído. Guarde-os onde a sua organização guarda os segredos mais
importantes, e a seção sobre a chave explica por que isso não é opcional.

## A configuração

Substitua o `/etc/pgbackrest.conf` por este, com a sua senha no lugar do marcador:

```schooling-example
{"language": "ini", "file": "pgbackrest.conf", "parts": [{"code": "[global]\nrepo1-path=/var/lib/pgbackrest\nrepo1-retention-full=2", "note": "O repositório local da lição 5, sem mudança: rápido para restaurar, e na mesma máquina."}, {"code": "repo2-path=/srv/offsite/pgbackrest\nrepo2-retention-full=4\nrepo2-cipher-type=aes-256-cbc\nrepo2-cipher-pass=PASTE-YOUR-PASSPHRASE-HERE", "note": "O segundo repositório: em outro lugar, guardado por mais tempo, e criptografado, porque o armazenamento dele é de outra pessoa."}, {"code": "compress-type=zst\nstart-fast=y\n\n[main]\npg1-path=/var/lib/postgresql/16/main", "note": "As configurações que valem para os dois."}]}
```

O segundo repositório precisa de um diretório que pertença ao `postgres`, e o arquivo agora guarda um
segredo, então ele também fica mais restrito: legível pelo `postgres`, que roda o pgBackRest, e por
mais ninguém além do root.

```
ana@vm:~$ sudo mkdir -p /srv/offsite/pgbackrest
ana@vm:~$ sudo chown postgres:postgres /srv/offsite/pgbackrest
ana@vm:~$ sudo chmod 750 /srv/offsite/pgbackrest
ana@vm:~$ sudo chown root:postgres /etc/pgbackrest.conf
ana@vm:~$ sudo chmod 640 /etc/pgbackrest.conf
ana@vm:~$ ls -l /etc/pgbackrest.conf
-rw-r----- 1 root postgres 310 Oct 15 21:44 /etc/pgbackrest.conf
```

Depois crie a stanza no repositório novo. O `stanza-create` vê que o `repo1` já tem a stanza e só a
cria onde ela está faltando:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --log-level-console=info stanza-create
2026-10-15 21:44:45.866 P00   INFO: stanza-create command begin 2.50: --exec-id=3470-3e69405a --log-level-console=info --pg1-path=/var/lib/postgresql/16/main --repo2-cipher-pass=<redacted> --repo2-cipher-type=aes-256-cbc --repo1-path=/var/lib/pgbackrest --repo2-path=/srv/offsite/pgbackrest --stanza=main
2026-10-15 21:44:46.472 P00   INFO: stanza-create for stanza 'main' on repo1
2026-10-15 21:44:46.472 P00   INFO: stanza 'main' already exists on repo1 and is valid
2026-10-15 21:44:46.472 P00   INFO: stanza-create for stanza 'main' on repo2
2026-10-15 21:44:46.483 P00   INFO: stanza-create command end: completed successfully (619ms)
```

## Backups vão para onde são mandados

Os segmentos arquivados agora vão para os dois repositórios sem ninguém pedir. Os backups não: o
`backup` escreve no `repo1` a menos que se diga outra coisa, então o segundo repositório ganha o seu
próprio:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main backup
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --repo=2 backup --type=full
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info
stanza: main
    status: ok
    cipher: mixed
        repo1: none
        repo2: aes-256-cbc

    db (current)
        wal archive min/max (16): 000000010000000000000002/000000010000000000000007

        full backup: 20261015-214441F
            timestamp start/stop: 2026-10-15 21:44:41-03 / 2026-10-15 21:44:45-03
            wal start/stop: 000000010000000000000003 / 000000010000000000000003
            database size: 33.8MB, database backup size: 33.8MB
            repo1: backup set size: 4.4MB, backup size: 4.4MB

        incr backup: 20261015-214441F_20261015-214447I
            timestamp start/stop: 2026-10-15 21:44:47-03 / 2026-10-15 21:44:48-03
            wal start/stop: 000000010000000000000004 / 000000010000000000000005
            database size: 33.8MB, database backup size: 8.3KB
            repo1: backup set size: 4.4MB, backup size: 389B
            backup reference list: 20261015-214441F

        full backup: 20261015-214449F
            timestamp start/stop: 2026-10-15 21:44:49-03 / 2026-10-15 21:44:53-03
            wal start/stop: 000000010000000000000006 / 000000010000000000000007
            database size: 33.8MB, database backup size: 33.8MB
            repo2: backup set size: 4.4MB, backup size: 4.4MB
```

O `backup` simples foi para o `repo1`, onde o backup full da lição 5 já estava, então o pgBackRest fez
lá um **incremental**, de algumas centenas de bytes. O com `--repo=2` teve que ser full, já que não
havia nada no `repo2` sobre o que construir. O `info` agora lista os backups dos dois repositórios
num só histórico, cada linha dizendo qual repositório o guarda, e `cipher: mixed` diz que um deles é
criptografado. Olhe o mesmo arquivo em cada um:

```
ana@vm:~$ sudo file /var/lib/pgbackrest/backup/main/20261015-214441F/pg_data/PG_VERSION.zst /srv/offsite/pgbackrest/backup/main/20261015-214449F/pg_data/PG_VERSION.zst
/var/lib/pgbackrest/backup/main/20261015-214441F/pg_data/PG_VERSION.zst:     Zstandard compressed data (v0.8+), Dictionary ID: None
/srv/offsite/pgbackrest/backup/main/20261015-214449F/pg_data/PG_VERSION.zst: openssl enc'd data with salted password
```

O `file` lê os primeiros bytes de cada um e os reconhece: a cópia no `repo1` é zstd, a cópia no
`repo2` é `openssl enc'd data with salted password`. Quem tem o bucket, o disco ou a fita não tem nada
que consiga ler sem a senha.

A rotina noturna da lição 5 ganha uma linha, `pgbackrest --stanza=main --repo=2 backup`, depois do
primeiro backup e antes do verify, para que os dois repositórios recebam um backup toda noite.
