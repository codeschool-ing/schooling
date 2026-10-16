---
title: Medir, com exatidão e por estimativa
version: 1
---

Uma tabela grande não é uma tabela inchada, e "esta tabela tem 117 MB" não diz nada sobre quanto
dela está vazio. **Meça antes de decidir qualquer coisa**, e saiba que tipo de medida está lendo,
porque a barata pode errar para os dois lados.

## Exata: pgstattuple

`pgstattuple` é uma extensão que vem com o PostgreSQL. A função de mesmo nome lê cada página de uma
tabela e conta o que há nela:

```
shop=# CREATE EXTENSION pgstattuple;
CREATE EXTENSION

shop=# \timing on
Timing is on.

shop=# SELECT table_len, tuple_count, tuple_percent, dead_tuple_count, free_space, free_percent FROM pgstattuple('orders_copy');
 table_len | tuple_count | tuple_percent | dead_tuple_count | free_space | free_percent 
-----------+-------------+---------------+------------------+------------+--------------
 122880000 |      800000 |         41.67 |                0 |   68026508 |        55.36
(1 row)

Time: 89.991 ms

shop=# SELECT table_len, scanned_percent, approx_tuple_count, approx_free_percent FROM pgstattuple_approx('orders_copy');
 table_len | scanned_percent | approx_tuple_count | approx_free_percent 
-----------+-----------------+--------------------+---------------------
 122880000 |               0 |             902407 |   55.33841145833333
(1 row)

Time: 2.382 ms

shop=# \timing off
Timing is off.
```

**`free_percent` é o bloat**: mais da metade dos 122.880.000 bytes da tabela é espaço livre, e
`tuple_percent` diz que as linhas vivas ocupam 42% dela. `dead_tuple_count` é 0 porque o VACUUM já
passou; numa tabela com versões mortas esperando, essa coluna diz quanto o próximo VACUUM vai
liberar.

A exatidão tem um preço. **O `pgstattuple` lê a tabela inteira**, pelos mesmos shared buffers que a
aplicação usa. Em 117 MB isso levou cerca de um décimo de segundo na máquina da gravação; numa
tabela de 500 GB é uma varredura completa de 500 GB, que pertence a uma hora tranquila.

O `pgstattuple_approx` faz a mesma pergunta ao mapa de visibilidade. Ele pula toda página marcada
como toda visível e estima essas pelo mapa de espaço livre, e é por isso que respondeu em poucos
milissegundos com `scanned_percent` 0. O percentual livre fica perto; a contagem de linhas
não, porque ela vem das estatísticas do planejador, coletadas antes do último `DELETE`. **Uma
estimativa só é tão atual quanto aquilo de que é estimada.**

## Por estimativa: contas sobre as estatísticas

Ferramentas de monitoramento que relatam bloat para todas as tabelas em geral não rodam extensão
nenhuma. Elas pegam as estatísticas do planejador, calculam quantas páginas as linhas deveriam
precisar e comparam com quantas páginas a tabela tem. Uma versão simples dessa consulta:

```
shop=# ANALYZE orders_copy;
ANALYZE

shop=# SELECT c.relname, c.relpages, ceil(c.reltuples * (24 + 4 + sum(s.avg_width)) / (8192 - 24)) AS expected_pages FROM pg_class c JOIN pg_stats s ON s.schemaname = 'public' AND s.tablename = c.relname WHERE c.relname IN ('orders', 'orders_copy') GROUP BY c.relname, c.relpages, c.reltuples;
   relname   | relpages | expected_pages 
-------------+----------+----------------
 orders      |     8334 |           7591
 orders_copy |    15000 |           6073
(2 rows)
```

Cada linha custa um cabeçalho de 24 bytes, um ponteiro de linha de 4 e a largura média de cada
coluna, tirada de `pg_stats`; uma página tem 8.192 bytes, menos 24 do próprio cabeçalho. Para
`orders_copy` a conta diz 6.073 páginas onde há 15.000, o que concorda com o `pgstattuple` sobre
metade da tabela estar sobrando.

**Agora leia a linha de `orders`.** `orders` foi carregada uma vez e nunca atualizada, então não
tem bloat, e a estimativa ainda diz 7.591 páginas contra 8.334: cerca de um décimo da tabela parece
desperdiçado. O décimo que falta é preenchimento que a fórmula não conhece, os bytes que alinham
cada coluna à sua fronteira. Consultas melhores corrigem mais disso, e nenhuma é exata. **Use a
estimativa para escolher quais tabelas olhar, e o `pgstattuple` para decidir.**
