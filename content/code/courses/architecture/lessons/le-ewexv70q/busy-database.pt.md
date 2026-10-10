---
title: O banco ocupado
version: 1
---

A página inicial mostra os cinco mais vendidos dos últimos trinta dias. A consulta está certa e leva um ou
dois milissegundos. O problema está em como ela é usada: **todo visitante a roda**, e a resposta é a mesma
para todos. Cem visitantes:

```
ana@vm:~/lab/perf$ docker compose exec -T db psql -U postgres -c 'SELECT pg_stat_statements_reset()'
   pg_stat_statements_reset    
-------------------------------
 2026-10-10 19:31:23.696846+00
(1 row)

ana@vm:~/lab/perf$ $P front-page
front-page: 100 queries, 500 rows, 1,900 bytes, 484 ms
ana@vm:~/lab/perf$ docker compose exec -T db psql -U postgres -c 'SELECT calls, round(total_exec_time) AS total_ms, rows, left(query, 50) AS query FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 3'
 calls | total_ms | rows |                       query                        
-------+----------+------+----------------------------------------------------
   100 |      153 |  500 | SELECT i.product_id, sum(i.units) FROM items i JOI
     1 |        1 |    1 | SELECT pg_stat_statements_reset()
(2 rows)
```

O `pg_stat_statements` é a ferramenta para ver isso do lado do banco: para cada consulta distinta, com que
frequência rodou e quanto tempo levou no total. A consulta dos mais vendidos rodou cem vezes e usou 153
milissegundos do tempo do banco, para calcular as mesmas cinco linhas cem vezes. Agora os mesmos cem
visitantes, com a resposta guardada por um minuto:

```
ana@vm:~/lab/perf$ $P front-page --cached
front-page: 1 queries, 5 rows, 19 bytes, 9 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Cem visitantes abrem a página inicial. Sem cache, toda visita manda a consulta dos mais vendidos ao banco: cem consultas. Com um cache guardado por um minuto, a primeira visita pergunta ao banco e as outras noventa e nove são respondidas pelo cache: uma consulta.\"><defs><marker id=\"l16-busy-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l16-busy-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">sem cache: 100 consultas</text><rect x=\"40\" y=\"60\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">100 visitas</text><rect x=\"210\" y=\"150\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">banco</text><path d=\"M110 102 L230 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M118 102 L248 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M126 102 L266 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M134 102 L284 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M142 102 L302 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l16-busy-ah-amber)\"></path><text x=\"535\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">com cache: 1 consulta</text><rect x=\"400\" y=\"60\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">100 visitas</text><rect x=\"560\" y=\"60\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">cache, 1 min</text><path d=\"M522 80 L558 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16-busy-ah-phosphor)\"></path><rect x=\"560\" y=\"150\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">banco</text><path d=\"M620 102 L620 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16-busy-ah-phosphor)\"></path><text x=\"632\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">uma vez</text></svg>", "caption": "O banco ocupado responde a mesma pergunta para cada visitante. Um cache, ou um modelo de leitura, a pergunta uma vez.", "same": ["cache, 1 min"]}
```

**Uma consulta em vez de cem.** Os mais vendidos dos últimos trinta dias não mudam em um minuto de nenhum
jeito que um visitante perceberia, então um cache com até um minuto de idade não custa precisão e tira 99%
da carga dessa consulta. Onde a resposta precisa ser mais fresca, o modelo de leitura da aula 13 é a mesma
ideia mantida em dia por eventos em vez de por um temporizador.

O banco costuma ser a parte mais difícil de escalar de um sistema, como a aula 10 mostrou: um primário
recebe as escritas, e acrescentar capacidade é uma máquina maior ou um projeto de sharding. Então trabalho
que não precisa acontecer lá não deveria. O antipadrão do **banco ocupado** cobre a família inteira:

- **A mesma pergunta para toda requisição**, como acima. Ponha em cache, ou mantenha um modelo de leitura.
- **Lógica que pertence à aplicação**, feita em SQL por conveniência: formatar texto, montar JSON ou XML,
  cálculos complexos em stored procedures. A CPU do banco é a CPU mais escassa do sistema.
- **Consultas que leem muito mais do que devolvem**, em geral por falta de um índice. A página de
  histórico procura itens por `order_id`, e não há índice nele:

```
ana@vm:~/lab/perf$ docker compose exec -T db psql -U postgres -c 'EXPLAIN ANALYZE SELECT product_id, units FROM items WHERE order_id = 42'
                                            QUERY PLAN                                            
--------------------------------------------------------------------------------------------------
 Seq Scan on items  (cost=0.00..156.20 rows=45 width=8) (actual time=0.030..0.861 rows=4 loops=1)
   Filter: (order_id = 42)
   Rows Removed by Filter: 7996
 Planning Time: 0.308 ms
 Execution Time: 0.897 ms
(5 rows)

ana@vm:~/lab/perf$ docker compose exec -T db psql -U postgres -c 'CREATE INDEX ON items (order_id)' -c 'EXPLAIN ANALYZE SELECT product_id, units FROM items WHERE order_id = 42'
CREATE INDEX
                                                         QUERY PLAN                                                         
----------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on items  (cost=4.59..50.08 rows=40 width=8) (actual time=0.034..0.036 rows=4 loops=1)
   Recheck Cond: (order_id = 42)
   Heap Blocks: exact=1
   ->  Bitmap Index Scan on items_order_id_idx  (cost=0.00..4.58 rows=40 width=0) (actual time=0.026..0.026 rows=4 loops=1)
         Index Cond: (order_id = 42)
 Planning Time: 0.363 ms
 Execution Time: 0.067 ms
(7 rows)
```

Sem o índice, o PostgreSQL leu todos os 8.000 itens para achar 4 (`Rows Removed by Filter: 7996`). Com
ele, foi direto a eles, e o tempo de execução caiu de 0,9 milissegundo para 0,07. Com 8.000 linhas
ninguém percebe; com 80 milhões o primeiro plano é uma página que dá timeout. Um `EXPLAIN ANALYZE` nas
consultas que o `pg_stat_statements` põe no topo é a primeira hora de costume olhando um banco ocupado.
