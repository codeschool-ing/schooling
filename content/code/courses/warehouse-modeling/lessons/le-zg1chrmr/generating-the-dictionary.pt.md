---
title: Gerando o dicionário
version: 1
---

Com toda descrição dentro do banco, o dicionário em si deixa de ser escrito. Ele é **gerado**, a partir do mesmo
catálogo que o teste lê:

```python
"""Write the field dictionary, in Markdown, from the database's own comments."""
import duckdb

con = duckdb.connect("wh.duckdb", read_only=True)
con.sql("CREATE TEMP TABLE classes AS FROM read_csv('classification.csv')")
tables = con.sql("""
    SELECT table_name, comment FROM duckdb_tables()
    WHERE schema_name = 'main' AND regexp_matches(table_name, '^(dim|fact|bridge)_')
    ORDER BY table_name
""").fetchall()

print("# Ponto Final warehouse: field dictionary\n")
for table, about in tables:
    print(f"## {table}\n\n{about}\n")
    print("| column | type | data | meaning |")
    print("|---|---|---|---|")
    for column, kind, cls, meaning in con.execute("""
        SELECT d.column_name, d.data_type, c.class, d.comment
        FROM duckdb_columns() d JOIN classes c USING (table_name, column_name)
        WHERE d.schema_name = 'main' AND d.table_name = ?
        ORDER BY d.column_index
    """, [table]).fetchall():
        print(f"| {column} | {kind} | {cls} | {meaning} |")
    print()
```

```
ana@lab:~/wh$ python3 dictionary.py > dictionary.md && wc -l dictionary.md
178 dictionary.md
ana@lab:~/wh$ awk '/^## fact_sales/ {p = 1} /^## / && !/fact_sales/ {p = 0} p' dictionary.md
## fact_sales

One row per line of an order that was not cancelled, in a shop or online.

| column | type | data | meaning |
|---|---|---|---|
| date_key | INTEGER | none | Day the order was placed, São Paulo time. Key of dim_date. |
| shop_key | BIGINT | none | Shop the order was placed in; the website is the shop Online. Key of dim_shop. |
| book_key | BIGINT | none | Book sold on this line. Key of dim_book. |
| customer_key | BIGINT | pseudonymous | Customer as they were when ordering; 0 for a sale nobody identified. Key of dim_customer. |
| promotion_key | BIGINT | none | Promotion applied to the line; 0 when there was none. Key of dim_promotion. |
| order_id | BIGINT | pseudonymous | Order number in the shop system. With line_no, identifies the row. |
| line_no | BIGINT | none | Position of the line within its order, from 1. |
| quantity | BIGINT | none | Copies sold on the line. Additive. |
| gross_cents | BIGINT | none | Quantity times the unit price charged, before any discount, in centavos. Additive. |
| discount_cents | BIGINT | none | Discount given on the line, in centavos. Additive. |
| net_cents | BIGINT | none | Net sales: gross_cents minus discount_cents, in centavos, without shipping. Additive. |
```

Um documento Markdown de 178 linhas, uma seção por tabela, com o grão em cima e uma linha por coluna com tipo,
classificação e significado. Pode ser publicado onde as pessoas olham, uma wiki, o repositório, uma ferramenta de
catálogo, e regerado a cada construção. Por ser gerado, **ele não consegue discordar do banco**: se uma coluna existe,
está no documento, e sua descrição é a guardada na coluna.

Isso inverte o problema antigo. Um dicionário escrito à mão é uma segunda cópia da verdade que precisa ser mantida em
dia por pessoas. Um gerado tem uma fonte só, os comentários, e o teste da seção 5 mantém essa fonte completa. A única
coisa que sobra para as pessoas é o que nenhum programa faz: **decidir o que cada coluna significa e escrever isso
bem**.

O mesmo padrão atravessa as ferramentas que fazem isso em escala. O dbt guarda descrições em YAML ao lado de cada
modelo e gera um site de documentação a partir delas, assunto da lição 12 de `pipelines-etl`. Ferramentas de catálogo
colhem os comentários dos bancos a que se conectam. A fonte do significado fica perto do código que cria a coluna.
