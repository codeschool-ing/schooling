---
title: Onde o cliente guarda a senha
version: 1
---

Uma pessoa consegue digitar uma senha num prompt. Um programa não, nem um script que roda às
três da manhã. A libpq — a biblioteca embaixo do `psql` e da maioria dos clientes PostgreSQL —
lê um **arquivo de senhas**, `~/.pgpass`, com uma linha por servidor, porta, banco e papel:

```
db.ipe.example:5433:ipe:bruno:<bruno's password>
```

No laboratório o arquivo da Ana tem uma linha para cada um dos seis papéis, porque as aulas
precisam conectar como cada um. **Um arquivo de verdade guarda as senhas de uma pessoa, nunca as
de um time.** Ana conhecer a senha do Bruno faria de cada linha de log que diz `bruno` uma linha
que pode significar Ana.

O arquivo é um segredo em disco, e a libpq confere como ele está guardado antes de usá-lo:

```
ana@lab:~/gov$ ls -l ~/.pgpass
-rw-r--r-- 1 ana ana 269 Oct  6 23:46 /home/ana/.pgpass
ana@lab:~/gov$ psql -h db.ipe.example -U bruno -c "SELECT current_user"
WARNING: password file "/home/ana/.pgpass" has group or world access; permissions should be u=rw (0600) or less
Password for user bruno: 
WARNING: password file "/home/ana/.pgpass" has group or world access; permissions should be u=rw (0600) or less
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: fe_sendauth: no password supplied
ana@lab:~/gov$ chmod 600 ~/.pgpass
ana@lab:~/gov$ psql -h db.ipe.example -U bruno -c "SELECT current_user"
 current_user 
--------------
 bruno
(1 row)
```

Com o arquivo legível por todos os usuários da máquina, a libpq se recusa a usá-lo — avisa, volta
a pedir a senha num prompt e, sem terminal para perguntar, desiste. Legível só pela Ana, funciona.
**Essa recusa é o cliente protegendo a senha, não o servidor**, e é o modelo para todo arquivo de
credencial deste curso: o programa que o lê deve recusar um arquivo que qualquer outro possa ter
lido.

## Como é uma senha errada

```
ana@lab:~/gov$ PGPASSWORD=lab-bruno-2025 psql -h db.ipe.example -U bruno -c "SELECT 1"
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  password authentication failed for user "bruno"
connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  password authentication failed for user "bruno"
ana@lab:~/gov$ PGPASSWORD=lab-bruno-2026 psql -h db.ipe.example -U nobody -c "SELECT 1"
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  password authentication failed for user "nobody"
connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  password authentication failed for user "nobody"
```

Duas coisas valem ser vistas aqui.

**A mensagem é a mesma para uma senha errada e para um papel que não existe.** `nobody` não é
papel neste cluster, e o servidor responde exatamente como responde ao Bruno com a senha do ano
passado. Qualquer outra coisa transformaria o formulário de login num jeito de perguntar quais
contas existem, que é a primeira coisa que alguém sondando um banco quer saber.

**Cada tentativa sai impressa duas vezes.** O cliente tentou uma vez com conexão cifrada e outra
sem, e as duas foram recusadas. Esse é o padrão da libpq, `sslmode=prefer`, e a aula 3 explica por
que "prefer" é a palavra errada em que confiar.

O servidor, que sabe mais do que conta ao cliente, escreve o motivo real no próprio log. A
seção 11 o lê.
