---
title: Instalando o PostgreSQL e criando o banco da livraria
version: 1
---

No prompt da sua máquina Ubuntu, dois comandos instalam o servidor, o cliente `psql` e o que eles
precisam:

```sh
sudo apt update
sudo apt install -y postgresql
```

O `apt` imprime uma tela de progresso, e as últimas linhas falam de criar um **cluster**, a palavra
do PostgreSQL para um servidor rodando e o diretório onde ficam os dados dele. Pergunte o que você
ganhou:

```
ana@vm:~$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

Versão 16, um cluster chamado `main`, **`online`**, na porta 5432, que é a porta que toda conexão
deste curso nomeia. A última coluna é o log do servidor, e a última seção desta aula vai até ele por
um motivo que o cliente nunca fica sabendo.

## Um papel e um banco para a livraria

O servidor mantém a própria lista de quem pode se conectar, separada dos usuários do computador.
Cada entrada é um **papel** (*role*), e o instalador criou exatamente um, o `postgres`. Você não está
na lista:

```
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

Essa recusa é, de certo modo, uma boa notícia. **Uma linha `FATAL:` é o servidor respondendo**,
então ele está instalado, rodando e escutando.

Só que a livraria não vai se conectar como você. Uma aplicação ganha um papel próprio, com senha, e
é dona de um banco próprio, para que o que ela pode tocar seja decidido num lugar só. O Ubuntu deixa
o usuário `postgres` do computador agir como o papel `postgres` do servidor, então os dois comandos
rodam como esse usuário:

```
ana@vm:~$ sudo -u postgres psql -c "CREATE ROLE bookshop LOGIN PASSWORD 'bookshop'"
CREATE ROLE
ana@vm:~$ sudo -u postgres createdb -O bookshop bookshop
```

O primeiro é SQL, enviado pelo `psql`: um papel chamado `bookshop`, que pode fazer login, com a senha
`bookshop`. Uma senha igual ao nome serve numa máquina que só você alcança e é errada em qualquer
outro lugar; a aula 23 a tira dos arquivos do projeto. O segundo cria um banco chamado `bookshop` e,
com `-O`, o entrega ao papel novo, para que a aplicação possa criar as próprias tabelas lá. O
`createdb` não imprimiu nada, que é o jeito dele de dizer que deu certo.

## Duas portas para o mesmo servidor

O próximo passo óbvio é recusado:

```
ana@vm:~$ psql -U bookshop bookshop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "bookshop"
```

A senha não está errada; ela nem foi pedida. O `psql` sem host se conecta por um **arquivo de
socket** nesta máquina, e para essa porta a configuração do Ubuntu usa autenticação **peer**: o
servidor pergunta ao sistema operacional quem está chamando, recebe `ana`, e recusa um login como
`bookshop`. Conectar em `localhost` passa pela outra porta, TCP na 5432, onde a regra é senha. Uma
URL de conexão nomeia o host, então ela entra por essa porta:

```
ana@vm:~$ psql postgresql://bookshop:bookshop@localhost:5432/bookshop
psql (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.

bookshop=> SELECT current_user, current_database();
 current_user | current_database 
--------------+------------------
 bookshop     | bookshop
(1 row)
```

A URL se lê da esquerda para a direita como protocolo, usuário, senha, host, porta e banco. **O JDBC
sempre entra pela porta TCP**, então este é exatamente o login que a livraria vai fazer, e se ele
funciona, o lado do servidor de tudo o que vem depois funciona também. A linha `SSL connection` diz
que a conversa é criptografada mesmo dentro de uma máquina só, porque o PostgreSQL do Ubuntu já vem
com um certificado.

`bookshop=>` é o prompt: o banco em que você está, e `>` porque o papel não é superusuário. Um
comando termina no ponto e vírgula. Comandos que começam com barra invertida são do próprio `psql`,
e `\q` é o que sai.
