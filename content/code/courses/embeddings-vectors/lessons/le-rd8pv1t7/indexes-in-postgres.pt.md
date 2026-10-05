---
title: Índices no PostgreSQL
version: 1
---

Toda busca até aqui leu as 40 linhas, calculou 40 distâncias e as ordenou. Isso é exato, e em 40
linhas é instantâneo. Um índice troca a exatidão por velocidade: responde a partir de uma estrutura
construída de antemão e lê uma parte pequena da tabela. O pgvector 0.6.0 oferece duas estruturas
assim, **HNSW** e **IVFFlat**, e as duas são aproximadas. A aula 15 explica como cada uma funciona e
o que fazem seus parâmetros. Esta seção é sobre o lado do PostgreSQL: construir um índice e
conferir que a consulta o usa.

## Um índice que o planejador ignora

A crença comum é que criar um índice faz as consultas o usarem. Construa um índice HNSW na central de
ajuda e pergunte ao PostgreSQL como ele rodaria a busca:

```
ana@lab:~/emb$ psql -c "CREATE INDEX ON articles USING hnsw (embedding vector_cosine_ops)"
CREATE INDEX
ana@lab:~/emb$ psql -c "EXPLAIN (COSTS OFF) SELECT id FROM articles ORDER BY embedding <=> (SELECT embedding FROM queries WHERE id = 'q01') LIMIT 3"
                    QUERY PLAN                    
--------------------------------------------------
 Limit
   InitPlan 1 (returns $0)
     ->  Index Scan using queries_pkey on queries
           Index Cond: (id = 'q01'::text)
   ->  Sort
         Sort Key: ((articles.embedding <=> $0))
         ->  Seq Scan on articles
(7 rows)
```

**`Seq Scan on articles`: o índice existe e o plano não encosta nele.** O planejador do PostgreSQL
estima o custo de cada jeito de rodar uma consulta e escolhe o mais barato. Quarenta linhas cabem em
poucas páginas, e ler todas sai mais barato que percorrer um grafo, então o planejador lê todas. É a
decisão certa, e é também por isso que um teste numa tabela pequena não prova nada sobre o índice.
`EXPLAIN` mostra o plano sem rodar a consulta; é o único jeito de saber qual plano você recebeu.

## Vinte mil linhas

Para ver o índice trabalhar, a tabela tem de ser grande o bastante para que uma leitura completa
custe alguma coisa. `noise.py` cria uma: 20.000 vetores aleatórios de comprimento 1, sem texto por
trás, porque o que vem a seguir é sobre o plano e não sobre o significado.

```schooling-example
{
  "language": "python",
  "file": "noise.py",
  "parts": [
    {
      "code": "import numpy as np\nimport psycopg\nfrom pgvector.psycopg import register_vector\n\nrng = np.random.default_rng(14)\nX = rng.standard_normal((20000, 384)).astype(np.float32)\nX /= np.linalg.norm(X, axis=1, keepdims=True)",
      "note": "20.000 vetores aleatórios de 384 números, sorteados de uma distribuição normal com semente fixa e divididos pelo próprio comprimento. Não há texto por trás deles."
    },
    {
      "code": "with psycopg.connect() as conn:\n    conn.execute(\"CREATE TABLE noise (id integer PRIMARY KEY, embedding vector(384) NOT NULL)\")\n    register_vector(conn)\n    cur = conn.cursor()\n    with cur.copy(\"COPY noise (id, embedding) FROM STDIN WITH (FORMAT BINARY)\") as copy:\n        copy.set_types([\"integer\", \"vector\"])\n        for i, v in enumerate(X):\n            copy.write_row((i, v))\n    print(conn.execute(\"SELECT count(*) FROM noise\").fetchone()[0], \"rows in noise\")",
      "note": "`COPY` em formato binário é a carga em massa do PostgreSQL, muito mais rápida que um INSERT por linha. `set_types` diz ao psycopg o que é cada coluna."
    }
  ],
  "output": "ana@lab:~/emb$ python noise.py\n20000 rows in noise"
}
```

