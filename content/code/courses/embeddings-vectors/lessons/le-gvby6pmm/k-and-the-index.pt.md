---
title: O k e o índice
version: 1
---

Até aqui o k era seu para escolher. Com um índice aproximado ele é em parte do índice. A aula 15
mostrou que o HNSW busca andando por um grafo e mantendo uma lista dos melhores candidatos que viu,
e que o tamanho dessa lista, o **ef**, é o botão entre velocidade e recall. A aula 15 não
precisou dizer o que acontece quando você pede mais resultados do que essa lista comporta, e duas
bibliotecas respondem a isso de jeitos opostos.

## O pgvector devolve menos linhas

`fill.py` põe 2.000 linhas numa tabela do PostgreSQL e constrói um índice HNSW sobre elas. Os vetores
são aleatórios, não embeddings de texto nenhum, porque o que vem a seguir é uma propriedade do
índice e não dos dados:

```python
import numpy as np
import psycopg
from pgvector.psycopg import register_vector

rng = np.random.default_rng(16)
V = rng.standard_normal((2000, 384)).astype(np.float32)
V /= np.linalg.norm(V, axis=1, keepdims=True)

with psycopg.connect(autocommit=True) as conn:
    conn.execute("CREATE EXTENSION IF NOT EXISTS vector")
    register_vector(conn)
    conn.execute("CREATE TABLE points (id int PRIMARY KEY, embedding vector(384))")
    with conn.cursor().copy("COPY points FROM STDIN WITH (FORMAT BINARY)") as copy:
        copy.set_types(["int4", "vector"])
        for i, v in enumerate(V):
            copy.write_row((i, v))
    conn.execute("CREATE INDEX ON points USING hnsw (embedding vector_cosine_ops)")
```

E `top100.sql` pede os 100 vizinhos mais próximos da linha 7, contando o que volta:

```sql
SELECT count(*) AS returned
FROM (SELECT id FROM points
      ORDER BY embedding <=> (SELECT embedding FROM points WHERE id = 7)
      LIMIT 100) AS top;
```

```
ana@lab:~/emb$ python fill.py
ana@lab:~/emb$ psql -c "SHOW hnsw.ef_search"
ERROR:  unrecognized configuration parameter "hnsw.ef_search"
ana@lab:~/emb$ psql -f top100.sql -c "SHOW hnsw.ef_search"
 returned 
----------
       40
(1 row)

 hnsw.ef_search 
----------------
 40
(1 row)
```

**A consulta pediu 100 linhas e recebeu 40**, sem erro e sem aviso. A busca HNSW do pgvector guarda
`hnsw.ef_search` candidatos, 40 se você não mudar, e a varredura do índice para quando eles acabam.
`LIMIT 100` não consegue pedir mais do que a varredura produz. O primeiro `SHOW` falhou porque a
configuração pertence à biblioteca do pgvector, que a sessão carrega na primeira vez que usa um
vetor; depois da consulta, o mesmo `SHOW` imprime o 40. O plano confirma que é o índice que está trabalhando:

```
ana@lab:~/emb$ psql -c "EXPLAIN (COSTS OFF) SELECT id FROM points ORDER BY embedding <=> (SELECT embedding FROM points WHERE id = 7) LIMIT 100"
                       QUERY PLAN                        
---------------------------------------------------------
 Limit
   InitPlan 1 (returns $0)
     ->  Index Scan using points_pkey on points points_1
           Index Cond: (id = 7)
   ->  Index Scan using points_embedding_idx on points
         Order By: (embedding <=> $0)
(6 rows)
```

Suba o `ef_search` para 100 e as 100 linhas voltam. Desligue o índice e o PostgreSQL ordena todas as
linhas pela distância, o que é exato, e as 100 voltam também:

```
ana@lab:~/emb$ psql -c "SET hnsw.ef_search = 100" -f top100.sql
SET
 returned 
----------
      100
(1 row)

ana@lab:~/emb$ psql -c "SET enable_indexscan = off" -f top100.sql
SET
 returned 
----------
      100
(1 row)
```

Esse último resultado é a prova de que os 40 eram coisa do índice. A tabela teve 2.000 linhas o
tempo todo.

Isso rodou no pgvector 0.6.0, a versão do laboratório. O pgvector 0.8.0 acrescentou as **varreduras
iterativas de índice** (iterative index scans), que continuam buscando quando uma varredura se
esgota antes de preencher o `LIMIT`; a aula 17 encontra o problema que elas resolvem na forma mais
aguda. Elas não existem no 0.6.0, e nada nesta aula as usou.

## O hnswlib busca mais largo sem avisar

Os mesmos 2.000 vetores no hnswlib, com a largura de busca em 10 e 100 vizinhos pedidos:

```schooling-example
{
  "language": "python",
  "file": "ef.py",
  "parts": [
    {
      "code": "import hnswlib\nimport numpy as np\n\nrng = np.random.default_rng(16)\nV = rng.standard_normal((2000, 384)).astype(np.float32)\nV /= np.linalg.norm(V, axis=1, keepdims=True)\nindex = hnswlib.Index(space=\"cosine\", dim=384)\nindex.init_index(max_elements=2000)\nindex.add_items(V, np.arange(2000))",
      "note": "2.000 vetores aleatórios de comprimento 1, com a mesma semente de `fill.py`, num índice do hnswlib com os parâmetros padrão."
    },
    {
      "code": "index.set_ef(10)\nlabels, distances = index.knn_query(V[7], k=100)\nprint(\"ef:\", index.ef, \" asked for 100, got\", labels.shape[1])",
      "note": "Ponha a largura da busca em 10 e peça 100 vizinhos."
    }
  ],
  "output": "ana@lab:~/emb$ python ef.py\nef: 10  asked for 100, got 100"
}
```

**O hnswlib devolveu os 100.** Ele busca com o maior entre `ef` e `k`, então pedir mais que `ef`
alarga a busca daquela consulta, e `index.ef` continua dizendo 10 depois. É o comportamento mais
amigável, e significa que o custo de uma consulta no hnswlib cresce com k mesmo que você nunca
tenha mexido no `ef`.

## O que fazer com isso

Uma regra cobre os dois: **a largura de busca do índice tem que ser pelo menos k**, e maior que k se
você quer um bom recall. No pgvector isso é uma configuração sua:

```sql
SET hnsw.ef_search = 100;
```

`SET` vale para a sessão, `SET LOCAL` para uma transação, e `ALTER DATABASE ... SET` torna o valor o
padrão das novas conexões. Ponha onde toda consulta com `LIMIT` grande vá recebê-lo, e acrescente um
teste que conte as linhas que um `LIMIT` grande devolve, porque um resultado curto parece exatamente
uma busca que tinha menos respostas boas.
