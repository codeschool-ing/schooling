---
title: No que um banco por colunas é ruim
version: 1
---

Toda vantagem desta lição veio de manter cada coluna junta, comprimida, em blocos grandes. A mesma escolha
torna um banco por colunas ruim no trabalho do caixa.

**Gravar uma linha de cada vez.** Uma linha precisa ser dividida nas suas colunas e acrescentada a onze
blocos comprimidos. Duas mil inserções, cada uma seu próprio comando e sua própria transação, no
PostgreSQL e num arquivo DuckDB:

```
ana@lab:~/wh$ seq 1 2000 | awk '{ print "INSERT INTO t VALUES (" $1 ", " $1 * 7 ");" }' > inserts.sql
ana@lab:~/wh$ head -2 inserts.sql
INSERT INTO t VALUES (1, 7);
INSERT INTO t VALUES (2, 14);
ana@lab:~/wh$ psql -q -c 'CREATE TABLE t (a int, b int)'
ana@lab:~/wh$ TIMEFORMAT='%R seconds'; time psql -q -f inserts.sql
0.956 seconds
ana@lab:~/wh$ duckdb small.duckdb -c 'CREATE TABLE t (a int, b int)'
ana@lab:~/wh$ TIMEFORMAT='%R seconds'; time duckdb small.duckdb < inserts.sql
1.981 seconds
```

**0,956 segundo no PostgreSQL, 1,981 no DuckDB**, uma execução cada, e as duas incluindo o tempo de
iniciar o programa. O banco por linhas acrescenta uma linha a uma página. O banco por colunas precisa
registrar de forma durável cada mudança de uma linha, onze colunas por vez, duas mil vezes. Gravadas como
um lote, as mesmas linhas são um acréscimo por coluna em vez de dois mil, e por isso toda carga deste curso
grava tabelas inteiras, nunca linhas soltas.

**Atualizar e apagar linhas.** Um valor num bloco comprimido e codificado não pode ser mudado no lugar sem
reescrever o bloco. Bancos por colunas resolvem marcando linhas como apagadas e gravando versões novas em
outro lugar, e limpando depois. Isso funciona, e é lento para muitas mudanças pequenas.

**Buscar uma linha pela chave.** Os onze valores da linha estão em onze lugares. Com os dados ordenados por
essa chave, os zone maps a encontram rápido:

```
ana@lab:~/wh$ psql -f lookup.sql
Timing is on.
CREATE INDEX
Time: 271.006 ms
 line_no | net_cents 
---------+-----------
       1 |      3290
       2 |      2990
       3 |      6890
(3 rows)

Time: 0.852 ms
ana@lab:~/wh$ duckdb wh.duckdb < duck-lookup.sql
┌─────────┬───────────┐
│ line_no │ net_cents │
│  int64  │   int64   │
├─────────┼───────────┤
│       1 │      3290 │
│       2 │      2990 │
│       3 │      6890 │
└─────────┴───────────┘
Run Time (s): real 0.002 user 0.001994 sys 0.000664
```

O PostgreSQL, com o índice que precisou construir antes, respondeu em 0,852 milissegundo; o DuckDB, sem
índice, em 0,002 segundo. Os dois são rápidos neste tamanho, e o do DuckDB só é rápido porque a
`fact_sales` está ordenada por número de pedido; uma busca por uma coluna pela qual a tabela não está
ordenada teria de varrê-la.

**É por isso que a lição 1 manteve dois bancos.** O banco operacional guarda linhas porque o caixa grava
linhas. O warehouse guarda colunas porque o relatório lê colunas. Os produtos HTAP da lição 1 mantêm as duas
cópias dentro de um produto exatamente por isso. A lição 9 são os bancos por colunas que você aluga em vez
de operar.
