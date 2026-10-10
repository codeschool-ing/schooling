---
title: Dump e restore
version: 1
---

O caminho mais antigo é também o mais simples: escrever o banco como SQL com o servidor antigo
rodando, e carregar no novo. Nada nos arquivos do cluster antigo importa, então funciona entre
quaisquer duas versões, entre duas máquinas e entre dois sistemas operacionais. O custo é **tempo
proporcional aos dados**, e parada do mesmo tamanho: o que for escrito depois que o dump começou não
está nele, então a aplicação para de escrever quando o dump começa e volta a escrever no servidor
novo quando o restore termina.

Esta seção copia o `shop` do `main`, que continua no 16, para o `17/main` vazio que o pacote criou.
Ler do `main` é tudo o que ela faz ali.

## O pg_dump mais novo

**Faça o dump com o `pg_dump` da versão nova, não com o da antiga.** Um `pg_dump` mais novo lê
servidores mais antigos e sabe do que a versão nova precisa; o contrário não é garantido. O wrapper
não escolhe isso por você, porque sem `-p` ele pega a versão do cluster da porta 5432:

```
ana@db:~$ pg_dump --version
pg_dump (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@db:~$ /usr/lib/postgresql/17/bin/pg_dump --version
pg_dump (PostgreSQL) 17.10
```

Então dê o caminho completo. `-Fc` escreve o **formato custom**: comprimido, e legível só pelo
`pg_restore`, que em troca consegue restaurar em paralelo e escolher tabelas avulsas:

```
ana@db:~$ time /usr/lib/postgresql/17/bin/pg_dump -Fc -f shop.dump shop

real	0m3.882s
user	0m1.714s
sys	0m0.081s
ana@db:~$ ls -lh shop.dump
-rw-rw-r-- 1 ana ana 14M Oct 10 16:41 shop.dump
```

Só a tabela `orders` e seus índices ocupam uns 107 MB no `main`, e o dump inteiro tem 14 MB. As
linhas comprimem bem, e os índices nem estão nele: um dump leva o comando `CREATE INDEX`, e o restore
constrói o índice de novo.

## Os papéis primeiro

O `pg_dump` copia um banco, e **papéis pertencem ao cluster, não a um banco**, então um dump do
`shop` não contém a `ana`. O `pg_dumpall --globals-only` escreve só os papéis e os tablespaces:

```
ana@db:~$ sudo -u postgres /usr/lib/postgresql/17/bin/pg_dumpall --globals-only | sudo -u postgres psql -q -p 5434
ERROR:  role "postgres" already exists
```

O mesmo erro esperado do ensaio: o `postgres` já existe.

## O restore

```
ana@db:~$ createdb -p 5434 shop
ana@db:~$ time pg_restore -p 5434 -d shop -j 4 shop.dump

real	0m4.543s
user	0m0.202s
sys	0m0.046s
```

`-j 4` roda quatro tarefas ao mesmo tempo, carregando tabelas e construindo índices lado a lado; só
funciona com os formatos custom e directory, o que é mais um motivo para usar `-Fc`. Num banco real o
restore costuma ser a metade mais longa, porque constrói todos os índices de novo, então o número de
tarefas vale ser ensaiado: até o número de processadores do servidor.

```
ana@db:~$ psql -p 5434 shop
psql (17.10)
Type "help" for help.

shop=# SELECT count(*) FROM orders;
  count  
---------
 1000000
(1 row)

shop=# SELECT pg_size_pretty(pg_table_size('orders')) AS orders, pg_size_pretty(pg_indexes_size('orders')) AS its_indexes;
 orders | its_indexes 
--------+-------------
 66 MB  | 37 MB
(1 row)

shop=# \q
ana@db:~$ psql -c "SELECT pg_size_pretty(pg_table_size('orders')) AS orders, pg_size_pretty(pg_indexes_size('orders')) AS its_indexes;" shop
 orders | its_indexes 
--------+-------------
 65 MB  | 42 MB
(1 row)
```

O milhão de linhas chegou. A tabela tem o mesmo tamanho, com diferença de um megabyte, e **os índices
estão menores**, 37 MB contra 42 MB no `main`. O `shop.sql` criou os índices antes de carregar as
linhas, então cada um cresceu divisão de página por divisão de página à medida que as linhas
chegavam; o restore construiu cada índice numa passada só, sobre dados prontos, bem compactado. Um
banco que viveu anos carrega mais do que isso — o espaço morto que updates e deletes deixam para trás,
que a lição 15 mediu — e nada disso sobrevive a um dump. É um dos motivos para escolherem este método
quando poderiam ter usado o `pg_upgrade`.

## Quando dump e restore é a escolha certa

- O banco é pequeno o bastante para a parada ser aceitável — dezenas de gigabytes e não terabytes,
  dependendo do hardware e de quanto tempo o negócio pode ficar sem escrever.
- Outra coisa muda ao mesmo tempo: uma máquina nova, outra arquitetura de processador, outro encoding
  ou locale para o cluster. O `pg_upgrade` precisa dos dois clusters numa máquina só, com
  configurações compatíveis; para um dump tanto faz.
- O servidor antigo precisa ficar exatamente como estava, legível, como caminho de volta.

O `pg_upgradecluster` sem `-m upgrade` roda este mesmo método para cada banco do cluster, papéis
incluídos, com as ferramentas da versão nova. **É a forma prática de dump e restore no Ubuntu**
quando o cluster continua na mesma máquina.
