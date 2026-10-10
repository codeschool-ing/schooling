---
title: O punhado que vale mexer
version: 1
---

São 364 parâmetros, e a ideia errada de configurar um servidor é percorrer todos, pondo em cada
um algo melhor que o padrão. **Cerca de uma dúzia decide como um servidor se comporta sob trabalho
real; o resto está certo como vem**, ou só importa a alguém com um problema específico, que vai
saber o nome do parâmetro antes de abrir o arquivo. Saber qual é essa dúzia, e quais poucos nunca
se deve tocar, é a maior parte da habilidade.

## Os que vale mexer

| parâmetro | padrão | o que decide | lição |
|---|---|---|---|
| `listen_addresses` | `localhost` | em quais endereços de rede o servidor aceita conexões | esta, abaixo |
| `max_connections` | `100` | quantas sessões ao mesmo tempo, cada uma um processo | 10 |
| `shared_buffers` | `128MB` | o cache próprio do servidor para páginas de tabelas e índices | 6 |
| `work_mem` | `4MB` | memória para um sort ou hash antes de transbordar para o disco | 6 |
| `maintenance_work_mem` | `64MB` | memória para `CREATE INDEX` e `VACUUM` | 6 |
| `effective_cache_size` | `4GB` | quanto cache o planner pode supor que existe; não aloca nada | 6 |
| `max_wal_size` | `1GB` | quanto log de escrita antecipada se acumula antes de forçar um checkpoint | 7, 8 |
| `checkpoint_timeout` | `5min` | o tempo máximo entre checkpoints | 8 |
| `log_min_duration_statement` e as outras configurações `log_` | desligado | o que chega ao log | 19 |
| as configurações `autovacuum_` | ligado, com limiares | quando as linhas mortas são limpas | 14 |
| `shared_preload_libraries` | vazio | extensões carregadas na partida, como o `pg_stat_statements` | 18 |
| `random_page_cost` | `4` | quanto o planner acha que custa uma leitura aleatória; menor em SSD | db-performance |

Quatro deles são parâmetros `postmaster`, e esse é o motivo prático para decidi-los cedo:
`listen_addresses`, `max_connections`, `shared_buffers` e `shared_preload_libraries` precisam de
restart, e toda mudança posterior neles também.

## Os que nunca se afrouxa

Alguns parâmetros trocam segurança por velocidade, e os padrões deles ficam do lado seguro. **O
`fsync = off` faz o servidor parar de garantir que os dados chegaram ao disco**, e uma queda de
energia então corrompe o cluster, não só as últimas transações. O `full_page_writes = off` abre o
mesmo buraco em outro lugar. Os dois aparecem em conselhos na internet sobre deixar o PostgreSQL
mais rápido, e a lição 8 mostra o que cada um protege. O `synchronous_commit` é o da família que
dá para afrouxar sabendo o que se faz, para dados cujo último segundo pode se perder, e a lição 8
mede isso também. O `autovacuum = off` entra na mesma lista por um motivo mais lento: nada quebra
hoje, e as tabelas crescem sem limite até a emergência da lição 14 chegar.

## listen_addresses: a porta antes do pg_hba.conf

O arquivo da seção anterior decide quem pode conectar. **Antes que qualquer parte dele valha, o
servidor precisa estar escutando no endereço que o cliente está chamando**, e por padrão ele
escuta só no loopback da máquina:

```
ana@db:~$ psql
ana=# SHOW listen_addresses;
 listen_addresses 
------------------
 localhost
(1 row)

ana=# \q
ana@db:~$ ss -ltn 'sport = 5432'
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      200        127.0.0.1:5432      0.0.0.0:*          
ana@db:~$ psql -h 127.0.0.2
psql: error: connection to server at "127.0.0.2", port 5432 failed: Connection refused
	Is the server running on that host and accepting TCP/IP connections?
```

O `ss -ltn` lista os sockets escutando TCP, e o filtro deixa só a porta 5432: um, em `127.0.0.1`.
A sua máquina virtual mostra uma segunda linha para `[::1]:5432`, o loopback do IPv6, que a
máquina de gravação não tinha. O `127.0.0.2` faz aqui o papel de um endereço em que o servidor não
está escutando. Ele pertence a esta máquina, então o próprio kernel respondeu `Connection refused`
e o PostgreSQL nem soube da tentativa. Uma aplicação em outro computador recebe a mesma resposta.

`'*'` quer dizer todos os endereços que a máquina tem. É um parâmetro `postmaster`, então precisa
de restart:

```
ana@db:~$ echo "listen_addresses = '*'" | sudo tee /etc/postgresql/16/main/conf.d/60-listen.conf
listen_addresses = '*'
ana@db:~$ sudo systemctl restart postgresql
ana@db:~$ ss -ltn 'sport = 5432'
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      200          0.0.0.0:5432      0.0.0.0:*          
ana@db:~$ psql -h 127.0.0.2
Password for user ana: 
psql: error: connection to server at "127.0.0.2", port 5432 failed: fe_sendauth: no password supplied
```

`0.0.0.0` é todo endereço IPv4. A mesma conexão agora chega ao servidor e vai até a pergunta da
senha, que é a linha 125 do `pg_hba.conf` trabalhando: a conexão saiu desta máquina a partir de
`127.0.0.1`, e **o arquivo compara o endereço de onde o cliente veio, não o que ele chamou**. Numa
rede de verdade os dois são máquinas diferentes e a diferença é óbvia.

Então abrir um servidor para uma aplicação exige **duas mudanças, e esquecer qualquer uma falha
de um jeito diferente**: o `listen_addresses`, ou o cliente recebe `Connection refused`; uma linha
`host` para o endereço do cliente, ou ele recebe `no pg_hba.conf entry`. Um firewall na máquina,
como o `ufw` do Ubuntu, é uma terceira porta com o mesmo sintoma da primeira. Dê nome aos
endereços em que o servidor deve escutar, quando puder, em vez de `'*'`, e abra o firewall só para
as máquinas que precisam.

## De volta a onde a lição 4 deixou você

Tudo que esta lição mudou é desfeito agora, para que a lição 6 comece do mesmo servidor com que
você começou esta. Os dois arquivos do `conf.d` saem, e um restart traz o `shared_buffers` e o
`listen_addresses` de volta:

```
ana@db:~$ sudo rm /etc/postgresql/16/main/conf.d/50-course.conf /etc/postgresql/16/main/conf.d/60-listen.conf
ana@db:~$ sudo systemctl restart postgresql
ana@db:~$ ls -l /etc/postgresql/16/main/conf.d
total 0
ana@db:~$ psql
ana=# SELECT name, setting, unit, source
ana-#   FROM pg_settings
ana-#  WHERE name IN ('shared_buffers', 'work_mem', 'listen_addresses',
ana(#                 'log_min_duration_statement')
ana-#     OR pending_restart;
            name            |  setting  | unit |       source       
----------------------------+-----------+------+--------------------
 listen_addresses           | localhost |      | default
 log_min_duration_statement | -1        | ms   | default
 shared_buffers             | 16384     | 8kB  | configuration file
 work_mem                   | 4096      | kB   | default
(4 rows)

ana=# \q
```

**O `conf.d` está vazio, o `postgresql.auto.conf` só tem seus dois comentários, a linha 125 do
`pg_hba.conf` está como o instalador escreveu, e nada está pendente.** O `shared_buffers` voltou
aos 128 MB do pacote, da linha 130 do arquivo principal, e o resto voltou aos padrões. Se o seu
servidor mostrar outra coisa aqui, a consulta dá o nome do parâmetro, e o `source` diz que camada
ainda o segura.
