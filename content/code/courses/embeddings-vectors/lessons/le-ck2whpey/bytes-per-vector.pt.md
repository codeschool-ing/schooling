---
title: Bytes por vetor
version: 1
---

Você decide o tamanho de um armazenamento de vetores no dia em que escolhe o modelo, muito antes
de escolher um banco de dados. É o número de dimensões vezes quatro bytes, vezes o número de
linhas. A expectativa comum é que o banco encolha isso, ou pelo menos não acrescente nada. Esta
seção mede o que ele acrescenta de verdade.

## Quatro bytes por número

Cada coordenada é um `float32`, então um vetor custa **4 × d bytes**, seja qual for o texto de
origem. São 1.536 bytes para os 384 números do all-MiniLM-L6-v2 (a aula 1 imprimiu isso), 6.144 para os
1536 do text-embedding-3-small, e o dobro disso para os 3072 do text-embedding-3-large ou do
gemini-embedding-001. A dimensão aparece na coluna `dims` da tabela de preços que a seção 05 desta
aula cita, e é o único número dessa tabela que você paga todo mês, e não uma vez só.

O conteúdo dos números não muda o tamanho deles, então as medições desta aula usam vetores
aleatórios de comprimento 1 em vez de embeddings. São 20.000 deles, com 384 e com 1536 dimensões,
saídos de um auxiliar de seis linhas.

```python
import numpy as np


def unit_vectors(n, d, seed=18):
    """n random vectors of d float32 numbers, each of length 1."""
    rng = np.random.default_rng(seed)
    X = rng.standard_normal((n, d), dtype=np.float32)
    return X / np.linalg.norm(X, axis=1, keepdims=True)
```

## Num arquivo, nada é acrescentado

```schooling-example
{
  "language": "python",
  "file": "files.py",
  "parts": [
    {
      "code": "import os\nimport faiss\nimport numpy as np\nfrom synth import unit_vectors\n\nN = 20_000",
      "note": "`unit_vectors` é o auxiliar de seis linhas acima. Vinte mil linhas bastam para cada tamanho se estabilizar num valor por vetor."
    },
    {
      "code": "for d in (384, 1536):\n    X = unit_vectors(N, d)\n    np.save(f\"v{d}.npy\", X)\n    flat = faiss.IndexFlatIP(d)\n    flat.add(X)\n    faiss.write_index(flat, f\"flat{d}.faiss\")",
      "note": "Para cada dimensão, os mesmos vetores de três jeitos: na memória, como arquivo `.npy` do NumPy e como índice plano do FAISS gravado em disco."
    },
    {
      "code": "    print(f\"{d:5} dims  in memory {X.nbytes:>11,}  {X.nbytes // N:>5} per vector\")\n    for f in (f\"v{d}.npy\", f\"flat{d}.faiss\"):\n        size = os.path.getsize(f)\n        print(f\"{f:>16}  {size:>11,}  {size / N:>7.1f} per vector\")",
      "note": "Os bytes na memória e o tamanho de cada arquivo dividido pelo número de vetores. O que passar de 4 × d por vetor é o custo do próprio formato."
    }
  ]
}
```

```
ana@lab:~/emb$ python files.py
  384 dims  in memory  30,720,000   1536 per vector
        v384.npy   30,720,128   1536.0 per vector
   flat384.faiss   30,720,045   1536.0 per vector
 1536 dims  in memory 122,880,000   6144 per vector
       v1536.npy  122,880,128   6144.0 per vector
  flat1536.faiss  122,880,045   6144.0 per vector
```

**Um arquivo custa 4 × d bytes por vetor e nada mais.** O `.npy` do NumPy põe um cabeçalho de 128
bytes na frente do array inteiro e o índice plano do FAISS, 45; espalhados por 20.000 vetores,
nenhum dos dois tira a coluna por vetor de `1536.0` ou `6144.0`. Esse é o piso: os números, um depois
do outro.

## No PostgreSQL, uma linha custa mais que o vetor

Os mesmos vetores no pgvector, uma tabela por dimensão, medidos por uma consulta que separa a
tabela nas suas partes:

