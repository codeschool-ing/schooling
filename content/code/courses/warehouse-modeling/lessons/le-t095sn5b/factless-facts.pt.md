---
title: Uma tabela fato sem fatos
version: 1
---

A Ponto Final faz eventos com autores aos sábados. Os clientes vêm; ninguém paga. O processo de
negócio é **comparecer a um evento**, a granularidade é uma linha por cliente por evento, e quando o
passo 4 pede as medidas, não há nenhuma. Nada foi medido; algo *aconteceu*.

Mesmo assim ganha uma tabela fato:

```sql
-- Grain: one row per customer at an author's event. There is no measure:
-- the row is the fact.
CREATE TABLE fact_event_attendance AS
SELECT d.date_key, s.shop_key, e.author_id, ea.customer_id
FROM staging.event_attendance ea
JOIN staging.events e USING (event_id)
JOIN dim_date d ON d.date = e.held_on
JOIN dim_shop s ON s.shop_id = e.shop_id;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < fact_attendance.sql
```

Isto é uma **tabela fato sem fatos** (factless): chaves e mais nada. A linha é o fato. Contar linhas
responde às perguntas:

```sql
SELECT s.shop_name,
       count(DISTINCT f.date_key)    AS events,
       count(*)                      AS attendances,
       count(DISTINCT f.customer_id) AS people
FROM fact_event_attendance f JOIN dim_shop s USING (shop_key)
GROUP BY ALL ORDER BY attendances DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < events.sql
┌───────────┬────────┬─────────────┬────────┐
│ shop_name │ events │ attendances │ people │
│  varchar  │ int64  │    int64    │ int64  │
├───────────┼────────┼─────────────┼────────┤
│ Cambuí    │     26 │         685 │    675 │
│ Savassi   │     24 │         646 │    613 │
│ Paulista  │     22 │         537 │    534 │
│ Pinheiros │     20 │         449 │    443 │
│ Batel     │     20 │         392 │    377 │
│ Moinhos   │      8 │         214 │    212 │
└───────────┴────────┴─────────────┴────────┘
```

O Cambuí fez mais eventos e atraiu mais gente. A diferença entre `attendances` e `people` são as
visitas repetidas: no Cambuí, 685 presenças vieram de 675 pessoas. Nenhum desses números está
guardado em lugar nenhum; cada um é uma contagem de linhas.

## O outro uso: o que não aconteceu

O segundo tipo de tabela factless de Kimball registra **cobertura**: que coisas estavam *elegíveis*
para algo, tenha acontecido alguma coisa ou não. Que livros estavam em promoção em cada loja em cada
dia, por exemplo. Uma tabela de vendas sozinha não diz que livros promovidos não venderam nada, porque
um livro que não vendeu não tem linha nela. Uma tabela de cobertura tem uma linha para cada livro
promovido, e *cobertura menos vendas* é a lista de livros que a promoção não moveu.

As promoções da Ponto Final valem para departamentos inteiros, então a Ana consegue chegar a essa
lista a partir de `dim_promotion` e `dim_book` sem uma. **No momento em que uma promoção cobrir uma
lista de títulos escolhidos a dedo, a própria lista vira uma tabela fato**, porque não há outro lugar
para anotar que títulos estavam nela.
