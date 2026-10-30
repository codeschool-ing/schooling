---
title: Flags de banco de dados, praticadas no próprio motor
version: 1
---

**Uma flag de banco de dados é uma configuração do motor, guardada pelo Cloud SQL e mudada pela API
dele.** No servidor do armário, o PostgreSQL lê `postgresql.conf` e `postgresql.auto.conf` do diretório
de dados. No Cloud SQL não há diretório ao seu alcance, então as mesmas configurações são uma lista de
pares `nome=valor` na instância, `--database-flags`, que o Cloud SQL escreve na configuração do motor
por você. **Cada flag é uma configuração do PostgreSQL, com o nome do PostgreSQL**, e se ela pode mudar
com o servidor rodando é regra do PostgreSQL, não do Google. É por isso que esta seção pode praticar
flags num notebook: a regra mora no motor, e o motor é de graça.

## PostgreSQL 16 no notebook

O Ubuntu empacota a mesma versão principal que o Cloud SQL roda para `POSTGRES_16`. Instalá-lo também
inicia um servidor próprio na porta 5432, que este curso não usa; a segunda linha o para e o impede de
subir junto com a máquina:

```sh
sudo apt-get install -y postgresql-16
sudo systemctl disable --now postgresql
```

Num WSL sem `systemd`, a segunda linha é `sudo service postgresql stop`, e ela precisa ser repetida a
cada reinício do WSL. O servidor do próprio curso roda como você, em `~/gcp/pg`, na porta **5433**,
então um servidor do sistema esquecido na 5432 nunca responde no lugar dele. O Ubuntu deixa os programas
do servidor fora do path, então acrescente isto a todo terminal que usar nesta aula e na próxima:

```sh
export PATH=/usr/lib/postgresql/16/bin:$PATH PGHOST=localhost PGPORT=5433 PGUSER=postgres
```

`PGHOST`, `PGPORT` e `PGUSER` são lidas por todo programa do PostgreSQL, o `psql` inclusive, então
nenhum dos comandos abaixo precisa repeti-las. Depois crie um cluster, o diretório de dados de onde um
servidor roda, e inicie um servidor nele:

```
ana@laptop:~/gcp$ initdb -D ~/gcp/pg/orders -U postgres --auth=trust
The files belonging to this database system will be owned by user "ana".
This user must also own the server process.

The database cluster will be initialized with locale "C.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

creating directory /home/ana/gcp/pg/orders ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... America/Sao_Paulo
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

Success. You can now start the database server using:

    pg_ctl -D /home/ana/gcp/pg/orders -l logfile start

ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/orders -o "-p 5433 -k $HOME/gcp/pg" -l ~/gcp/pg/orders.log start
waiting for server to start.... done
server started
ana@laptop:~/gcp$ psql -Atc 'SELECT version()'
PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit
```

**`-U postgres` dá ao superusuário o nome do que o Cloud SQL cria**, para que todo comando aqui seja o
que você digitaria lá. `--auth=trust` deixa entrar qualquer conexão local sem senha, o que é aceitável
num notebook cujo servidor escuta só em `localhost` e errado em qualquer outro lugar. Duas linhas da
saída valem a leitura: o `initdb` escolheu `max_connections` 100 e `shared_buffers` 128MB, os padrões
dele para uma máquina sobre a qual não sabe nada. O `pg_ctl` inicia o servidor, com `-p` para a porta,
`-k` para o diretório do socket local, e `-l` para o arquivo de log, porque o diretório de sockets do
sistema pertence ao PostgreSQL do sistema.

## Lendo as configurações, e quais precisam de reinício

**Toda configuração tem um contexto**, a palavra do próprio PostgreSQL para quando ela pode mudar, e a
view de catálogo `pg_settings` mostra isso ao lado do valor:

```
ana@laptop:~/gcp$ psql -c "SELECT name, setting, unit, context FROM pg_settings WHERE name IN ('max_connections', 'shared_buffers', 'work_mem', 'log_min_duration_statement') ORDER BY name"
            name            | setting | unit |  context   
----------------------------+---------+------+------------
 log_min_duration_statement | -1      | ms   | superuser
 max_connections            | 100     |      | postmaster
 shared_buffers             | 16384   | 8kB  | postmaster
 work_mem                   | 4096    | kB   | user
(4 rows)
```

| contexto | quando a configuração pode mudar | no Cloud SQL |
|---|---|---|
| `postmaster` | só quando o servidor inicia | definir a flag reinicia a instância |
| `superuser`, `sighup` | num reload da configuração, sem reinício | a flag vale sem reinício |
| `user` | para uma sessão, por qualquer um, com `SET` | a flag define o padrão; uma sessão ainda muda o seu |

**`max_connections` e `shared_buffers` são `postmaster`** porque a memória de cada vaga de conexão e a
do cache de buffers é montada quando o servidor inicia. `shared_buffers` 16384 em unidades de 8 kB são
os 128MB que o `initdb` imprimiu. `log_min_duration_statement`, que registra todo comando mais lento
que o valor dela, é `superuser`: um reload basta. `work_mem`, a memória que uma ordenação ou um hash
pode usar antes de transbordar para o disco, é `user`, e o último bloco desta seção usa isso.

## Mudando duas delas

`ALTER SYSTEM` é como um superusuário muda uma configuração num PostgreSQL rodando. Ele escreve o valor
em `postgresql.auto.conf`, e `pg_reload_conf()` pede ao servidor que leia a configuração de novo:

```
ana@laptop:~/gcp$ psql -c "ALTER SYSTEM SET log_min_duration_statement = '500ms'" -c 'SELECT pg_reload_conf()' -c 'SHOW log_min_duration_statement'
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

 log_min_duration_statement 
----------------------------
 500ms
(1 row)
```

**Aplicada no reload.** Todo comando mais lento que meio segundo agora vai para o log, que é o jeito
mais barato que existe de achar as consultas lentas que a primeira seção disse que continuam suas. O
mesmo com a outra:

```
ana@laptop:~/gcp$ psql -c 'ALTER SYSTEM SET max_connections = 400' -c 'SELECT pg_reload_conf()' -c 'SHOW max_connections'
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

 max_connections 
-----------------
 100
(1 row)
```

**Continua 100.** O reload leu o arquivo, e o servidor não podia aplicar um valor que só monta na
partida, então manteve o antigo e marcou a diferença:

```
ana@laptop:~/gcp$ psql -c "SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'max_connections'"
      name       | setting | pending_restart 
-----------------+---------+-----------------
 max_connections | 100     | t
(1 row)

ana@laptop:~/gcp$ cat ~/gcp/pg/orders/postgresql.auto.conf
# Do not edit this file manually!
# It will be overwritten by the ALTER SYSTEM command.
log_min_duration_statement = '500ms'
max_connections = '400'
ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/orders -l ~/gcp/pg/orders.log restart -m fast
waiting for server to shut down.... done
server stopped
waiting for server to start.... done
server started
ana@laptop:~/gcp$ psql -Atc 'SHOW max_connections'
400
```

**`pending_restart` fica `t` até o servidor reiniciar, e aí o valor é 400.** Esse é todo o comportamento
que o Cloud SQL embrulha. Numa instância, definir `max_connections` com
`gcloud sql instances patch quitanda-orders --database-flags=…` reinicia a instância, e a linha de
comando avisa antes; definir `log_min_duration_statement`, não. A documentação do Google lista, para
cada flag suportada, se ela precisa de reinício, e a lista é a coluna `context` de cima com outro nome.

**Duas armadilhas do comando do Cloud SQL que o local não tem**, ambas da documentação do Google sobre
configurar flags. O `--database-flags` substitui a lista inteira a cada vez: fazer patch numa instância
com `--database-flags=max_connections=400` remove o `log_min_duration_statement=500` com que a
instância foi criada, então todo patch nomeia toda flag. E o `--clear-database-flags` remove todas, o
que a referência marca com "WARNING: Instance will be restarted."

## O que o motor recusa

```
ana@laptop:~/gcp$ psql -c 'ALTER SYSTEM SET max_conections = 400'
ERROR:  unrecognized configuration parameter "max_conections"
ana@laptop:~/gcp$ psql -c "ALTER SYSTEM SET work_mem = '64 potatoes'"
ERROR:  invalid value for parameter "work_mem": "64 potatoes"
HINT:  Valid units for this parameter are "B", "kB", "MB", "GB", and "TB".
```

**O PostgreSQL confere o nome e o valor**, e o Cloud SQL também: uma flag que não está na lista dele
para a versão do motor é recusada, e também um valor fora da faixa que a documentação dá para ela. A
lista do Cloud SQL é mais curta que as configurações do PostgreSQL. Algumas nem são expostas, porque o
Google as opera: a porta, o endereço de escuta, o diretório de dados, o arquivamento de WAL de que os
backups dele dependem. Algumas só existem no Cloud SQL, com nomes que começam com `cloudsql.`, como a
`cloudsql.iam_authentication` da seção anterior e a `cloudsql.logical_decoding`, que a aula 25 liga para
captura de mudanças. `gcloud sql flags list --database-version=POSTGRES_16` imprime a lista de uma
versão; ele pergunta à API, então não foi executado aqui.

## Por que o `postgres` do Cloud SQL não pode fazer isso, e o que ele pode

```
ana@laptop:~/gcp$ psql -c 'CREATE ROLE quitanda_app LOGIN'
CREATE ROLE
ana@laptop:~/gcp$ psql -U quitanda_app -d postgres -c "ALTER SYSTEM SET work_mem = '64MB'"
ERROR:  permission denied to set parameter "work_mem"
ana@laptop:~/gcp$ psql -U quitanda_app -d postgres -c "SET work_mem = '64MB'" -c 'SHOW work_mem'
SET
 work_mem 
----------
 64MB
(1 row)
```

**Um papel que não é superusuário não muda a configuração do servidor**, e essa é a posição do usuário
`postgres` do Cloud SQL, membro de `cloudsqlsuperuser` sem o `SUPERUSER` do PostgreSQL. Então as flags
são da API, e nada que uma conexão diga as muda para a conexão seguinte. **O que qualquer papel pode
fazer é dar `SET` numa configuração `user` para a própria sessão**: um relatório que precisa de uma
ordenação grande pode pedir 64MB de `work_mem` para si, e deixar o padrão pequeno para as quatrocentas
conexões que não precisam. No Cloud SQL isso vale do mesmo jeito, e é o ajuste mais barato que existe,
porque muda uma consulta e não reinicia nada.

```
ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/orders stop
waiting for server to shut down.... done
server stopped
```

O cluster fica em `~/gcp/pg/orders`, parado, e a aula 7 o inicia de novo.