```schooling-example
{
  "language": "python",
  "file": "load.py",
  "parts": [
    {
      "code": "import sys\nimport numpy as np\nimport psycopg\nfrom pgvector.psycopg import register_vector\n\nd = int(sys.argv[1])\nX = np.load(f\"v{d}.npy\")",
      "note": "Lê de volta o `.npy` que `files.py` gravou, para a dimensão passada na linha de comando."
    },
    {
      "code": "with psycopg.connect(autocommit=True) as conn:\n    conn.execute(\"CREATE EXTENSION IF NOT EXISTS vector\")\n    register_vector(conn)\n    conn.execute(f\"CREATE TABLE v{d} (id bigint PRIMARY KEY, embedding vector({d}))\")",
      "note": "Uma tabela só com o id e o vetor, para que o tamanho dela seja o custo do vetor e da linha."
    },
    {
      "code": "    copy = f\"COPY v{d} (id, embedding) FROM STDIN WITH (FORMAT BINARY)\"\n    with conn.cursor().copy(copy) as cp:\n        cp.set_types([\"int8\", \"vector\"])\n        for i, v in enumerate(X):\n            cp.write_row((i, v))\n    conn.execute(f\"VACUUM ANALYZE v{d}\")\n    print(f\"v{d}: {len(X)} rows\")",
      "note": "`COPY` em binário é o jeito rápido de carregar linhas; `VACUUM ANALYZE` deixa as estatísticas da tabela em dia, inclusive a contagem de linhas."
    }
  ]
}
```

```sql
SELECT c.relname                          AS "table",
       c.reltuples::bigint                AS "rows",
       pg_relation_size(c.oid)            AS heap,
       pg_relation_size(c.reltoastrelid)  AS toast,
       pg_indexes_size(c.oid)             AS indexes,
       pg_total_relation_size(c.oid) / c.reltuples::bigint AS per_row
  FROM pg_class c
 WHERE c.relname IN ('v384', 'v1536')
 ORDER BY 1 DESC;
```

```
ana@lab:~/emb$ python load.py 384 && python load.py 1536
v384: 20000 rows
v1536: 20000 rows
ana@lab:~/emb$ psql -f sizes.sql
 table | rows  |   heap   |   toast   | indexes | per_row 
-------+-------+----------+-----------+---------+---------
 v384  | 20000 | 33030144 |         0 |  466944 |    1676
 v1536 | 20000 |  1212416 | 163840000 |  466944 |    8371
(2 rows)
```

As duas linhas pagam o custo extra de jeitos diferentes, então leia uma de cada vez.

**Com 384 dimensões uma linha custa 1.676 bytes para guardar 1.536 bytes de números.** O pgvector
guarda um vetor como seus 4 × d bytes mais um cabeçalho de 8, e o PostgreSQL acrescenta o próprio
cabeçalho e um ponteiro a cada linha. Uma página de 8 KB só aceita linhas inteiras, então o espaço
que sobra no fim de cada página é desperdiçado. `indexes` é a chave primária, 466.944 bytes nas duas
tabelas.

**Com 1536 dimensões a tabela propriamente dita fica quase vazia.** `heap` tem 1.212.416 bytes e
`toast` tem 163.840.000. Um vetor de 1536 dimensões, mais de 6 KB, é grande demais para dividir uma
página com os vizinhos. O PostgreSQL o tira da linha e o leva para o armazenamento **TOAST** da
tabela, cortado em pedaços, deixando um ponteiro no lugar. O pgvector 0.6.0 declara o tipo como
`STORAGE external`, o que quer dizer levado para fora e nunca comprimido. Contando tudo, uma linha
custa 8.371 bytes para 6.144 bytes de números.

Nada disso é defeito, e os dois custos extras são fixos por linha. Na prática, **a conta crua
subestima o que um banco vai ocupar**: no orçamento, multiplique pelo
`per_row` medido, e não por 4 × d. E isso ainda é antes de qualquer índice, que é o assunto da
próxima seção.
