---
title: A conta, em duas máquinas
version: 1
---

Dimensionar memória não é procurar o melhor valor de cada parâmetro. É **um orçamento: a memória
da máquina dividida entre o cache compartilhado, o trabalho privado dos processos e o sistema
operacional**, com a parte privada dimensionada pelo pior momento e não pelo momento médio. O
método leva cinco minutos e cabe num cartão, e o resultado para a sua máquina virtual é diferente
do resultado para o computador de onde vieram estas transcrições.

## O que o servidor não confere

Um dos parâmetros é pura crença, e o servidor acredita em qualquer coisa:

```
ana@db:~$ psql shop
shop=# SET effective_cache_size = '1TB';
SET

shop=# SHOW effective_cache_size;
 effective_cache_size 
----------------------
 1TB
(1 row)

shop=# RESET effective_cache_size;
RESET

shop=# SELECT name, setting FROM pg_settings
shop-#  WHERE name IN ('max_connections', 'autovacuum_max_workers',
shop(#                 'max_parallel_workers_per_gather');
              name               | setting 
---------------------------------+---------
 autovacuum_max_workers          | 3
 max_connections                 | 100
 max_parallel_workers_per_gather | 2
(3 rows)

shop=# \q
```

Um terabyte, numa máquina de 15 GB, aceito sem uma palavra. **O `effective_cache_size` não aloca
nada**; é a estimativa do planner de quanto dos dados deve estar na memória, no `shared_buffers` e
no cache de páginas juntos, e ele faz varreduras de índice parecerem mais baratas quando é grande.
Ponha nele o que é verdade, cerca de três quartos da máquina num servidor dedicado, e nada é
gasto.

Os outros três são os multiplicadores do orçamento. O `max_connections` é quantos processos podem
estar rodando um sort cada ao mesmo tempo. O `autovacuum_max_workers` é quantos vacuums podem
segurar um `maintenance_work_mem` cada. O `max_parallel_workers_per_gather` é quantos ajudantes uma
consulta pode acrescentar, cada um com o seu `work_mem` por passo, e numa máquina virtual com 2
processadores, dois ajudantes e o processo que os iniciou já são mais processos que processadores.

## O orçamento, calculado para as duas máquinas

Quatro fatias, nesta ordem:

1. **O `shared_buffers`, um quarto da memória.** A seção sobre ele diz por que não mais.
2. **O sistema operacional e os processos do próprio servidor**, meio gigabyte na máquina pequena
   e um gigabyte na grande: o kernel, o systemd, o postmaster e os seus workers, o processo de cada
   conexão antes de ordenar qualquer coisa.
3. **Cache de páginas a manter**, um quarto de novo. Foi ele que deixou barata cada `read` desta
   lição, e um orçamento que o gasta em `work_mem` torna as faltas de cache reais.
4. **O que sobra é para sorts e hashes**, e o `work_mem` é isso dividido pelo número de operações
   que podem rodar ao mesmo tempo: `max_connections` vezes dois, como palpite de trabalho de que
   uma consulta típica tem um ou dois passos famintos de memória.

| | a máquina virtual recomendada | a máquina de gravação |
|---|---|---|
| memória | 4 GB = 4096 MB | 15 GB = 15360 MB |
| `shared_buffers`, um quarto | 1024 MB | 3840 MB |
| sistema operacional e processos | 512 MB | 1024 MB |
| cache de páginas a manter, um quarto | 1024 MB | 3840 MB |
| sobra para sorts e hashes | 1536 MB | 6656 MB |
| dividido por 100 conexões × 2 | 7,7 MB | 33,3 MB |
| **`work_mem`, arredondado** | **8MB** | **32MB** |
| `maintenance_work_mem`, quatro de uma vez | 128MB, 512 MB no máximo | 512MB, 2 GB no máximo |
| `effective_cache_size`, três quartos | 3GB | 11GB |

