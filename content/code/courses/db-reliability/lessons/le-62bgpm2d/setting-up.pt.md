---
title: Instalando o pgBackRest, e a stanza
version: 1
---

Instale pelos pacotes do Ubuntu:

```sh
sudo apt install -y pgbackrest
```

```
ana@vm:~$ pgbackrest version
pgBackRest 2.50
```

O pgBackRest trabalha com **repositórios** e **stanzas**. Um repositório é onde ficam os backups e o
log arquivado; uma stanza é o conjunto de backups de um servidor PostgreSQL dentro dele, com um nome
que você escolhe. Um repositório pode guardar as stanzas de muitos servidores, e uma stanza pode ser
copiada para mais de um repositório, que é o que a lição 9 faz.

A configuração dele é um arquivo só, `/etc/pgbackrest.conf`. O pacote instala um exemplo ali;
substitua-o por este, usando `sudo nano /etc/pgbackrest.conf` ou qualquer editor rodado com `sudo`:

```schooling-example
{"language": "ini", "file": "pgbackrest.conf", "parts": [{"code": "[global]\nrepo1-path=/var/lib/pgbackrest", "note": "Configurações que valem para tudo. Por enquanto o repositório é um diretório nesta máquina; a lição 9 leva uma cópia dele para outro lugar."}, {"code": "repo1-retention-full=2", "note": "Manter dois backups full, com tudo o que depende deles. A próxima seção mostra o que isso apaga, e quando."}, {"code": "compress-type=zst", "note": "Comprimir com zstd, que é rápido e compacto. O padrão, gzip, é mais lento para o mesmo tamanho."}, {"code": "start-fast=y\n", "note": "Pedir ao servidor um checkpoint imediato no início de um backup, como o -c fast do pg_basebackup."}, {"code": "[main]\npg1-path=/var/lib/postgresql/16/main", "note": "A stanza, chamada main por causa do cluster. O pg1-path é o diretório de dados que o pg_lsclusters mostrou na lição 1."}]}
```

O pgBackRest roda como o usuário `postgres` do sistema operacional, o dono do diretório de dados, e
todo comando desta lição começa com `sudo -u postgres`.

## O archive command, substituído

A lição 4 arquivava com `cp`. O pgBackRest tem um comando próprio para isso, o `archive-push`, que
comprime cada segmento, calcula o checksum, grava no repositório e garante que ele chegou ao disco
antes de informar sucesso:

```
shop=# ALTER SYSTEM SET archive_mode = on;
ALTER SYSTEM

shop=# ALTER SYSTEM SET archive_command = 'pgbackrest --stanza=main archive-push %p';
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 main restart
```

Se você ainda tem as configurações da lição 4, isto as substitui; o restart só é necessário se o
`archive_mode` estava desligado.

## Criando a stanza, e conferindo

O `stanza-create` cria os diretórios da stanza no repositório e registra a qual servidor ela
pertence. O `check` então prova que o caminho inteiro funciona, de ponta a ponta: pede ao servidor
que troque de segmento e espera até esse segmento chegar ao repositório pelo `archive_command`. Os
dois ficam calados se ninguém pedir o contrário, então estes dois pedem o log deles no nível `info`:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --log-level-console=info stanza-create
2026-10-10 16:27:29.544 P00   INFO: stanza-create command begin 2.50: --exec-id=981-2fbfb15f --log-level-console=info --pg1-path=/var/lib/postgresql/16/main --repo1-path=/var/lib/pgbackrest --stanza=main
2026-10-10 16:27:30.152 P00   INFO: stanza-create for stanza 'main' on repo1
2026-10-10 16:27:30.156 P00   INFO: stanza-create command end: completed successfully (614ms)
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --log-level-console=info check
2026-10-10 16:27:30.184 P00   INFO: check command begin 2.50: --exec-id=988-b010d3cf --log-level-console=info --pg1-path=/var/lib/postgresql/16/main --repo1-path=/var/lib/pgbackrest --stanza=main
2026-10-10 16:27:30.789 P00   INFO: check repo1 configuration (primary)
2026-10-10 16:27:30.990 P00   INFO: check repo1 archive for WAL (primary)
2026-10-10 16:27:30.990 P00   INFO: WAL segment 000000010000000000000002 successfully archived to '/var/lib/pgbackrest/archive/main/16-1/0000000100000000/000000010000000000000002-457829d86e276a258a6ad80bbebeff102a1e45a5.zst' on repo1
2026-10-10 16:27:30.990 P00   INFO: check command end: completed successfully (807ms)
```

A linha que importa é **`WAL segment … successfully archived`**: o servidor terminou um segmento,
rodou o `archive-push`, e o segmento chegou ao repositório. O `check` é o teste mais barato que existe
do caminho de arquivamento, e a rotina noturna do fim desta lição o roda primeiro.
