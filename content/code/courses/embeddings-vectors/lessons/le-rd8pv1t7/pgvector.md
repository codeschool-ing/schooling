---
title: A vector column in PostgreSQL
version: 1
---

Lessons 12 and 13 put the help centre into stores built for vectors: Chroma, FAISS, LanceDB,
Qdrant. It is easy to come away thinking that vector search needs a database of its own.
Marginalia's orders, accounts and articles already live in PostgreSQL, and **pgvector** turns that
database into a vector store. It is an extension, the same mechanism PostGIS uses to add geographic
types, and it adds three things: a column type called `vector`, operators that measure the distance
between two vectors, and two kinds of index.

Lesson 2 installed it in a scratch database to compare three distances on paper. Here it holds the
help centre. The lab runs PostgreSQL 16 with the pgvector package Ubuntu 24.04 ships, and the schema
is two ordinary tables:

```schooling-example
{
  "language": "sql",
  "file": "schema.sql",
  "parts": [
    {
      "code": "CREATE EXTENSION IF NOT EXISTS vector;",
      "note": "pgvector is an extension: one statement per database adds the `vector` type, its operators and two index methods."
    },
    {
      "code": "CREATE TABLE articles (\n    id        text PRIMARY KEY,\n    category  text NOT NULL,\n    lang      text NOT NULL,\n    title     text NOT NULL,\n    body      text NOT NULL,\n    embedding vector(384) NOT NULL\n);",
      "note": "An ordinary table with one more column. `vector(384)` fixes the dimension, so a vector of any other length is refused on the way in."
    },
    {
      "code": "CREATE TABLE queries (\n    id        text PRIMARY KEY,\n    text      text NOT NULL,\n    relevant  text[] NOT NULL,\n    embedding vector(384) NOT NULL\n);",
      "note": "The customer questions from `data/queries.jsonl`, with the articles the course judged relevant as a text array. The next section uses them."
    }
  ]
}
```

```
ana@lab:~/emb$ psql -f schema.sql
CREATE EXTENSION
CREATE TABLE
CREATE TABLE
ana@lab:~/emb$ psql -c "SELECT extversion FROM pg_extension WHERE extname = 'vector'"
 extversion 
------------
 0.6.0
(1 row)

ana@lab:~/emb$ psql -c "\d articles"
                 Table "public.articles"
  Column   |    Type     | Collation | Nullable | Default 
-----------+-------------+-----------+----------+---------
 id        | text        |           | not null | 
 category  | text        |           | not null | 
 lang      | text        |           | not null | 
 title     | text        |           | not null | 
 body      | text        |           | not null | 
 embedding | vector(384) |           | not null | 
Indexes:
    "articles_pkey" PRIMARY KEY, btree (id)
```

**The extension is version 0.6.0**, and that number matters more than usual. pgvector moves fast:
0.7.0 added a half-precision `halfvec` type, sparse vectors and indexes over binary vectors, and
0.8.0 added iterative index scans, which lesson 17 comes back to. None of those exist in 0.6.0, so
nothing in this course runs them. A hosted service chooses its own version, and the first query to
send to any PostgreSQL you did not install is the `extversion` one above.

## Loading the help centre

PostgreSQL does not know what a NumPy array is, and the driver, psycopg, does not know what a
`vector` is. The `pgvector` Python package bridges the two:

```schooling-example
{
  "language": "python",
  "file": "load.py",
  "parts": [
    {
      "code": "import json\nimport psycopg\nfrom pgvector.psycopg import register_vector\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]",
      "note": "`psycopg` is the PostgreSQL driver and `register_vector` comes from the `pgvector` Python package. Read both data files."
    },
    {
      "code": "A = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])\nQ = embed([q[\"text\"] for q in queries])",
      "note": "Embed the 40 articles (title and body, as in lesson 1) and the 24 questions with all-MiniLM-L6-v2."
    },
    {
      "code": "with psycopg.connect() as conn:\n    register_vector(conn)\n    cur = conn.cursor()\n    cur.executemany(\n        \"INSERT INTO articles (id, category, lang, title, body, embedding)\"\n        \" VALUES (%s, %s, %s, %s, %s, %s)\",\n        [(h[\"id\"], h[\"category\"], h[\"lang\"], h[\"title\"], h[\"body\"], v)\n         for h, v in zip(help, A)])\n    cur.executemany(\n        \"INSERT INTO queries (id, text, relevant, embedding) VALUES (%s, %s, %s, %s)\",\n        [(q[\"id\"], q[\"text\"], q[\"relevant\"], v) for q, v in zip(queries, Q)])",
      "note": "With no arguments, `connect()` reads `PGHOST` and `PGDATABASE` from the environment. `register_vector` teaches this connection to send a NumPy array as a `vector` and read one back as an array. Leaving the `with` block commits."
    },
    {
      "code": "print(len(help), \"articles and\", len(queries), \"queries written\")",
      "note": "Nothing is returned by an INSERT, so the program says what it wrote."
    }
  ]
}
```

```
ana@lab:~/emb$ python load.py
40 articles and 24 queries written
ana@lab:~/emb$ psql -c "SELECT id, vector_dims(embedding) AS dims, round(vector_norm(embedding)::numeric, 4) AS length, pg_column_size(embedding) AS bytes FROM articles LIMIT 3"
 id  | dims | length | bytes 
-----+------+--------+-------
 h01 |  384 | 1.0000 |  1544
 h02 |  384 | 1.0000 |  1544
 h03 |  384 | 1.0000 |  1544
(3 rows)
```

**Each stored vector takes 1,544 bytes**: the 384 × 4 = 1,536 bytes of `float32` numbers lesson 1
counted, plus an 8-byte header that holds the dimension. pgvector keeps every coordinate in single
precision, whatever Python sends. The `length` column says the model's unit length survived the
trip. Lesson 18 weighs the whole row and the indexes around it; this is only the value.

## The type checks the dimension

The `384` in `vector(384)` is enforced, not documented. A vector of the wrong length is refused
before it reaches the table:

```
ana@lab:~/emb$ psql -c "INSERT INTO queries VALUES ('q99', 'test', '{}', '[0.1,0.2,0.3]')"
ERROR:  expected 384 dimensions, not 3
```

That is worth more than it looks. Lesson 1 showed that a vector from one model means nothing next
to a vector from another, and the commonest way to mix them is a script that loads the wrong
model. When the two models have different dimensions, this column catches it at the first INSERT.
Two models with the same dimension slip through, which is why the model's name belongs in the
schema as well, in a column or in the table's own name.
