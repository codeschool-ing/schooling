---
title: Instalar o PostgreSQL 16, e apontar o agenda para ele
version: 1
---

A aula 3 terminou com as inscrições numa lista Python, perdidas a cada reinício e erradas com duas
requisições ao mesmo tempo. Elas precisam de um banco, e este curso usa o **PostgreSQL 16**, a versão
que o Ubuntu 24.04 traz. O SQLite, que o agenda usou até aqui, é um bom banco para um escritor por
vez; um site onde muita gente se inscreve ao mesmo tempo quer um servidor que faça travas de linha,
que é a última seção desta aula, e o SQLite não tem nenhuma para fazer.

## Três lugares para tê-lo

| caminho | o que você ganha | quanto custa ao seu computador |
|---|---|---|
| **na sua máquina virtual** (recomendado) | o PostgreSQL 16 do arquivo do Ubuntu, como serviço | o disco do pacote, e um servidor rodando em segundo plano na máquina virtual |
| **instalado no seu computador** | os instaladores do postgresql.org para Windows e macOS | o mesmo, no computador em que você também trabalha |
| **online** | um banco que uma empresa de hospedagem roda por você | nada no seu computador; uma conta mensal ou uma cota gratuita nos termos de outra pessoa |

**A máquina virtual é a escolha**, e é a mesma instalação que o curso `sql-databases` usa na aula 1,
então quem fizer aquele curso depois já a terá. No seu próprio computador, os instaladores funcionam e
toda consulta deste curso roda igual, mas os comandos de preparação abaixo são do Ubuntu e não foram
rodados em outro lugar. Um banco hospedado funciona com o Django sem mudança, precisa de senha e de um
nome de host em vez do socket local, e a aula 15 diz como o agenda lê esses valores; ele não foi
usado neste curso, e nada aqui depende de uma empresa oferecê-lo.

## Instalando

Na máquina virtual:

```sh
sudo apt update
sudo apt install -y postgresql
```

O pacote instala o servidor, o cliente `psql` e a libpq, a biblioteca C que todo cliente usa para
conversar com o PostgreSQL, e sobe um **cluster**: um servidor rodando, com o diretório de dados
dele.

```
ana@vm:~/agenda$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~/agenda$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

Um cluster, versão 16, chamado `main`, na porta 5432, **online**. A última coluna é o arquivo de log,
o primeiro lugar a olhar quando ele se comporta mal.

## Um papel e um banco

O PostgreSQL tem a própria lista de usuários, chamados **papéis** (roles), e o único com que ele
começa é o `postgres`. Crie um com o seu nome de login, como o `sql-databases` faz, e depois um banco
para o agenda:

```
ana@vm:~/agenda$ sudo -u postgres createuser --superuser $USER
```

```
ana@vm:~/agenda$ createdb agenda
```

Os dois não imprimem nada quando funcionam. O `--superuser` deixa o seu papel fazer qualquer coisa
neste servidor, o que é certo para uma máquina só sua, e os testes da aula 14 precisam de parte disso:
o Django cria um banco separado para rodá-los. **Um papel com o seu nome de login conecta sem senha**
pelo socket local, porque o PostgreSQL do Ubuntu confia no sistema operacional para dizer quem você
é; isso se chama autenticação **peer**.

## O driver, e a configuração

O Django conversa com o PostgreSQL pelo **psycopg**, uma biblioteca Python sobre a libpq:

```
ana@vm:~/agenda$ uv add psycopg
Resolved 7 packages in 296ms
Prepared 1 package in 99ms
Installed 2 packages in 5ms
 + psycopg==3.3.6
 + typing-extensions==4.16.0
```

Depois troque o `DATABASES` em `config/settings.py`. Sem usuário, sem senha e sem host: o Django
conecta como você, pelo socket, no banco chamado `agenda`.

```
ana@vm:~/agenda$ sed -n '/^DATABASES/,/^}/p' config/settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'agenda',
    }
}
```

Os apps embutidos do Django ganham agora as tabelas no PostgreSQL. As primeiras linhas do `migrate`
são as mesmas dezoito da aula 2; estas são as últimas:

```
ana@vm:~/agenda$ uv run python manage.py migrate | tail -3
  Applying auth.0011_update_proxy_permissions... OK
  Applying auth.0012_alter_user_first_name_max_length... OK
  Applying sessions.0001_initial... OK
```

O arquivo do SQLite não é mais usado, então apague com `rm db.sqlite3`. E pergunte ao PostgreSQL o
que ele guarda agora, com o `psql` e o comando dele para listar tabelas:

```
ana@vm:~/agenda$ psql agenda -c "\dt"
                  List of relations
 Schema |            Name            | Type  | Owner 
--------+----------------------------+-------+-------
 public | auth_group                 | table | ana
 public | auth_group_permissions     | table | ana
 public | auth_permission            | table | ana
 public | auth_user                  | table | ana
 public | auth_user_groups           | table | ana
 public | auth_user_user_permissions | table | ana
 public | django_admin_log           | table | ana
 public | django_content_type        | table | ana
 public | django_migrations          | table | ana
 public | django_session             | table | ana
(10 rows)
```

**O dono de toda tabela é `ana`**, o papel que você criou, porque o Django conectou como ele.
