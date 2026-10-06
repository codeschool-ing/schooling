---
title: Dicionários e sequências
version: 1
---

Veja o que cada coluna da `fact_sales` guarda:

```sql
-- A column with few distinct values, and one with many.
SELECT count(DISTINCT shop_key) AS shops, count(DISTINCT order_id) AS orders,
       count(*) AS rows
FROM fact_sales;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < dictionary.sql
┌───────┬────────┬────────┐
│ shops │ orders │  rows  │
│ int64 │ int64  │ int64  │
├───────┼────────┼────────┤
│     7 │ 572439 │ 887477 │
└───────┴────────┴────────┘
```

887.477 linhas, e `shop_key` tem sete valores diferentes em todas elas. Uma coluna assim gasta a maior
parte dos seus bytes dizendo as mesmas poucas coisas de novo e de novo, e duas codificações aproveitam isso.

**Codificação por dicionário.** Escreva os valores distintos uma vez, num dicionário, e troque cada valor
da coluna pela sua posição no dicionário. Sete lojas precisam das posições 0 a 6, que cabem em três bits,
então cada linha da coluna custa três bits em vez de oito bytes. O Parquet usa um dicionário em quase toda
coluna por padrão, e as codificações que escolheu estão nos seus metadados como `PLAIN_DICTIONARY`.

**Codificação por sequência** (run-length encoding, RLE). Onde o mesmo valor se repete em linhas
consecutivas, escreva-o uma vez com o número de vezes que se repete, em vez de cada cópia. Só funciona
quando valores iguais ficam juntos, o que depende da ordem das linhas.

O DuckDB escolheu uma codificação para cada coluna da sua cópia, um segmento de cada vez:

```sql
-- How DuckDB compressed each column of its own fact_sales.
SELECT column_name, compression, count(*) AS segments
FROM pragma_storage_info('fact_sales')
WHERE segment_type <> 'VALIDITY'
GROUP BY ALL
ORDER BY column_name, segments DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < compression.sql
┌────────────────┬─────────────┬──────────┐
│  column_name   │ compression │ segments │
│    varchar     │   varchar   │  int64   │
├────────────────┼─────────────┼──────────┤
│ book_key       │ BitPacking  │        8 │
│ customer_key   │ BitPacking  │        8 │
│ date_key       │ RLE         │        8 │
│ discount_cents │ BitPacking  │        4 │
│ discount_cents │ RLE         │        4 │
│ gross_cents    │ BitPacking  │        8 │
│ line_no        │ BitPacking  │        8 │
│ net_cents      │ BitPacking  │        8 │
│ order_id       │ BitPacking  │        8 │
│ promotion_key  │ BitPacking  │        7 │
│ promotion_key  │ RLE         │        1 │
│ quantity       │ BitPacking  │        8 │
│ shop_key       │ BitPacking  │        8 │
└────────────────┴─────────────┴──────────┘
  13 rows                       3 columns
```

**`date_key` é RLE em todos os segmentos.** A tabela foi carregada em ordem de número de pedido, os
números de pedido sobem com o tempo, e assim as vendas de cada dia ficam juntas numa sequência.
`discount_cents` é RLE em metade dos segmentos, porque a maioria dos itens não tem desconto e os zeros vêm
em sequência; a outra metade, onde havia promoções, é empacotada em bits. Toda outra coluna é **empacotada
em bits** (bit-packing), que é a próxima seção.

O DuckDB faz a escolha por segmento, testando as codificações e ficando com a menor. Ninguém declarou nada
disso, e isso é típico dos motores colunares: as codificações são um detalhe de implementação que o leitor
nunca precisa nomear, e se adaptam aos dados.
