---
title: maintenance_work_mem e a criação de um índice
version: 1
---

O `maintenance_work_mem` é o `work_mem` dos trabalhos que não são consultas: **`CREATE INDEX`,
`VACUUM` e a adição de uma chave estrangeira a uma tabela que já tem linhas**. O padrão é 64 MB,
dezesseis vezes o `work_mem`, e ele pode ser maior porque esses trabalhos são poucos. Um servidor
roda centenas de sorts por minuto e um punhado de criações de índice por mês; o autovacuum roda no
máximo `autovacuum_max_workers` vacuums ao mesmo tempo, três por padrão, e cada um toma o
`maintenance_work_mem`, porque o `autovacuum_work_mem` é `-1`.

Criar um índice é um sort: a chave de cada linha, em ordem, escrita como o índice. Então a
pergunta interessante é a mesma da seção anterior: o sort cabe?

## Uma criação, duas cotas

Crie um índice em `orders (total_cents)` com quase nada, depois com o padrão, e apague-o a cada
vez. Três configurações deixam o resultado fácil de ver. O `\timing on` faz o `psql` imprimir
quanto cada comando levou. O `max_parallel_maintenance_workers = 0` mantém a criação num processo
só, quando o servidor a dividiria entre dois ajudantes e repartiria a memória entre eles. O
`log_temp_files = 0` com `client_min_messages = log` faz o servidor contar a esta sessão cada
arquivo temporário que escreve, uma ferramenta de superusuário que a lição 19 põe no log de vez.

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# SET max_parallel_maintenance_workers = 0;
SET
Time: 0.473 ms

shop=# SET log_temp_files = 0;
SET
Time: 0.212 ms

shop=# SET client_min_messages = log;
SET
Time: 0.290 ms

shop=# SET maintenance_work_mem = '1MB';
SET
Time: 0.307 ms

shop=# CREATE INDEX orders_total_cents ON orders (total_cents);
LOG:  temporary file: path "base/pgsql_tmp/pgsql_tmp299.0", size 20070400
CREATE INDEX
Time: 402.848 ms

shop=# DROP INDEX orders_total_cents;
DROP INDEX
Time: 9.973 ms

shop=# RESET maintenance_work_mem;
RESET
Time: 0.284 ms

shop=# SHOW maintenance_work_mem;
 maintenance_work_mem 
----------------------
 64MB
(1 row)

Time: 0.273 ms

shop=# CREATE INDEX orders_total_cents ON orders (total_cents);
CREATE INDEX
Time: 409.138 ms

shop=# DROP INDEX orders_total_cents;
DROP INDEX
Time: 8.460 ms

shop=# \q
```

Com 1 MB, o menor valor que o servidor aceita, **o sort transbordou: um arquivo temporário de
20070400 bytes**, cerca de 19 MB, em `base/pgsql_tmp`, dentro do diretório de dados que você
conheceu na lição 4. Com os 64 MB padrão não houve arquivo nenhum, então o milhão de chaves coube
na memória. O servidor apaga o arquivo temporário assim que a operação termina, e é por isso que a
linha do log é o único vestígio dele.

As duas criações levaram cerca de meio segundo na máquina de gravação, e os dois tempos ficaram
próximos. É o mesmo resultado do sort da seção anterior, pelo mesmo motivo: 19 MB gravados e lidos
de volta nunca saíram do cache de páginas de uma máquina com 15 GB. **Transbordar é barato
enquanto os arquivos ficam na memória, e lento quando precisam chegar a um disco.** Numa tabela
dez ou cem vezes maior que a `orders`, numa máquina virtual de 4 GB, o transbordo não cabe mais no
cache, e cada byte dele é gravado no disco e lido de volta.

## Como usar

- **Aumente para uma criação, na sessão que a roda.** Um `SET maintenance_work_mem = '1GB';` antes
  de um `CREATE INDEX` grande, e nada mais no servidor percebe. O padrão serve para as tabelas do
  `shop`, como a segunda criação mostrou.
- **Lembre dos workers.** Uma criação paralela divide o `maintenance_work_mem` entre os seus
  processos, e o servidor planeja menos workers que o `max_parallel_maintenance_workers` quando a
  parte de cada um seria pequena demais para valer a pena.
- **Conte o autovacuum.** Três workers, cada um com `maintenance_work_mem`, podem estar rodando
  enquanto alguém cria um índice: quatro cotas ao mesmo tempo. Para o vacuum, o PostgreSQL 16 usa
  no máximo 1 GB dele, diga a configuração o que disser, então um valor maior só ajuda a criação
  de índices.

O `VACUUM` e os seus workers são a lição 14. O que importa aqui é que a memória que eles usam é
este parâmetro, multiplicado por três num servidor comum.