A linha do `maintenance_work_mem` é a mesma ideia para a manutenção: três workers do autovacuum e
uma criação de índice, quatro cotas que podem coincidir, mantidas dentro da fatia de sorts e
hashes.

Como arquivos no `conf.d`, os dois resultados são estes. Cada um é o orçamento acima e nada mais:

```ini
# /etc/postgresql/16/main/conf.d/10-memory.conf, for 4 GB of memory
shared_buffers = 1GB
work_mem = 8MB
maintenance_work_mem = 128MB
effective_cache_size = 3GB
```

```ini
# /etc/postgresql/16/main/conf.d/10-memory.conf, for 15 GB of memory
shared_buffers = 3840MB
work_mem = 32MB
maintenance_work_mem = 512MB
effective_cache_size = 11GB
```

## O pior caso

O orçamento supõe dois sorts por conexão. Nada garante isso. Pegue um relatório comum: dois hash
joins e um sort, planejado em paralelo com os dois ajudantes padrão. Cada um dos três processos
pode usar o `work_mem` em dobro para cada hash e uma vez para o sort:

> 3 processos × (2 hashes × 2 + 1 sort) = **15 × `work_mem`**

Com 8 MB isso dá 120 MB para uma consulta, folgado dentro dos 1536 MB da máquina virtual. Agora
deixe vinte pessoas abrirem esse relatório no mesmo momento, que é o que um painel faz numa
segunda de manhã: 2400 MB, mais que a fatia inteira, tirados primeiro do cache de páginas e depois
de lugar nenhum. **O `work_mem` é um teto por passo, nunca um limite do total**, e o total é
decidido por quantas conexões estão ocupadas ao mesmo tempo.

Quando a máquina fica sem memória de verdade, o OOM killer do Linux escolhe um processo e o mata,
em geral o que usa mais memória: aqui, um dos vinte rodando o relatório. O postmaster não tem como
saber em que estado um processo morto deixou a memória compartilhada, então **encerra todas as
conexões e reinicia o servidor** por segurança. Um relatório descontrolado vira uma queda para
todo mundo. A documentação do PostgreSQL recomenda pôr o `vm.overcommit_memory` do kernel em 2
num servidor dedicado, para que uma alocação que não pode ser atendida falhe dentro da consulta
que pediu, e a lição 9 volta às configurações do kernel junto com o disco.

As defesas que funcionam ficam fora dos parâmetros de memória. Uma é **menos conexões ocupadas**,
que é a lição 10 e um pool de conexões. A outra é um `work_mem` maior dado com `ALTER ROLE … SET`
aos papéis que precisam, em vez de a todo mundo.

## Pondo de volta

A lição 7 começa do mesmo servidor de que esta lição começou. Apague a extensão e remova o
arquivo:

```
ana@db:~$ psql shop
shop=# DROP EXTENSION pg_buffercache;
DROP EXTENSION

shop=# \q
ana@db:~$ sudo rm /etc/postgresql/16/main/conf.d/10-memory.conf
ana@db:~$ sudo systemctl restart postgresql
ana@db:~$ psql shop
shop=# SELECT name, setting, unit, source FROM pg_settings
shop-#  WHERE name IN ('shared_buffers', 'work_mem', 'maintenance_work_mem')
shop-#     OR pending_restart;
         name         | setting | unit |       source       
----------------------+---------+------+--------------------
 maintenance_work_mem | 65536   | kB   | default
 shared_buffers       | 16384   | 8kB  | configuration file
 work_mem             | 4096    | kB   | default
(3 rows)

shop=# \dx
                 List of installed extensions
  Name   | Version |   Schema   |         Description          
---------+---------+------------+------------------------------
 plpgsql | 1.0     | pg_catalog | PL/pgSQL procedural language
(1 row)

shop=# \q
```

**De volta a 128 MB de `shared_buffers` e aos padrões, sem nada pendente e sem extensão além da
que todo banco tem.** O `10-memory.conf` acima é o que este servidor teria em produção; o curso
mantém os padrões porque as lições depois desta foram gravadas com eles.
