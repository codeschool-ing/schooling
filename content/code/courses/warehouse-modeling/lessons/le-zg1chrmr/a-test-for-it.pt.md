---
title: Um teste para colunas sem documentação
version: 1
---

"Toda coluna tem uma descrição" é uma regra, e uma regra que ninguém confere é um desejo. Este programa a confere, e
mais uma regra ao lado: toda coluna precisa ter também uma **classificação**, lida de um arquivo CSV que a seção 9
explica.

```python
"""Fail if any column of the model has no description or no classification."""
import sys

import duckdb

con = duckdb.connect("wh.duckdb", read_only=True)
con.sql("CREATE TEMP TABLE classes AS FROM read_csv('classification.csv')")
problems = con.sql("""
    WITH model AS (
        SELECT table_name, column_name, comment FROM duckdb_columns()
        WHERE schema_name = 'main'
          AND regexp_matches(table_name, '^(dim|fact|bridge)_')
    )
    SELECT m.table_name, m.column_name,
           CASE WHEN m.comment IS NULL THEN 'no description' ELSE 'no classification' END
    FROM model m LEFT JOIN classes c USING (table_name, column_name)
    WHERE m.comment IS NULL OR c.class IS NULL
    UNION ALL
    SELECT c.table_name, c.column_name, 'classified but does not exist'
    FROM classes c ANTI JOIN model m USING (table_name, column_name)
    ORDER BY ALL
""").fetchall()

for table, column, problem in problems[:5]:
    print(f"{table}.{column}: {problem}")
if len(problems) > 5:
    print(f"... and {len(problems) - 5} more")
print(f"problems: {len(problems)}")
sys.exit(1 if problems else 0)
```

Ele lê as tabelas do modelo no próprio catálogo do DuckDB, então não consegue deixar passar uma tabela que ninguém
listou. E confere nos dois sentidos: uma coluna sem descrição ou sem classificação é um problema, e também uma
classificação de uma coluna que não existe mais, que é como uma coluna renomeada aparece. Ele imprime os cinco
primeiros problemas, a contagem, e sai com 1 se houver algum.

No warehouse como está, com um comentário escrito:

```
ana@lab:~/wh$ python3 check_docs.py; echo "exit status $?"
bridge_book_author.author_key: no description
bridge_book_author.book_key: no description
bridge_book_author.position: no description
bridge_book_author.weight: no description
dim_author.author_id: no description
... and 86 more
problems: 91
exit status 1
```

**Noventa e uma de 92 colunas não têm descrição.** Não é um resultado incomum para um warehouse construído por uma
pessoa cuidadosa ao longo de doze lições; é o normal. Descrições ficam para o fim, o que na prática quer dizer nunca, a
menos que algo falhe sem elas.

É para isso que serve o status de saída. Executado no pipeline que constrói o warehouse, este teste transforma "por
favor, documente suas colunas" numa construção que não passa enquanto elas não estiverem documentadas. É o mesmo passo
da conferência de contrato da lição 11: **uma promessa vira um arquivo, e o arquivo é executado**.
