---
title: O PgBouncer entre a aplicação e o servidor
version: 1
---

O **PgBouncer** é um programa pequeno que aceita conexões como se fosse o PostgreSQL e repassa o
trabalho delas para um **pool** de conexões reais com o servidor, bem menos numerosas, que ele mantém
abertas. Instale-o:

```sh
sudo apt install -y pgbouncer
```

O pacote inicia um PgBouncer como serviço, na porta 6432, com a configuração em `/etc/pgbouncer`.
Esta lição deixa esse em paz e roda o seu próprio, como o seu usuário, na porta **6433**, com tudo em
`~/pgbouncer`, para que você possa alterá-lo e reiniciá-lo sem `sudo`.

A aplicação ganha um papel próprio, `shop_app`, com senha, as permissões de que precisa no `shop` e um
banco `bench` só seu para o `pgbench`:

```
shop=# CREATE ROLE shop_app LOGIN PASSWORD 'app-pass-1';
CREATE ROLE

shop=# GRANT SELECT, INSERT, UPDATE ON customers, orders TO shop_app;
GRANT

shop=# GRANT USAGE ON SEQUENCE orders_id_seq TO shop_app;
GRANT

shop=# ALTER DATABASE bench OWNER TO shop_app;
ALTER DATABASE
ana@vm:~$ echo '127.0.0.1:*:*:shop_app:app-pass-1' >> ~/.pgpass && chmod 600 ~/.pgpass
ana@vm:~$ dropdb bench && createdb -O shop_app bench && pgbench -q -i -s 10 -h 127.0.0.1 -U shop_app bench > /dev/null 2>&1
```

O PgBouncer confere as senhas ele mesmo, antes de ter uma conexão com o servidor a quem perguntar,
então precisa da senha de cada usuário num arquivo próprio. Com SCRAM, que é como o PostgreSQL 16
guarda as senhas, o arquivo contém o mesmo **segredo SCRAM** que o servidor guarda, nunca a senha;
copie-o do servidor:

```
ana@vm:~$ mkdir -p ~/pgbouncer
ana@vm:~$ psql -XAt shop -c "SELECT format('\"%s\" \"%s\"', rolname, rolpassword) FROM pg_authid WHERE rolname = 'shop_app'" > ~/pgbouncer/userlist.txt
ana@vm:~$ cut -c1-60 ~/pgbouncer/userlist.txt
"shop_app" "SCRAM-SHA-256$4096:QldR6MRSe4CH6F47p/P/3w==$9BXx
```

Depois a configuração, salva como `~/pgbouncer/pgbouncer.ini`:

```schooling-example
{"language": "ini", "file": "pgbouncer.ini", "parts": [{"code": "[databases]\nshop = host=127.0.0.1 port=5432 dbname=shop pool_size=1\nbench = host=127.0.0.1 port=5432 dbname=bench\n", "note": "Uma linha por banco que o PgBouncer oferece, e onde ele realmente está. O `shop` fica limitado a um pool de uma conexão com o servidor, para que a última seção possa mostrar o que um pool faz com as configurações de uma sessão."}, {"code": "[pgbouncer]\nlisten_addr = 127.0.0.1\nlisten_port = 6433\nunix_socket_dir =", "note": "Onde ele escuta: só nesta máquina, numa porta própria, ao lado da 6432 do pacote."}, {"code": "auth_type = scram-sha-256\nauth_file = /home/ana/pgbouncer/userlist.txt\nadmin_users = shop_app", "note": "As senhas são conferidas contra o arquivo que você acabou de escrever. Os `admin_users` podem se conectar ao banco especial `pgbouncer` e perguntar sobre os pools."}, {"code": "pool_mode = transaction\nmax_client_conn = 500\ndefault_pool_size = 20", "note": "O modo de pooling, o assunto do resto desta lição, e os tamanhos: até 500 clientes, dividindo no máximo 20 conexões com o servidor por banco e usuário."}, {"code": "logfile = /home/ana/pgbouncer/pgbouncer.log\npidfile = /home/ana/pgbouncer/pgbouncer.pid", "note": "O seu próprio log e o arquivo com o ID do processo, no mesmo diretório."}]}
```

Troque `ana` pelo seu nome de usuário nos três caminhos. Inicie-o em segundo plano com `-d` e
conecte-se através dele exatamente como a um servidor, só que na porta dele:

```
ana@vm:~$ pgbouncer -d ~/pgbouncer/pgbouncer.ini
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app -XAt shop -c "SELECT count(*) FROM orders"
50000
```
