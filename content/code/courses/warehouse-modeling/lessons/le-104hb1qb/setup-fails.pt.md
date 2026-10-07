---
title: Quando a instalação falha
version: 1
---

**A maioria das instalações falha num passo pulado ou feito duas vezes**, e cada falha se anuncia com as
próprias palavras. Aqui estão as que uma primeira execução encontra, cada uma provocada na máquina de
gravação pulando ou repetindo o passo, com o que a mensagem quer dizer e o que digitar.

## O servidor não está rodando

```
ana@lab:~/wh$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@lab:~/wh$ psql -c 'SELECT 1'
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
```

`down` no `pg_lsclusters` e *No such file or directory* no `psql`: o servidor está instalado e
parado. Onde o Ubuntu inicia serviços no boot, inicia este também. O WSL sem systemd não inicia, nem
alguns contêineres. Inicie-o e confira:

```
ana@lab:~/wh$ sudo pg_ctlcluster 16 main start
ana@lab:~/wh$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

## O papel não existe

```
ana@lab:~/wh$ psql -c 'SELECT 1'
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

O servidor está de pé e não conhece o seu nome de login. O `createuser` da seção 04 cria o papel.

## O banco não existe

```
ana@lab:~/wh$ psql -c 'SELECT 1'
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "shop" does not exist
```

O papel existe e o `shop` não. O `PGDATABASE` do `~/.bashrc` faz o `psql` se conectar ao `shop` tenha
ele sido criado ou não; o `createdb` o cria.

## Uma configuração que não mudou

```
ana@lab:~/wh$ psql -c 'SHOW shared_buffers'
 shared_buffers 
----------------
 128MB
(1 row)
```

O `ALTER SYSTEM` escreveu o valor novo na configuração do servidor, e o servidor leu a configuração
quando iniciou. `sudo pg_ctlcluster 16 main restart`, e a mesma consulta responde `512MB`.

## Carregar duas vezes

```
ana@lab:~/wh$ sh load.sh
ERROR:  duplicate key value violates unique constraint "shops_pkey"
DETAIL:  Key (shop_id)=(1) already exists.
CONTEXT:  COPY shops, line 2
```

O `load.sh` para no primeiro erro, então nada depois da primeira tabela foi carregado na segunda vez,
e nada carregado na primeira se perdeu. Cada tabela já tem as suas linhas, e as chaves delas recusam
uma segunda cópia. Se uma carga tivesse falhado no meio, o banco teria parte dos dados, e o conserto
mais simples para os dois casos é recomeçar o banco:

```
ana@lab:~/wh$ dropdb shop && createdb --locale=C.UTF-8 --template=template0 shop && psql -q -f oltp.sql && sh load.sh
```

## Qualquer outra coisa

- `duckdb: command not found`, ou o `python3` não consegue importar `duckdb`: o ambiente virtual não
  está ativo neste terminal. A linha do `~/.bashrc` o ativa em todo terminal novo; `. ~/.bashrc` o
  ativa neste.
- O `pip` não alcança o índice de pacotes: um proxy ou um firewall entre a sua máquina e a internet.
  O ambiente virtual fica vazio até o `pip install` funcionar.
- `No space left on device`: o PostgreSQL precisa do 1,1 GB da seção 05 de uma vez, e lições
  posteriores escrevem cópias do warehouse ao lado dele. `df -h ~` diz quanto sobra. Uma máquina
  virtual pode ganhar um disco maior; uma do Multipass é mais fácil de recriar com um `--disk` maior.

Para o que não estiver nesta lista, leia as últimas linhas que um comando imprimiu. O `load.sh` e o
script de construção da lição 2 param no primeiro erro, então a última mensagem é a que importa.