A mesma busca, os três mais próximos da linha 7, antes de existir um índice em `noise`:

```
ana@lab:~/emb$ psql -e -f before.sql
EXPLAIN (ANALYZE, COSTS OFF)
SELECT id FROM noise
ORDER BY embedding <=> (SELECT embedding FROM noise WHERE id = 7)
LIMIT 3;
                                           QUERY PLAN                                           
------------------------------------------------------------------------------------------------
 Limit (actual time=13.014..15.303 rows=3 loops=1)
   InitPlan 1 (returns $0)
     ->  Index Scan using noise_pkey on noise noise_1 (actual time=0.039..0.041 rows=1 loops=1)
           Index Cond: (id = 7)
   ->  Gather Merge (actual time=13.013..15.294 rows=3 loops=1)
         Workers Planned: 2
         Params Evaluated: $0
         Workers Launched: 2
         ->  Sort (actual time=6.371..6.372 rows=3 loops=3)
               Sort Key: ((noise.embedding <=> $0))
               Sort Method: top-N heapsort  Memory: 25kB
               Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
               Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
               ->  Parallel Seq Scan on noise (actual time=0.015..5.732 rows=6667 loops=3)
 Planning Time: 0.373 ms
 Execution Time: 15.740 ms
(16 rows)
```

Depois construa o índice e rode de novo:

```
ana@lab:~/emb$ psql -e -f after.sql
Timing is on.
CREATE INDEX ON noise USING hnsw (embedding vector_cosine_ops);
CREATE INDEX
Time: 8262.853 ms (00:08.263)
Timing is off.
EXPLAIN (ANALYZE, COSTS OFF)
SELECT id FROM noise
ORDER BY embedding <=> (SELECT embedding FROM noise WHERE id = 7)
LIMIT 3;
                                           QUERY PLAN                                           
------------------------------------------------------------------------------------------------
 Limit (actual time=3.417..3.424 rows=3 loops=1)
   InitPlan 1 (returns $0)
     ->  Index Scan using noise_pkey on noise noise_1 (actual time=0.042..0.042 rows=1 loops=1)
           Index Cond: (id = 7)
   ->  Index Scan using noise_embedding_idx on noise (actual time=3.416..3.420 rows=3 loops=1)
         Order By: (embedding <=> $0)
 Planning Time: 0.484 ms
 Execution Time: 3.587 ms
(8 rows)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Dois planos de consulta para a mesma busca, os três mais próximos entre 20.000 linhas. Sem índice: um Limit acima de um Gather Merge, acima de 3 nós Sort, cada um acima de um Parallel Seq Scan que leu 6667 linhas; tempo de execução 15.740 ms. Com o índice HNSW: um Limit acima de um único Index Scan usando noise_embedding_idx, que devolveu 3 linhas; tempo de execução 3.587 ms.\"><text x=\"185\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">sem índice</text><rect x=\"115\" y=\"40\" width=\"140\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Limit</text><path d=\"M185 68 L185 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"100\" y=\"88\" width=\"170\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Gather Merge</text><path d=\"M185 116 L70 136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"138\" width=\"100\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Sort</text><path d=\"M70 166 L70 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"15\" y=\"188\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Parallel</text><text x=\"70\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Seq Scan</text><text x=\"70\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">rows=6667</text><path d=\"M185 116 L185 136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"135\" y=\"138\" width=\"100\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Sort</text><path d=\"M185 166 L185 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"130\" y=\"188\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Parallel</text><text x=\"185\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Seq Scan</text><text x=\"185\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">rows=6667</text><path d=\"M185 116 L300 136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"250\" y=\"138\" width=\"100\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Sort</text><path d=\"M300 166 L300 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"245\" y=\"188\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Parallel</text><text x=\"300\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Seq Scan</text><text x=\"300\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">rows=6667</text><text x=\"185\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">linhas lidas por cada um</text><text x=\"185\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3 processos, cada um lê sua parte da tabela</text><text x=\"185\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">Execution Time: 15.740 ms</text><path d=\"M380 30 L380 325\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"550\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">com o índice HNSW</text><rect x=\"480\" y=\"40\" width=\"140\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Limit</text><path d=\"M550 68 L550 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"420\" y=\"88\" width=\"260\" height=\"44\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Index Scan using</text><text x=\"550\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">noise_embedding_idx</text><text x=\"550\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">rows=3</text><text x=\"550\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">percorre o grafo, não lê nenhuma tabela inteira</text><text x=\"550\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Execution Time: 3.587 ms</text></svg>", "caption": "A mesma consulta sobre as 20.000 linhas de noise, a partir das duas saídas de EXPLAIN ANALYZE acima. Sem índice, todas as linhas são lidas e ordenadas, divididas entre processos paralelos; com o índice HNSW, uma varredura do índice devolve as três linhas. Os tempos são desta execução."}
```

