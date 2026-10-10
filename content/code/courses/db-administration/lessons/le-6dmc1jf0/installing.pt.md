---
title: Instalando o PostgreSQL pelos pacotes do Ubuntu
version: 1
---

Um servidor Ubuntu recém-instalado não tem banco nenhum, e pedir o cliente prova isso:

```
ana@db:~$ psql --version
-bash: line 1: psql: command not found
```

Dois comandos instalam o servidor, o cliente `psql` e tudo de que eles precisam:

```sh
sudo apt update
sudo apt install -y postgresql
```

O `sudo` pede sua senha, e o `apt` imprime uma tela de progresso por um ou dois minutos. O pacote
chamado `postgresql` é pequeno, e seu único trabalho é puxar a versão maior atual para esta
versão do Ubuntu — no 24.04, `postgresql-16`. As últimas linhas falam em criar um **cluster**, que
é a palavra do PostgreSQL para um servidor rodando e o diretório onde moram os seus dados. A
palavra é mais antiga que o sentido moderno de "um grupo de máquinas", e aqui ela quer dizer um
servidor. Pergunte o que você ganhou:

```
ana@db:~$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@db:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

**Leia essa string de versão uma vez, porque a lição 20 depende dela.** `16` é a **versão maior**;
`.15` é a décima quinta **versão menor** dela, que traz correções de bugs e de segurança e nada
mais. A parte entre parênteses é o empacotamento do próprio Ubuntu para essa versão. O seu número
pode ser maior: o Ubuntu publica cada versão menor como uma atualização comum.

O `pg_lsclusters` não faz parte do PostgreSQL. Ele vem do **postgresql-common**, a camada do Debian
e do Ubuntu em volta dele, que deixa uma máquina rodar vários clusters lado a lado, até de versões
maiores diferentes. Todo cluster tem uma versão e um nome — aqui `16` e `main` — e a linha diz as
quatro coisas que se pergunta sobre qualquer servidor: a porta, se está no ar, onde estão os dados
e onde ele escreve o log.

## O serviço

O systemd subiu o cluster no momento em que ele foi instalado, e sobe de novo a cada boot:

```
ana@db:~$ systemctl status postgresql@16-main --no-pager
● postgresql@16-main.service - PostgreSQL Cluster 16-main
     Loaded: loaded (/usr/lib/systemd/system/postgresql@.service; enabled-runtime; preset: enabled)
     Active: active (running) since Sat 2026-10-10 03:28:12 -03; 789ms ago
    Process: 2482 ExecStart=/usr/bin/pg_ctlcluster --skip-systemctl-redirect 16-main start (code=exited, status=0/SUCCESS)
   Main PID: 2487 (postgres)
        CPU: 148ms
     CGroup: /system.slice/system-postgresql.slice/postgresql@16-main.service
             ├─2487 /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main -c config_file=/etc/postgresql/16/main/postgresql.conf
             ├─2488 "postgres: 16/main: checkpointer "
             ├─2489 "postgres: 16/main: background writer "
             ├─2491 "postgres: 16/main: walwriter "
             ├─2492 "postgres: 16/main: autovacuum launcher "
             └─2493 "postgres: 16/main: logical replication launcher "
```

A unidade é `postgresql@16-main`: um **template**, `postgresql@.service`, com a versão e o nome do
cluster depois do `@`. Um segundo cluster seria uma segunda instância do mesmo template. Existe
também um `postgresql.service` simples, que não faz nada por conta própria e repassa `start`,
`stop` e `restart` a todos os clusters da máquina. `sudo systemctl restart postgresql` é a forma
curta que você vai ver na maioria das instruções, e numa máquina com um cluster as duas querem dizer
a mesma coisa.

A árvore embaixo de `CGroup` é o próprio servidor. **A primeira linha é o postmaster**, o processo
iniciado com o diretório de dados depois de `-D` e o arquivo de configuração depois de
`config_file`. Os cinco abaixo dele são os processos de fundo que ele iniciou, cada um com o nome
do seu trabalho. As lições 7 e 8 tratam do checkpointer e do WAL writer, a lição 14 do autovacuum
launcher. Cada cliente que conecta acrescenta mais um processo a essa lista, e a lição 10 é sobre
por que isso importa.
