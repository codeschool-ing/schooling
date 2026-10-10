---
title: O que o Ubuntu guarda fora do diretório de dados
version: 1
---

Num servidor montado pelas instruções do próprio projeto PostgreSQL, o diretório de dados guarda
tudo: `postgresql.conf`, `pg_hba.conf` e o log, todos ao lado de `base/`. O Debian e o Ubuntu tiram
três coisas de lá, e **saber quais três é metade de achar qualquer coisa num servidor que você
herda**.

## A configuração, em /etc

```
ana@db:~$ ls -l /etc/postgresql/16/main
total 60
drwxr-xr-x 2 postgres postgres  4096 Oct 10 03:18 conf.d
-rw-r--r-- 1 postgres postgres   315 Oct 10 03:18 environment
-rw-r--r-- 1 postgres postgres   143 Oct 10 03:18 pg_ctl.conf
-rw-r----- 1 postgres postgres  5924 Oct 10 03:18 pg_hba.conf
-rw-r----- 1 postgres postgres  2640 Oct 10 03:18 pg_ident.conf
-rw-r--r-- 1 postgres postgres 30243 Oct 10 03:18 postgresql.conf
-rw-r--r-- 1 postgres postgres   317 Oct 10 03:18 start.conf
```

O `postgresql.conf` e o `pg_hba.conf` são os dois de que a lição 5 trata, e o `pg_ident.conf` é o
mapa que a lição 11 usa. O `conf.d/` é um diretório vazio que o arquivo principal lê no fim, e é ali
que uma mudança sua deve ficar, e não no arquivo de 30 kB. Os outros três são do postgresql-common:

| arquivo | o que decide |
|---|---|
| `start.conf` | se o cluster sobe no boot: `auto`, `manual` ou `disabled` |
| `environment` | variáveis de ambiente com que o servidor é iniciado |
| `pg_ctl.conf` | opções extras para o `pg_ctl`, o programa que sobe e para o servidor |

```
ana@db:~$ cat /etc/postgresql/16/main/start.conf | grep -v "^#"

auto
```

Tudo menos os comentários: `auto`. Um cluster que você mantém para um ensaio e não quer rodando
depois de cada reboot fica como `manual`.

Tirar a configuração do diretório de dados compra uma coisa: **o diretório de dados vira só dados**.
Ele pode ser apagado e refeito, restaurado de um backup ou trocado por uma cópia de outro servidor
sem perder um único ajuste, e `/etc` é onde todo outro serviço da máquina guarda a configuração de
qualquer jeito.

## O log e o socket

```
ana@db:~$ ls -l /var/log/postgresql /var/run/postgresql
/var/log/postgresql:
total 4
-rw-r----- 1 postgres adm 560 Oct 10 04:11 postgresql-16-main.log

/var/run/postgresql:
total 4
-rw-r--r-- 1 postgres postgres 4 Oct 10 04:11 16-main.pid
```

O log é um arquivo por cluster, com a versão e o nome dele, legível pelo grupo `adm` para que um
administrador não precise virar `postgres` para lê-lo. O Ubuntu o rotaciona uma vez por semana com o
logrotate. A lição 19 é sobre o que vai dentro dele.

O `/var/run/postgresql` guarda o socket que você viu na lição 3, que o `ls` não mostra porque o nome
começa com ponto, e o `16-main.pid`, o registro do próprio postgresql-common do processo do
servidor.

## Criando e removendo clusters

Como uma máquina pode ter vários clusters, o postgresql-common tem comandos para criá-los e
removê-los, e a lição 3 usou dois deles para começar de novo:

```sh
sudo pg_dropcluster --stop 16 main
sudo pg_createcluster --start 16 main
```

O `pg_dropcluster --stop` para o cluster e apaga **o diretório de dados, o diretório de configuração e
o log dele** — os três lugares que esta seção e a anterior descreveram. Nada é guardado e nada
pergunta duas vezes. O `pg_createcluster` roda o `initdb`, o programa que cria um diretório de dados
vazio, escreve uma configuração nova em `/etc/postgresql/16/main` e, com `--start`, sobe o cluster. O
cluster novo só tem o papel `postgres`, como no dia em que você instalou.

Um segundo cluster ao lado do primeiro recebe outro nome e a próxima porta livre:
`sudo pg_createcluster 16 rehearsal` criaria `/var/lib/postgresql/16/rehearsal` escutando na 5433. A
lição 20 faz exatamente isso para ensaiar um upgrade sem encostar no `main`.
