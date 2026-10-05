---
title: Uma coluna de vetores no PostgreSQL
version: 1
---

As aulas 12 e 13 puseram a central de ajuda em bancos feitos para vetores: Chroma, FAISS, LanceDB,
Qdrant. É fácil sair delas achando que busca vetorial precisa de um banco só para ela. Os pedidos,
as contas e os artigos da Marginalia já moram no PostgreSQL, e o **pgvector** transforma esse banco
num banco de vetores. Ele é uma extensão, o mesmo mecanismo que o PostGIS usa para acrescentar tipos
geográficos, e acrescenta três coisas: um tipo de coluna chamado `vector`, operadores que medem a
distância entre dois vetores e dois tipos de índice.

A aula 2 o instalou para comparar três distâncias em dois vetores pequenos. Aqui ele guarda a
central de ajuda. O laboratório roda o PostgreSQL 16 com o pacote do pgvector que o Ubuntu 24.04
distribui, e o esquema são duas tabelas comuns:

```schooling-example
{
  "language": "sql",
  "file": "schema.sql",
  "parts": [
    {
      "code": "CREATE EXTENSION IF NOT EXISTS vector;",
      "note": "O pgvector é uma extensão: um comando por banco acrescenta o tipo `vector`, seus operadores e dois métodos de índice."
    },
    {
      "code": "CREATE TABLE articles (\n    id        text PRIMARY KEY,\n    category  text NOT NULL,\n    lang      text NOT NULL,\n    title     text NOT NULL,\n    body      text NOT NULL,\n    embedding vector(384) NOT NULL\n);",
      "note": "Uma tabela comum com uma coluna a mais. `vector(384)` fixa a dimensão, então um vetor de qualquer outro tamanho é recusado na entrada."
    },
    {
      "code": "CREATE TABLE queries (\n    id        text PRIMARY KEY,\n    text      text NOT NULL,\n    relevant  text[] NOT NULL,\n    embedding vector(384) NOT NULL\n);",
      "note": "As perguntas de clientes de `data/queries.jsonl`, com os artigos que o curso julgou relevantes como um array de texto. A próxima seção usa essas perguntas."
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

**A extensão está na versão 0.6.0**, e esse número importa mais que o normal. O pgvector anda
rápido: a 0.7.0 acrescentou um tipo de meia precisão, `halfvec`, vetores esparsos e índices sobre
vetores binários, e a 0.8.0 acrescentou as varreduras iterativas de índice, às quais a aula 17
volta. Nada disso existe na 0.6.0, então nada neste curso roda essas funções. Um serviço hospedado
escolhe a própria versão, e a primeira consulta a mandar a qualquer PostgreSQL que você não instalou
é a de `extversion` acima.

## Carregando a central de ajuda

O PostgreSQL não sabe o que é um array do NumPy, e o driver, o psycopg, não sabe o que é um
`vector`. O pacote Python `pgvector` faz a ponte entre os dois:

```schooling-example
{
  "language": "python",
  "file": "load.py",
  "parts": [
    {
      "code": "import json\nimport psycopg\nfrom pgvector.psycopg import register_vector\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]",
      "note": "`psycopg` é o driver do PostgreSQL e `register_vector` vem do pacote Python `pgvector`. Leia os dois arquivos de dados."
    },
    {
      "code": "A = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])\nQ = embed([q[\"text\"] for q in queries])",
      "note": "Transforme em vetores os 40 artigos (título e corpo, como na aula 1) e as 24 perguntas com o all-MiniLM-L6-v2."
    },
    {
      "code": "with psycopg.connect() as conn:\n    register_vector(conn)\n    cur = conn.cursor()\n    cur.executemany(\n        \"INSERT INTO articles (id, category, lang, title, body, embedding)\"\n        \" VALUES (%s, %s, %s, %s, %s, %s)\",\n        [(h[\"id\"], h[\"category\"], h[\"lang\"], h[\"title\"], h[\"body\"], v)\n         for h, v in zip(help, A)])\n    cur.executemany(\n        \"INSERT INTO queries (id, text, relevant, embedding) VALUES (%s, %s, %s, %s)\",\n        [(q[\"id\"], q[\"text\"], q[\"relevant\"], v) for q, v in zip(queries, Q)])",
      "note": "Sem argumentos, `connect()` lê `PGHOST` e `PGDATABASE` do ambiente. `register_vector` ensina esta conexão a mandar um array do NumPy como `vector` e a ler um de volta como array. Sair do bloco `with` faz o commit."
    },
    {
      "code": "print(len(help), \"articles and\", len(queries), \"queries written\")",
      "note": "Um INSERT não devolve nada, então o programa diz o que gravou."
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

**Cada vetor guardado ocupa 1.544 bytes**: os 384 × 4 = 1.536 bytes de números `float32` que a aula
1 contou, mais um cabeçalho de 8 bytes que guarda a dimensão. O pgvector guarda toda coordenada em
precisão simples, mande o Python o que mandar. A coluna `length` mostra que o comprimento 1 do
modelo sobreviveu à viagem. A aula 18 pesa a linha inteira e os índices em volta dela; aqui é só o
valor.

## O tipo confere a dimensão

O `384` de `vector(384)` é imposto, não só documentado. Um vetor do tamanho errado é recusado antes
de chegar à tabela:

```
ana@lab:~/emb$ psql -c "INSERT INTO queries VALUES ('q99', 'test', '{}', '[0.1,0.2,0.3]')"
ERROR:  expected 384 dimensions, not 3
```

Isso vale mais do que parece. A aula 1 mostrou que um vetor de um modelo não significa nada ao lado
de um vetor de outro, e o jeito mais comum de misturá-los é um script que carrega o modelo errado.
Quando os dois modelos têm dimensões diferentes, esta coluna pega o erro no primeiro INSERT. Dois
modelos com a mesma dimensão passam, e é por isso que o nome do modelo também pertence ao esquema,
numa coluna ou no próprio nome da tabela.