**Antes, três processos leram cerca de 6.667 linhas cada um e as ordenaram; depois, uma varredura de
índice devolveu as três linhas.** As duas linhas de `Execution Time`, `15.740 ms` e `3.587 ms`, são
desta execução, numa máquina que outras pessoas estavam usando, e a distância entre elas cresce com a
tabela: a varredura sequencial lê todas as linhas e a de índice não. A construção levou
`8262.853 ms`, uma vez, e cada inserção posterior paga de novo um pouco disso para entrar no grafo.
A aula 18 pesa o índice em disco.

A resposta do índice é aproximada, e nada acima conferiu que as três linhas dele são as três exatas.
A aula 15 mede com que frequência um índice aproximado perde um vizinho verdadeiro.

## O operador tem de combinar com o índice

Um índice é construído para uma distância. O `vector_cosine_ops` do `CREATE INDEX` acima diz que este
ordena por `<=>`, e por nada mais. Peça a distância L2, ou escreva o cosseno como similaridade e
ordene ao contrário, e o planejador não consegue usá-lo:

```
ana@lab:~/emb$ psql -e -f unused.sql
EXPLAIN (COSTS OFF)
SELECT id FROM noise
ORDER BY embedding <-> (SELECT embedding FROM noise WHERE id = 7)
LIMIT 3;
                      QUERY PLAN                      
------------------------------------------------------
 Limit
   InitPlan 1 (returns $0)
     ->  Index Scan using noise_pkey on noise noise_1
           Index Cond: (id = 7)
   ->  Sort
         Sort Key: ((noise.embedding <-> $0))
         ->  Seq Scan on noise
(7 rows)

EXPLAIN (COSTS OFF)
SELECT id FROM noise
ORDER BY 1 - (embedding <=> (SELECT embedding FROM noise WHERE id = 7)) DESC
LIMIT 3;
                                 QUERY PLAN                                  
-----------------------------------------------------------------------------
 Limit
   InitPlan 1 (returns $0)
     ->  Index Scan using noise_pkey on noise noise_1
           Index Cond: (id = 7)
   ->  Sort
         Sort Key: (('1'::double precision - (noise.embedding <=> $0))) DESC
         ->  Seq Scan on noise
(7 rows)
```

**Os dois planos voltaram para `Seq Scan on noise`**, sem nenhum aviso: as consultas ainda devolvem
as linhas certas, devagar. A segunda é a armadilha, porque `1 - (embedding <=> q)` em ordem
decrescente é a mesma ordem que `embedding <=> q` em ordem crescente. O planejador não faz essa
álgebra. Um índice atende `ORDER BY` *coluna* *operador* *valor*, crescente, com um `LIMIT`, e o
operador tem de ser o que a classe de operadores nomeia:

