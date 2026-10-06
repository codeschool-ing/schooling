---
title: Gerando a camada de staging
version: 1
---

Os metadados da camada de staging de Ana são uma lista de quinze tabelas, e só uma delas diz alguma coisa além do
nome:

```json
{
  "schema": "staging",
  "directory": "extract",
  "tables": [
    {"name": "shops"},
    {"name": "categories"},
    {"name": "publishers"},
    {"name": "authors"},
    {"name": "books", "types": {"isbn": "VARCHAR"}},
    {"name": "book_authors"},
    {"name": "customers"},
    {"name": "customer_changes"},
    {"name": "promotions"},
    {"name": "orders"},
    {"name": "order_lines"},
    {"name": "payments"},
    {"name": "stock_counts"},
    {"name": "events"},
    {"name": "event_attendance"}
  ]
}
```

O gerador a lê e escreve SQL:

```schooling-example
{
  "language": "python",
  "file": "gen_staging.py",
  "parts": [
    {
      "code": "\"\"\"Write the staging SQL from sources.json instead of by hand.\"\"\"\nimport json\nimport sys\n\nmeta = json.load(open(sys.argv[1]))\n\n",
      "note": "O arquivo de metadados vem na linha de comando, então o mesmo programa gera qualquer camada descrita do mesmo jeito."
    },
    {
      "code": "print(\"SET TimeZone = 'America/Sao_Paulo';\")\nprint(f\"CREATE SCHEMA {meta['schema']};\")\n",
      "note": "O que é escrito uma vez, antes de qualquer tabela: o fuso e o esquema, cujo nome também vem dos metadados."
    },
    {
      "code": "for t in meta[\"tables\"]:\n    options = [\"sample_size = -1\"]\n    if \"types\" in t:\n        pairs = \", \".join(f\"'{c}': '{ty}'\" for c, ty in t[\"types\"].items())\n        options.append(f\"types = {{{pairs}}}\")\n",
      "note": "As exceções moram aqui. Toda tabela recebe a mesma opção; uma tabela cuja entrada traz `types` os recebe a mais, e nenhuma tabela precisa de código próprio."
    },
    {
      "code": "    path = f\"{meta['directory']}/{t['name']}.csv\"\n    print(f\"CREATE TABLE {meta['schema']}.{t['name']} AS \"\n          f\"FROM read_csv('{path}', {', '.join(options)});\")",
      "note": "Um comando por entrada, com o caminho do arquivo montado a partir do diretório e do nome, e é por isso que os arquivos da extração precisam ter o nome das suas tabelas."
    }
  ]
}
```

```
ana@lab:~/wh$ python3 gen_staging.py sources.json > staging.sql && wc -l staging.sql && sed -n 1,3p staging.sql && grep books staging.sql
17 staging.sql
SET TimeZone = 'America/Sao_Paulo';
CREATE SCHEMA staging;
CREATE TABLE staging.shops AS FROM read_csv('extract/shops.csv', sample_size = -1);
CREATE TABLE staging.books AS FROM read_csv('extract/books.csv', sample_size = -1, types = {'isbn': 'VARCHAR'});
ana@lab:~/wh$ duckdb fresh.duckdb < staging.sql
```

Depois a camada gerada é construída num banco vazio e comparada com a escrita à mão, coluna por coluna:

```sql
-- Every staging column, by hand against generated, both ways round.
ATTACH 'wh.duckdb' AS hand (READ_ONLY);
ATTACH 'fresh.duckdb' AS generated (READ_ONLY);
WITH h AS (SELECT table_name, column_name, data_type FROM duckdb_columns()
           WHERE database_name = 'hand' AND schema_name = 'staging'),
     g AS (SELECT table_name, column_name, data_type FROM duckdb_columns()
           WHERE database_name = 'generated' AND schema_name = 'staging')
SELECT (SELECT count(*) FROM h) AS hand_columns,
       (SELECT count(*) FROM g) AS generated_columns,
       (SELECT count(*) FROM (FROM h EXCEPT FROM g)) AS only_by_hand,
       (SELECT count(*) FROM (FROM g EXCEPT FROM h)) AS only_generated;
```

```
ana@lab:~/wh$ duckdb < compare.sql
┌──────────────┬───────────────────┬──────────────┬────────────────┐
│ hand_columns │ generated_columns │ only_by_hand │ only_generated │
│    int64     │       int64       │    int64     │     int64      │
├──────────────┼───────────────────┼──────────────┼────────────────┤
│           77 │                77 │            0 │              0 │
└──────────────┴───────────────────┴──────────────┴────────────────┘
```

Dezessete linhas de SQL, e a única exceção, `books`, leva seu tipo forçado. Construída num banco vazio e comparada com
a camada de staging escrita à mão na lição 2, **cada uma das 77 colunas bate, em nome e em tipo, nos dois sentidos**.
A camada gerada é a escrita à mão, e daqui em diante acrescentar uma origem é uma linha de JSON.

Duas coisas valem ver no resultado. A exceção está à vista: `"types": {"isbn": "VARCHAR"}` está nos metadados, onde
quem lê a lista vê que essa tabela é diferente e por que o gerador tem uma opção para ela. Em quinze comandos escritos
à mão, era uma linha entre quinze. E a comparação é ela mesma o teste de que um gerador precisa: **uma camada gerada
merece confiança porque foi comparada com uma sabidamente boa**, e a comparação pode rodar toda vez que o gerador
muda.

Onde pipelines orientados a metadados deixam de compensar também fica à vista. O staging são quinze cópias de um
padrão; a carga tipo 2 da lição 5 é um programa cuidadoso, e gerá-la a partir de metadados exigiria um template tão
complicado quanto o programa que ele substitui. **Gere as camadas que se repetem, escreva as que pensam**: bronze para
prata, staging, dimensões tipo 1 e Data Vault são boas candidatas; a lógica de negócio da camada ouro não é.
