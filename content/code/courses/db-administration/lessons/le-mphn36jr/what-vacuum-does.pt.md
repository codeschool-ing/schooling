---
title: O que o VACUUM faz, e o que não faz
version: 1
---

O nome sugere uma tabela que fica menor. **Um `VACUUM` simples não encolhe o arquivo**, a não ser
pelas páginas vazias bem no fim dele, que a lição 15 mede. O que ele faz são três trabalhos, e
nenhuma outra parte do servidor faz qualquer um deles.

**Ele torna o espaço morto reutilizável.** O VACUUM lê as páginas que mudaram, encontra as versões
que nenhuma transação consegue ver, remove as entradas de índice que apontam para elas e anota o
espaço liberado no **mapa de espaço livre** (free space map) da tabela. O próximo `INSERT` ou
`UPDATE` que precisar de espaço o encontra ali em vez de aumentar o arquivo.

**Ele mantém o mapa de visibilidade.** Um bit por página diz que toda linha da página é visível
para toda transação. Uma página com esse bit ligado pode ser pulada pelo próximo VACUUM, e uma
varredura só de índice pode confiar no índice sem visitar a tabela. Um segundo bit diz que toda
linha da página também está congelada, o que o terceiro trabalho explica.

**Ele congela linhas antigas**, marcando-as como visíveis para todos, para que o `xmin` delas nunca
mais precise ser comparado com nada. A seção sobre wraparound, duas seções adiante, explica por que
isso importa.

`pg_visibility` é outra extensão que vem com o PostgreSQL. Ela conta os dois bits:

```
shop=# CREATE EXTENSION pg_visibility;
CREATE EXTENSION

shop=# UPDATE orders_copy SET total_cents = total_cents + 1 WHERE id <= 50000;
UPDATE 50000

shop=# SELECT pg_size_pretty(pg_relation_size('orders_copy')) AS size, * FROM pg_visibility_map_summary('orders_copy');
 size  | all_visible | all_frozen 
-------+-------------+------------
 68 MB |        7915 |          0
(1 row)

shop=# VACUUM orders_copy;
VACUUM

shop=# SELECT pg_size_pretty(pg_relation_size('orders_copy')) AS size, * FROM pg_visibility_map_summary('orders_copy');
 size  | all_visible | all_frozen 
-------+-------------+------------
 68 MB |        8751 |        415
(1 row)
```

O `UPDATE` tirou 836 páginas do mapa de visibilidade: as páginas de onde ele removeu linhas e as
páginas onde escreveu as versões novas. O VACUUM as devolveu. **O tamanho não mudou**: 68 MB antes
e depois, porque o espaço das 50.000 versões mortas agora é espaço livre dentro do arquivo,
esperando as próximas linhas.

As 415 páginas congeladas são um hábito da versão 16. Quando o VACUUM já está escrevendo uma página
inteira no write-ahead log, ele congela a página enquanto está ali, porque o trabalho extra quase
não custa nada. Todo o resto espera até as linhas ficarem antigas o bastante, ou até alguém pedir:

```
shop=# SELECT relname, relfrozenxid, age(relfrozenxid) FROM pg_class WHERE relname = 'orders_copy';
   relname   | relfrozenxid | age 
-------------+--------------+-----
 orders_copy |          782 |  20
(1 row)

shop=# VACUUM (FREEZE) orders_copy;
VACUUM

shop=# SELECT pg_size_pretty(pg_relation_size('orders_copy')) AS size, * FROM pg_visibility_map_summary('orders_copy');
 size  | all_visible | all_frozen 
-------+-------------+------------
 68 MB |        8751 |       8751
(1 row)

shop=# SELECT relname, relfrozenxid, age(relfrozenxid) FROM pg_class WHERE relname = 'orders_copy';
   relname   | relfrozenxid | age 
-------------+--------------+-----
 orders_copy |          802 |   0
(1 row)
```

**`relfrozenxid` é o id de transação mais antigo que ainda pode aparecer não congelado na
tabela**. Antes do `FREEZE` ele era 782, a transação que carregou a cópia. Depois, toda página está
congelada e o número subiu até o presente, com idade 0. O autovacuum mantém essa idade dentro de
limites sozinho; quanto ela pode se afastar é o assunto da seção sobre wraparound.

**Um VACUUM simples não atrapalha ninguém.** Ele toma uma trava que só conflita com outro VACUUM e
com mudanças na estrutura da tabela, então leituras e escritas continuam enquanto ele roda. O
`VACUUM FULL` é outro comando, que reescreve a tabela sob uma trava exclusiva, e a lição 15 mostra
quanto isso custa. A outra coisa que o `VACUUM ANALYZE` fez quando a cópia foi criada, atualizar as
estatísticas do planejador, pertence ao `ANALYZE`, e a lição 16 é sobre ele.
