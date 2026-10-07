---
title: Uma carga que dobra
version: 1
---

Para ver se um passo mudou alguma coisa, a Ana precisa de um jeito de descrever o que ele deixou para
trás que seja curto o bastante para comparar de olho e exato o bastante para não deixar escapar nada.
Contar linhas é curto e deixa escapar quase tudo. Um **md5 de todas as linhas, numa ordem fixa**, não
deixa escapar nada:

```
-- One day of marts.fact_sales reduced to two values: how many lines, and an md5
-- of all of them in a fixed order. Two runs that leave the same day behind give
-- the same two values; any difference at all, in any column, changes the md5.
SELECT count(*) AS lines,
       md5(string_agg(f::text, '|' ORDER BY order_id, line_no)) AS fingerprint
  FROM marts.fact_sales f
 WHERE order_date = :'day';
```

O `f::text` transforma cada linha numa string — todas as colunas, em ordem — e o `string_agg` as junta
na ordem da chave, para que as mesmas linhas sempre deem o mesmo texto e o mesmo md5. Um valor mudado
em qualquer lugar do dia, uma linha a mais, uma linha a menos: cada um muda a impressão digital.

Depois, a carga ingênua das vendas de um dia. É o `fact_sales.sql` da lição 7 sem a primeira linha, o
`DELETE`:

```
-- marts.fact_sales for one day, the naive way: insert the day's lines.
INSERT INTO marts.fact_sales
SELECT o.order_date, o.order_id, l.line_no,
       coalesce(d.customer_key, -1),
       l.book_id, l.quantity, l.line_cents
  FROM staging.orders o
  JOIN staging.order_lines l USING (order_id)
  LEFT JOIN marts.dim_customer d
         ON d.customer_id = o.customer_id
        AND o.ordered_at >= d.valid_from
        AND (o.ordered_at < d.valid_to OR d.valid_to IS NULL)
 WHERE o.order_date = :'day' AND o.is_sale;
```

```
ana@vm:~/etl$ psql -d wh -v day=2026-03-16 -f fingerprint.sql
 lines |           fingerprint            
-------+----------------------------------
   448 | c5aa6b634e10684f652731525f1e420f
(1 row)

ana@vm:~/etl$ psql -q -d wh -v day=2026-03-16 -f load/fact_sales_append.sql
ana@vm:~/etl$ psql -d wh -v day=2026-03-16 -f fingerprint.sql
 lines |           fingerprint            
-------+----------------------------------
   896 | e55dc68e9fb03305a2e57f55ff7afd0d
(1 row)

ana@vm:~/etl$ psql -q -d wh -v day=2026-03-16 -f load/fact_sales_append.sql
ana@vm:~/etl$ psql -d wh -v day=2026-03-16 -f fingerprint.sql
 lines |           fingerprint            
-------+----------------------------------
  1344 | b34f029d164be35d08621e10bd994952
(1 row)
```

Antes: 448 linhas, carregadas pela carga noturna. Mais uma execução do insert: 896, cada linha duas
vezes. Mais uma: 1.344. Cada execução fez exatamente o que lhe mandaram — inserir as linhas do dia — e
cada uma acrescentou o dia de novo. **Nada falhou, e as vendas do dia 16 agora são o triplo do que a
loja vendeu.** Um relatório somando `line_cents` não teria motivo para duvidar.

Esse é o jeito mais comum de um pipeline dar errado sem erro. Um retry depois de um timeout, uma
tarefa do Airflow limpa para corrigir outra coisa, um backfill sobre um intervalo que se sobrepõe ao da
semana passada: qualquer um deles roda o insert uma segunda vez, e a segunda vez é invisível a menos
que alguém conte.
