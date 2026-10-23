---
title: Um papel no banco com senha
version: 1
---

A aula 4 se conectou como ana, uma superusuária, pelo socket local, sem senha. A aplicação de um
servidor se conecta como **um papel próprio**, com senha, por TCP, e é dona do seu banco e de nada
mais, para que um bug ou um vazamento no agenda alcance os dados do agenda e não os do servidor.

Acrescente os três valores ao `.env`, com a senha gerada como a chave foi, e crie o papel com ela. A
senha chega ao `psql` por uma variável, então nunca aparece num comando nem no histórico do shell:

```
ana@vm:~/agenda$ printf 'DATABASE_USER=agenda_app\nDATABASE_PASSWORD=%s\nDATABASE_HOST=localhost\n' "$(python3 -c 'import secrets; print(secrets.token_urlsafe(24))')" >> .env
ana@vm:~/agenda$ echo "create role agenda_app login createdb password :'pw'" | sudo -u postgres psql -v pw="$(sed -n 's/^DATABASE_PASSWORD=//p' .env)"
CREATE ROLE
```

O `createdb` deixa o papel criar o banco que o pytest-django faz a cada rodada, o que serve a uma
máquina de desenvolvimento e não à produção. Depois entregue a ele as tabelas do agenda e o próprio
banco; os dois eram da ana:

```
ana@vm:~/agenda$ sudo -u postgres psql agenda -c "reassign owned by ana to agenda_app" -c "alter database agenda owner to agenda_app"
REASSIGN OWNED
ALTER DATABASE
```

## Duas recusas

Sem host, o `psql` usa o socket, e o socket usa autenticação peer, que a aula 4 prometeu que você
encontraria:

```
ana@vm:~/agenda$ psql -U agenda_app agenda -c "select current_user"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "agenda_app"
```

**`Peer authentication failed`**: pelo socket, o PostgreSQL do Ubuntu só deixa entrar um papel com o
mesmo nome do usuário do sistema operacional que se conecta, e não existe usuário `agenda_app`. Por
TCP, ele pede uma senha no lugar, e a confere:

```
ana@vm:~/agenda$ PGPASSWORD=wrong psql -h localhost -U agenda_app agenda -c 'select current_user'
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  password authentication failed for user "agenda_app"
connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  password authentication failed for user "agenda_app"
```

Com a certa, do `.env`, pelo Django:

```
ana@vm:~/agenda$ uv run --env-file .env python manage.py dbshell -- -c "select current_user, inet_server_addr()"
 current_user | inet_server_addr 
--------------+------------------
 agenda_app   | 127.0.0.1
(1 row)

ana@vm:~/agenda$ uv run --env-file .env pytest -q
.................                                                                            [100%]
17 passed in 8.92s
```

O `dbshell` passou as configurações ao `psql`: **agenda_app, em 127.0.0.1**, por TCP. Os testes rodaram
como esse papel também, criando e apagando o banco deles.