| operador | distância | classe de operadores |
|---|---|---|
| `<->` | L2 | `vector_l2_ops` |
| `<#>` | produto interno negativo | `vector_ip_ops` |
| `<=>` | cosseno | `vector_cosine_ops` |

Escreva o `ORDER BY` nesse formato e calcule a similaridade na lista do `SELECT`, como `search.py`
faz.

## IVFFlat, e um índice que perde linhas

O segundo tipo de índice separa as linhas em grupos, `lists` deles, quando é construído. Uma consulta
olha só no grupo ou nos grupos mais próximos da pergunta. Aqui ele está nos 40 artigos, com as 100
listas que serviriam para uma tabela grande:

```
ana@lab:~/emb$ psql -c "CREATE INDEX ON articles USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100)"
NOTICE:  ivfflat index created with little data
DETAIL:  This will cause low recall.
HINT:  Drop the index until the table has more data.
CREATE INDEX
ana@lab:~/emb$ python search.py "how do I get my money back"
0.554  0.446  h18  Returning a gift
```

**A busca pediu três artigos e recebeu um**, sem erro. O PostgreSQL imprimiu um `NOTICE` quando o
índice foi construído, e ninguém lê um aviso num script de implantação. O planejador escolheu o
índice novo em vez do HNSW, o que `\d articles` e `EXPLAIN` confirmam:

```
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
    "articles_embedding_idx" hnsw (embedding vector_cosine_ops)
    "articles_embedding_idx1" ivfflat (embedding vector_cosine_ops) WITH (lists='100')

ana@lab:~/emb$ psql -c "EXPLAIN (COSTS OFF) SELECT id FROM articles ORDER BY embedding <=> (SELECT embedding FROM queries WHERE id = 'q01') LIMIT 3"
                         QUERY PLAN                         
------------------------------------------------------------
 Limit
   InitPlan 1 (returns $0)
     ->  Index Scan using queries_pkey on queries
           Index Cond: (id = 'q01'::text)
   ->  Index Scan using articles_embedding_idx1 on articles
         Order By: (embedding <=> $0)
(6 rows)
```

E a configuração que decide em quantos grupos uma consulta olha:

```
ana@lab:~/emb$ psql -c "SELECT count(*) AS returned FROM (SELECT id FROM articles ORDER BY embedding <=> (SELECT embedding FROM queries WHERE id = 'q01') LIMIT 3) AS top" -c "SHOW ivfflat.probes"
 returned 
----------
        1
(1 row)

 ivfflat.probes 
----------------
 1
(1 row)
```

**`ivfflat.probes` vale 1, então a consulta olhou num grupo, e esse grupo tinha um artigo.** Os
grupos foram calculados a partir das 40 linhas que existiam quando o índice foi construído: 100
grupos para 40 artigos deixam a maioria deles vazia. Essa é a regra geral do IVFFlat, não uma
esquisitice de uma tabela minúscula. Os grupos dele são aprendidos dos dados presentes no
`CREATE INDEX`, então ele é construído depois que a tabela é carregada, e reconstruído quando os
dados mudaram muito. O HNSW não tem essa etapa e pode ser criado numa tabela vazia. A aula 15
explica `lists` e `probes`.

Apagar o índice traz as três linhas de volta:

```
ana@lab:~/emb$ psql -c "DROP INDEX articles_embedding_idx1"
DROP INDEX
ana@lab:~/emb$ python search.py "how do I get my money back"
0.554  0.446  h18  Returning a gift
0.562  0.438  h15  When your refund arrives
0.601  0.399  h22  Charged twice for one order
```

A lição a guardar é a que o `EXPLAIN` ensinou duas vezes: **o índice que uma consulta usa é escolha
do planejador, e um índice aproximado pode devolver menos linhas que o `LIMIT` sem avisar.** A aula
16 encontra a versão disso no HNSW, e a aula 17 a versão que um filtro causa. As duas são achadas do
mesmo jeito: contando as linhas que uma consulta devolve numa tabela do tamanho da de produção.
