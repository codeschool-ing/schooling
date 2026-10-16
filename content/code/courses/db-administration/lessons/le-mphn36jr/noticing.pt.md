---
title: Perceber, e ajustar uma tabela
version: 1
---

O autovacuum trabalha em silêncio, e no PostgreSQL 16 também relata em silêncio. Três lugares
dizem o que ele fez, e **o primeiro é uma consulta que vale guardar**:

```
shop=# SELECT relname, n_live_tup, n_dead_tup, last_vacuum, last_autovacuum FROM pg_stat_user_tables ORDER BY n_dead_tup DESC;
   relname   | n_live_tup | n_dead_tup |          last_vacuum          |        last_autovacuum        
-------------+------------+------------+-------------------------------+-------------------------------
 customers   |      50000 |          0 |                               | 2026-10-10 16:49:15.095607-03
 orders_copy |    1000000 |          0 | 2026-10-10 16:51:25.061368-03 | 2026-10-10 16:51:15.411023-03
 orders      |    1000000 |          0 |                               | 2026-10-10 16:49:15.367302-03
(3 rows)
```

Uma tabela perto do topo com um `n_dead_tup` grande e um `last_autovacuum` antigo ou vazio é uma
que o autovacuum não alcançou ou não consegue limpar. As seções anteriores dão os dois motivos de
costume: a linha dela é alta demais para o tamanho que tem, ou alguma coisa segura o horizonte.
`orders_copy` também tem um `last_vacuum`, do `VACUUM` digitado à mão na seção sobre a transação
aberta; as colunas `auto` são as que dizem se o servidor está dando conta sozinho.

**O segundo é o log**, e por padrão ele quase não diz nada:

```
shop=# SHOW log_autovacuum_min_duration;
 log_autovacuum_min_duration 
-----------------------------
 10min
(1 row)
```

Só entra no log um autovacuum que leve dez minutos ou mais. Isso pega a execução que importa numa
tabela grande e nenhuma das que mostrariam o ritmo dela. A lição 19 configura o log do servidor
inteiro. Aqui o parâmetro vai numa tabela só, junto com a correção que a seção sobre o gatilho
prometeu para tabelas grandes: uma fração de 1% em vez de 20%.

```
shop=# ALTER TABLE orders_copy SET (autovacuum_vacuum_scale_factor = 0.01, log_autovacuum_min_duration = 0);
ALTER TABLE

shop=# SELECT relname, reloptions FROM pg_class WHERE relname = 'orders_copy';
   relname   |                             reloptions                              
-------------+---------------------------------------------------------------------
 orders_copy | {autovacuum_vacuum_scale_factor=0.01,log_autovacuum_min_duration=0}
(1 row)

shop=# UPDATE orders_copy SET total_cents = total_cents + 1 WHERE id <= 20000;
UPDATE 20000
```

`reloptions` é onde moram os parâmetros por tabela, e `\d+ orders_copy` também os mostra, em
`Options:`. A linha desta tabela agora é 50 mais 1% de um milhão, 10.050 versões mortas, então
20.000 passa dela. Na rodada seguinte do lançador:

```
ana@db:~$ sudo grep -A10 'automatic vacuum of table "shop.public.orders_copy"' /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:53:15.133 -03 [1016] LOG:  automatic vacuum of table "shop.public.orders_copy": index scans: 0
	pages: 0 removed, 10417 remain, 338 scanned (3.24% of total)
	tuples: 20000 removed, 987756 remain, 0 are dead but not yet removable
	removable cutoff: 809, which was 0 XIDs old when operation ended
	frozen: 0 pages from table (0.00% of total) had 0 tuples frozen
	index scan bypassed: 167 pages from table (1.60% of total) have 19957 dead item identifiers
	avg read rate: 0.000 MB/s, avg write rate: 0.000 MB/s
	buffer usage: 557 hits, 0 misses, 0 dirtied
	WAL usage: 342 records, 0 full page images, 59812 bytes
	system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
```

Cada linha é uma que você viu no `VACUUM VERBOSE`, escrita pelo worker no log do servidor com um
horário. **`20000 removed` e `0 are dead but not yet removable` é o formato saudável.** `index scan
bypassed` é uma economia que chegou na versão 14: quando menos de 2% das páginas da tabela têm
entradas mortas, o worker deixa os índices para uma passada futura em vez de ler todos eles por tão
pouco.

O terceiro lugar é o `pg_stat_progress_vacuum`, que tem uma linha para cada VACUUM rodando naquele
momento, com a fase em que está e quantas páginas já leu. É a view para abrir quando alguma coisa
está no vacuum há uma hora e você quer saber se falta pouco.

**Parâmetros por tabela são como o autovacuum é ajustado na prática.** Os padrões do servidor
servem para a maioria das tabelas; as poucas grandes e movimentadas ganham fração ou limiar
próprios. Nunca responda a um problema com `autovacuum_enabled = false` numa tabela. Isso acaba com
as visitas comuns e deixa só a agressiva, a da seção sobre wraparound, que chega mais tarde e
maior.

## Devolvendo o shop

A cópia e as duas extensões eram para esta lição. Os dois parâmetros dela, o do log incluído,
moram na tabela e vão embora com ela. Remova-as, e o `shop` fica como a lição 4 o deixou:

```
shop=# DROP TABLE orders_copy;
DROP TABLE

shop=# DROP EXTENSION pageinspect;
DROP EXTENSION

shop=# DROP EXTENSION pg_visibility;
DROP EXTENSION
```
