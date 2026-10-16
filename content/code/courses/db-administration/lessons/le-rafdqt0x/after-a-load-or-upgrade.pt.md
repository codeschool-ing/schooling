---
title: Depois de um restore ou de um upgrade, não há resumo nenhum
version: 1
---

O resumo velho das seções anteriores ao menos descrevia a tabela como ela era. **Um banco
restaurado de um dump não tem resumo nenhum**, porque o `pg_dump` copia o esquema e as linhas e não
copia o `pg_statistic`. As tabelas estão cheias e o planejador não sabe nada sobre o que há nelas.

Um dump e um restore num segundo banco, para ver. Backups são o assunto de `db-reliability` a partir
da lição 1; os três primeiros comandos aqui só fazem uma cópia:

```
ana@db:~$ pg_dump -Fc -f shop.dump shop
ana@db:~$ createdb shop_restore
ana@db:~$ pg_restore -d shop_restore shop.dump
ana@db:~$ psql shop_restore -c "SELECT count(*) FROM pg_stats WHERE schemaname = 'public';"
 count 
-------
     0
(1 row)

ana@db:~$ psql shop_restore -c "EXPLAIN SELECT * FROM orders WHERE status = 'cancelled';"
                                 QUERY PLAN                                  
-----------------------------------------------------------------------------
 Gather  (cost=1000.00..15100.33 rows=5000 width=60)
   Workers Planned: 2
   ->  Parallel Seq Scan on orders  (cost=0.00..13600.33 rows=2083 width=60)
         Filter: (status = 'cancelled'::text)
(4 rows)
```

Nenhuma linha na `pg_stats` para nenhuma coluna de nenhuma tabela. `rows=5000` não é estimativa de
coisa alguma: sem estatísticas, o planejador supõe que uma igualdade casa com meio por cento da
tabela, seja qual for a tabela e seja qual for o valor. Aqui ele erra por um fator de quarenta, e em
outra consulta erraria para o outro lado.

O autovacuum chegaria a essas tabelas uma hora, já que toda linha restaurada conta como mudança.
Num banco de cem tabelas ele chega a elas uma de cada vez, enquanto a aplicação já está mandando
consultas planejadas sobre meio por cento.

## Em etapas, para os primeiros planos prestarem mais cedo

```
ana@db:~$ vacuumdb --analyze-in-stages -d shop_restore
vacuumdb: processing database "shop_restore": Generating minimal optimizer statistics (1 target)
vacuumdb: processing database "shop_restore": Generating medium optimizer statistics (10 targets)
vacuumdb: processing database "shop_restore": Generating default (full) optimizer statistics
ana@db:~$ psql shop_restore -c "EXPLAIN SELECT * FROM orders WHERE status = 'cancelled';"
                           QUERY PLAN                           
----------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..20892.00 rows=194033 width=34)
   Filter: (status = 'cancelled'::text)
(2 rows)
```

O `vacuumdb` roda `VACUUM` ou `ANALYZE` sobre um banco inteiro a partir do shell, e
`--analyze-in-stages` roda só o `ANALYZE`, três vezes. **A primeira passada usa alvo de
estatísticas 1**, uma amostra de 300 linhas por tabela, e termina quase na hora: as estimativas são
grosseiras, mas são estimativas, e os planos deixam de ser chutes. A segunda usa 10, e a terceira o
alvo normal, depois da qual o mesmo `EXPLAIN` espera 194.033 pedidos cancelados onde há 200.000.
Num banco grande, a primeira passada é a que deixa a aplicação voltar, e o resumo completo chega
atrás dela.

No total ele trabalha mais do que um único `ANALYZE`, já que cada tabela é analisada três vezes.
Quando nada está esperando para usar o banco, `vacuumdb --analyze-only` faz uma passada só, e `-j 4`
a espalha por quatro conexões.

A cópia restaurada não é mais necessária:

```
ana@db:~$ dropdb shop_restore
ana@db:~$ rm shop.dump
```

## Os momentos que pedem isso

**Depois de um upgrade de versão maior com `pg_upgrade`**, que leva os arquivos de dados e, até o
PostgreSQL 17, deixa as estatísticas para trás. O `pg_upgrade` imprime o comando do `vacuumdb` no fim
da execução, e ele é a primeira coisa a fazer quando o servidor novo sobe. O PostgreSQL 18 leva a
maior parte delas; a lição 20 faz o upgrade de 16 para 17, em que isso ainda é trabalho seu.

**Depois de um restore**, como acima, e depois de carregar um banco com uma ferramenta de migração
como a que a lição 21 usa.

**Depois de criar um índice sobre uma expressão**, como `lower(email)`. O planejador guarda
estatísticas da expressão como se ela fosse uma coluna, e quem as coleta é o próximo `ANALYZE` da
tabela, não o `CREATE INDEX`.

**Depois de qualquer mudança em massa numa tabela**, que é o caso das seções anteriores: um
`ANALYZE` dessa tabela, pelo job que fez a mudança.

Um upgrade de versão menor, de 16.2 para 16.15 como na lição 20, não mexe em nada disso. Ele troca os
programas e mantém o diretório de dados, `pg_statistic` incluído.
