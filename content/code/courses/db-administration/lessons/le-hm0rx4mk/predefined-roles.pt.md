---
title: Papéis predefinidos
version: 1
---

Algumas necessidades aparecem em todo servidor: uma ferramenta de backup que precisa ler tudo, um
agente de monitoramento que precisa ver todas as sessões, um engenheiro de plantão que precisa
conseguir parar uma consulta descontrolada. Antes da versão 10, a resposta comum para a maioria delas
era `SUPERUSER`. **O PostgreSQL agora traz papéis que carregam um desses poderes cada**, com o
prefixo `pg_` e concedidos como qualquer grupo:

```
shop=# SELECT rolname FROM pg_roles WHERE rolname LIKE 'pg\_%' ORDER BY 1;
           rolname           
-----------------------------
 pg_checkpoint
 pg_create_subscription
 pg_database_owner
 pg_execute_server_program
 pg_monitor
 pg_read_all_data
 pg_read_all_settings
 pg_read_all_stats
 pg_read_server_files
 pg_signal_backend
 pg_stat_scan_tables
 pg_use_reserved_connections
 pg_write_all_data
 pg_write_server_files
(14 rows)
```

O `\du` os esconde; a consulta acima lista os catorze que a versão 16 tem. Os que um administrador
mais concede:

| papel | o que um membro pode fazer |
|---|---|
| `pg_read_all_data` | ler toda tabela, visão e sequência, em todo esquema, como se tivesse `SELECT` e `USAGE` em tudo |
| `pg_write_all_data` | inserir, atualizar e apagar em toda tabela, do mesmo jeito |
| `pg_monitor` | ver a consulta de toda sessão no `pg_stat_activity`, e ler as visões de estatística e as configurações de que uma ferramenta de monitoramento precisa |
| `pg_signal_backend` | cancelar ou encerrar as sessões de outros papéis que não são superusuários |
| `pg_checkpoint` | rodar `CHECKPOINT` |
| `pg_use_reserved_connections` | usar as vagas de conexão reservadas pelo `reserved_connections`, novo na 16 |
| `pg_read_server_files`, `pg_write_server_files`, `pg_execute_server_program` | ler arquivos, escrever arquivos e rodar programas no servidor como o usuário `postgres` |

**Os três últimos são um superusuário com outro nome**: quem consegue escrever os arquivos do
servidor consegue reescrever a configuração dele, e quem consegue rodar um programa ali é dono da
conta do banco na máquina. Conceda-os como concederia `SUPERUSER`, ou seja, quase nunca. O
`pg_database_owner` da lição 12 também está na lista, e é o único papel que ninguém recebe: o membro
dele é quem for dono do banco atual.

## Ler tudo, e a porta que isso não abre

O `pg_read_all_data` é o papel para uma ferramenta de backup, um auditor ou uma exportação de dados:

```
shop=# CREATE ROLE auditor LOGIN IN ROLE pg_read_all_data;
CREATE ROLE

shop=# SELECT has_database_privilege('auditor', 'shop', 'CONNECT');
 has_database_privilege 
------------------------
 f
(1 row)

shop=# SET ROLE auditor;
SET

shop=> SELECT email FROM customers ORDER BY id LIMIT 1;
         email         
-----------------------
 customer1@example.com
(1 row)

shop=> SELECT count(*) FROM reports.ideas;
 count 
-------
     0
(1 row)

shop=> INSERT INTO coupons VALUES ('WELCOME', 10);
ERROR:  permission denied for table coupons

shop=> RESET ROLE;
RESET

shop=# DROP ROLE auditor;
DROP ROLE
```

O auditor leu `email`, que o `reporting` nunca recebeu, e uma tabela criada por um estagiário minutos
antes, sem grant em nenhuma das duas e sem privilégio padrão a quem agradecer. Não conseguiu gravar.
E **não teria conseguido nem fazer login**: o `pg_read_all_data` faz as vezes de privilégios de
tabela e de esquema, não de `CONNECT`, que o `shop` dá só ao `app` e ao `reporting`. Um papel feito
para ler precisa receber a primeira porta como qualquer outro.

A segurança por linha ainda o filtra, a menos que ele também tenha `BYPASSRLS`, e o alcance dele
inclui as tabelas que vão existir no ano que vem. É exatamente o que um backup precisa e demais para
um analista, cujo acesso é a lista deliberada que a lição 12 montou.

## Ver e parar outras sessões

Para os dois próximos, comece uma consulta lenta como `app` num segundo terminal, para haver uma
sessão para olhar:

```sh
psql -h localhost -U app shop -c "SELECT pg_sleep(60)"
```

Depois, como `bruno`, procure por ela, uma vez sem o `pg_monitor` e outra com ele:

```
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT pid, usename, state, query FROM pg_stat_activity WHERE usename = 'app';
 pid | usename | state |          query           
-----+---------+-------+--------------------------
 296 | app     |       | <insufficient privilege>
(1 row)
shop=# GRANT pg_monitor TO bruno;
GRANT ROLE
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT pid, usename, state, query FROM pg_stat_activity WHERE usename = 'app';
 pid | usename | state  |        query        
-----+---------+--------+---------------------
 296 | app     | active | SELECT pg_sleep(60)
(1 row)
```

**Sem o papel, o `pg_stat_activity` mostra que uma sessão existe e esconde o que ela está fazendo**:
o número do processo e o usuário estão lá, o estado vem vazio e a consulta diz `<insufficient
privilege>`. Um papel sempre vê as próprias sessões por inteiro e um superusuário vê tudo, e é por
isso que uma ferramenta de monitoramento testada como superusuário e implantada como um papel menor
mostra uma lista de sessões sem consulta nenhuma. Com o `pg_monitor`, o `bruno` viu a consulta.

O `pg_signal_backend` é o direito de fazer algo a respeito. A lição 10 usou o `pg_terminate_backend`
como superusuário; aqui está a mesma chamada de um papel que não é:

```
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename = 'app';
ERROR:  permission denied to terminate process
DETAIL:  Only roles with privileges of the role whose process is being terminated or with privileges of the "pg_signal_backend" role may terminate this process.
shop=# GRANT pg_signal_backend TO bruno;
GRANT ROLE
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename = 'app';
 pg_terminate_backend 
----------------------
 t
(1 row)
shop=# REVOKE pg_monitor, pg_signal_backend FROM bruno;
REVOKE ROLE
```

A primeira recusa cita as duas formas de entrar: ser membro do papel dono da sessão, ou ter o
`pg_signal_backend`. Com o papel, a chamada devolveu `t` e a sessão do `app` foi encerrada. **Ele não
consegue tocar na sessão de um superusuário**, seja o que for que tenha recebido, e é isso que o
torna seguro de entregar a um engenheiro de plantão que não é administrador. Os dois grants foram
revogados no fim, porque o `bruno` é um analista e nenhum desses poderes faz parte do trabalho dele.
