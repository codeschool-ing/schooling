---
title: Um PostgreSQL só seu
version: 1
---

Desta aula em diante, o boxoffice guarda os eventos num banco de dados, então a sua máquina precisa
de um: **o PostgreSQL 16, a versão que o Ubuntu 24.04 traz**, a mesma que o `sql-databases` instala
na aula 1 dele. Se você fez esse curso, o seu servidor já está rodando; confira com os dois primeiros
comandos abaixo e pule para o role. Na trilha de backend, porém, o `sql-databases` vem depois deste
curso, então, se você ainda não passou por ele, esta seção é tudo de que você precisa.

## Três lugares para rodá-lo

| caminho | o que custa ao seu computador | para este curso |
|---|---|---|
| **instalado** pelo arquivo do Ubuntu (recomendado) | uns 50 MB em disco, e um processo servidor que ocupa algumas dezenas de megabytes de memória parado | toda transcrição roda como impressa |
| **na máquina virtual** que você talvez já use para o Go | o mesmo, dentro da máquina | o mesmo |
| **num container**, `postgres:16` do Docker Hub | antes, um motor de containers, que a aula 16 instala | funciona, com uma senha e um endereço TCP no lugar do socket abaixo |

O quarto caminho, um banco hospedado por uma empresa de nuvem, exige uma conta e uma conexão de rede a
cada consulta, e **um curso não deve depender da camada gratuita de uma empresa**, então ele não é um
dos três. Instale se puder: o servidor é pequeno, sobe junto com a máquina e o socket dele não pede
senha, o que deixa curtos todos os comandos destas aulas.

## Instalando

Estes dois comandos instalam o servidor, o cliente `psql` e as ferramentas do Ubuntu em volta deles.
O laboratório instalou o PostgreSQL exatamente com eles, e a tela de progresso não está reproduzida
aqui:

```sh
sudo apt update
sudo apt install -y postgresql
```

Depois pergunte o que você ganhou:

```
ana@vm:~/boxoffice$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~/boxoffice$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@vm:~/boxoffice$ psql -c "SELECT 1"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

**Versão 16, um cluster chamado `main` na porta 5432, online.** Cluster é a palavra do PostgreSQL para
um servidor rodando e o diretório de dados dele. A última coluna é o arquivo de log, o primeiro lugar
para olhar quando algo dá errado. A recusa no fim é esperada: o PostgreSQL mantém a própria lista de
usuários, chamados **roles**, e o instalador pôs nela só o `postgres`.

## Um role e um banco

```
ana@vm:~/boxoffice$ sudo -u postgres createuser --superuser $USER
ana@vm:~/boxoffice$ createdb boxoffice
ana@vm:~/boxoffice$ psql boxoffice -c "SELECT current_user, current_database()"
 current_user | current_database 
--------------+------------------
 ana          | boxoffice
(1 row)
```

O `createuser`, rodado como `postgres`, acrescenta um role com o seu nome de login; `--superuser`
deixa esse role fazer qualquer coisa neste servidor, o que é certo numa máquina só sua e errado em
qualquer outro lugar. O `createdb` cria o banco que o boxoffice vai usar. Nenhum dos dois imprimiu
nada, que é o jeito de os dois dizerem que funcionaram.

**Nenhuma senha foi pedida em momento algum**, e nenhuma será. O `psql` e o boxoffice se conectam por
um socket Unix em `/var/run/postgresql`, e o PostgreSQL do Ubuntu confia numa conexão pelo socket vinda
do usuário do sistema operacional de mesmo nome, o que se chama **autenticação peer**. É por isso que o
endereço que o boxoffice vai usar nomeia o diretório do socket em vez de um host e uma porta:

```sh
export DATABASE_URL='postgres:///boxoffice?host=/var/run/postgresql'
```

Leia assim: o protocolo do PostgreSQL, nenhum host no lugar de costume, o banco `boxoffice` e o
diretório do socket como `host`. Ponha essa linha no `~/.profile`, ao lado dos tokens da aula 2, para
todo terminal novo tê-la.
