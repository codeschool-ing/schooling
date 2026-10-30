---
title: Parâmetros do servidor, e os que pedem um restart
version: 1
---

**Num servidor que você roda, as configurações do PostgreSQL moram no `postgresql.conf`; num flexible
server elas são parâmetros do servidor, definidos pelo Azure.** Os nomes e os valores são os do próprio
PostgreSQL. O que o Azure acrescenta é a porta: você muda um parâmetro pela linha de comando, pelo
portal ou por uma declaração, e o Azure decide quais parâmetros você pode tocar e dentro de que faixa.

O motor já diz quais configurações valem na hora e quais precisam de restart. No contêiner da seção
anterior:

```
ana@laptop:~/azure$ pg -c "SELECT name, setting, unit, context FROM pg_settings WHERE name IN ('max_connections', 'shared_buffers', 'shared_preload_libraries', 'work_mem', 'log_min_duration_statement') ORDER BY context, name"
            name            | setting | unit |  context   
----------------------------+---------+------+------------
 max_connections            | 100     |      | postmaster
 shared_buffers             | 16384   | 8kB  | postmaster
 shared_preload_libraries   |         |      | postmaster
 log_min_duration_statement | -1      | ms   | superuser
 work_mem                   | 4096    | kB   | user
(5 rows)

```

**`context` é a coluna que importa.** `user` quer dizer que qualquer sessão pode mudá-lo para si, como
o `work_mem`. `superuser` quer dizer que um administrador pode mudá-lo com o servidor rodando.
**`postmaster` quer dizer que ele é lido uma vez, quando o servidor inicia**: `max_connections`,
`shared_buffers` e `shared_preload_libraries` não mudam sem restart. A documentação do Azure chama
esses de parâmetros estáticos, e mudar um deles num flexible server o reinicia, o que é uma pequena
interrupção que você agenda, não uma chave que você vira.

## Um que precisa de restart, do jeito difícil

**O `pg_stat_statements` é a extensão que responde "quais consultas custam mais"**, a primeira pergunta
depois de um alarme de banco lento, e ele precisa ser carregado quando o servidor inicia:

```
ana@laptop:~/azure$ pg -c "CREATE EXTENSION pg_stat_statements"
CREATE EXTENSION
ana@laptop:~/azure$ pg -c "SELECT count(*) FROM pg_stat_statements"
ERROR:  pg_stat_statements must be loaded via "shared_preload_libraries"
```

**A extensão foi instalada, e a view se recusou a responder** até a biblioteca estar em
`shared_preload_libraries`. No seu próprio servidor você diz isso com `ALTER SYSTEM`, que escreve a
configuração num arquivo que o PostgreSQL lê ao iniciar, e depois reinicia:

```
ana@laptop:~/azure$ pg -c "ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements'"
ALTER SYSTEM
ana@laptop:~/azure$ pg -c "SELECT pg_reload_conf()"
 pg_reload_conf 
----------------
 t
(1 row)

ana@laptop:~/azure$ pg -c "SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'shared_preload_libraries'"
           name           | setting | pending_restart 
--------------------------+---------+-----------------
 shared_preload_libraries |         | t
(1 row)

```

**`pending_restart` é o motor dizendo isso**: o valor está escrito, o `pg_reload_conf()` o releu, e ele
não vale até o servidor iniciar de novo.

```
ana@laptop:~/azure$ docker compose restart postgres 2>&1 | tail -1
 Container azure-postgres-1 Started 
ana@laptop:~/azure$ pg -c "SHOW shared_preload_libraries"
 shared_preload_libraries 
--------------------------
 pg_stat_statements
(1 row)

ana@laptop:~/azure$ for i in 1 2 3; do pg -c "SELECT count(*), sum(total_cents) FROM orders WHERE customer_id = 17" > /dev/null; done
ana@laptop:~/azure$ pg -c "SELECT calls, rows, query FROM pg_stat_statements ORDER BY calls DESC LIMIT 3"
 calls | rows |                                query                                 
-------+------+----------------------------------------------------------------------
     3 |    3 | SELECT count(*), sum(total_cents) FROM orders WHERE customer_id = $1
     1 |    0 | SHOW shared_preload_libraries
(2 rows)

```

**O restart pegou a biblioteca, e a view agora responde.** A consulta do suporte rodou três vezes com o
mesmo cliente e é uma linha só, três chamadas, porque a view conta comandos pelo texto normalizado, com
`$1` onde estava o 17. Todo comando a partir de agora é contado assim, com as chamadas, as linhas e o
tempo, e `ORDER BY total_exec_time DESC` é a lista que uma pessoa lê primeiro quando o banco está
lento.

## O mesmo parâmetro, no Azure

**Num flexible server, o `ALTER SYSTEM` não está disponível para você**: o administrador não é
superusuário, como a seção anterior disse. A porta documentada é a linha de comando, que fala com o
Azure Resource Manager e não com o motor, e por isso, como todo comando de plano de controle deste
curso, para no login:

```
ana@laptop:~/azure$ az postgres flexible-server parameter set --resource-group rg-quitanda-data-prd --server-name psql-quitanda-orders-prd --name shared_preload_libraries --value pg_stat_statements 2>&1 | tail -1
ERROR: Please run 'az login' to setup account.
```

**Esse comando definiria o parâmetro, e como ele é estático, o Azure precisaria então reiniciar o
servidor** antes de ele valer. E há um segundo portão para qualquer extensão: um parâmetro de servidor
chamado `azure.extensions` lista as extensões que o administrador pode criar, e uma extensão fora dessa
lista é recusada pelo `CREATE EXTENSION`, seja qual for o papel. Nenhum dos dois foi rodado aqui; os
dois estão na documentação.

Como declaração, o parâmetro é um recurso próprio. Salve isto ao lado do `main.tf` da seção anterior,
em `~/azure/tf/flex`:

`params.tf`:

```hcl
resource "azurerm_postgresql_flexible_server_configuration" "preload" {
  name      = "shared_preload_libraries"
  server_id = azurerm_postgresql_flexible_server.orders.id
  value     = "pg_stat_statements"
}
```

```
ana@laptop:~/azure/tf/flex$ terraform validate -no-color
Success! The configuration is valid.

```

**Válido, e calado sobre o restart.** A declaração diz qual deve ser o parâmetro. Se aplicá-lo reinicia um servidor
de produção no meio do dia é um fato que o `validate` não conhece, e é o motivo de uma
mudança num parâmetro estático passar pela mesma revisão que qualquer interrupção.
