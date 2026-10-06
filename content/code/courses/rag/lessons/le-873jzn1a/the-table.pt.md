---
title: A tabela
version: 1
---

Os vetores vão para o PostgreSQL com pgvector, no banco `rag`, o mesmo motor que o `embeddings-vectors`
usou nas aulas 14 a 18. Um banco vetorial dedicado serviria igualmente; o motivo do PostgreSQL aqui é
que os metadados dos pedaços são dados relacionais, e os filtros da aula 14 são cláusulas `WHERE`.

```schooling-example
{
  "language": "python",
  "file": "ingest.py",
  "parts": [
    {
      "code": "SCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS chunks (\n    id          text PRIMARY KEY,\n    doc_id      text NOT NULL,\n    doc_version text NOT NULL,\n    status      text NOT NULL,\n    audience    text NOT NULL,\n    owner       text NOT NULL,\n    updated     date NOT NULL,\n    path        text NOT NULL,\n    position    int  NOT NULL,\n    text        text NOT NULL,\n    tokens      int  NOT NULL,\n    model       text NOT NULL,\n    embedding   vector(384) NOT NULL\n);\nCREATE INDEX IF NOT EXISTS chunks_doc ON chunks (doc_id);\n\"\"\"",
      "note": "Uma linha por pedaço. Ao lado do vetor: de onde o pedaço veio (`doc_id`, `path`, `position`), em que estado está o documento (`doc_version`, `status`, `updated`), quem pode lê-lo (`audience`), quem o mantém verdadeiro (`owner`), e como foi feito (`tokens`, `model`)."
    },
    {
      "code": "def chunks_of(doc_id, meta, body):\n    \"\"\"Every chunk of one document, with the metadata the search will filter on.\"\"\"\n    for position, (path, text) in enumerate(structured(body, SIZE)):\n        digest = hashlib.sha256(f\"{path}\\n{text}\".encode()).hexdigest()[:12]\n        yield {\"id\": f\"{doc_id}:{digest}\", \"doc_id\": doc_id, \"doc_version\": meta[\"version\"],\n               \"status\": meta[\"status\"], \"audience\": meta[\"audience\"], \"owner\": meta[\"owner\"],\n               \"updated\": meta[\"updated\"], \"path\": path, \"position\": position, \"text\": text,\n               \"tokens\": len(enc.encode(text)), \"model\": MODEL}",
      "note": "O id é o id do documento e um hash do caminho e do texto do pedaço. Duas execuções sobre texto igual produzem o mesmo id, e uma palavra mudada produz outro."
    }
  ]
}
```

## Toda coluna tem um leitor

```
ana@lab:~/rag$ psql -c "\d chunks"
                   Table "public.chunks"
   Column    |    Type     | Collation | Nullable | Default 
-------------+-------------+-----------+----------+---------
 id          | text        |           | not null | 
 doc_id      | text        |           | not null | 
 doc_version | text        |           | not null | 
 status      | text        |           | not null | 
 audience    | text        |           | not null | 
 owner       | text        |           | not null | 
 updated     | date        |           | not null | 
 path        | text        |           | not null | 
 position    | integer     |           | not null | 
 text        | text        |           | not null | 
 tokens      | integer     |           | not null | 
 model       | text        |           | not null | 
 embedding   | vector(384) |           | not null | 
Indexes:
    "chunks_pkey" PRIMARY KEY, btree (id)
    "chunks_doc" btree (doc_id)
```

Uma coluna que ninguém lê é uma coluna que ninguém mantém correta, então cada uma destas tem um trabalho
mais adiante no curso:

| coluna | lida por |
| --- | --- |
| `id` | a próxima seção: decidir o que gerar de novo |
| `doc_id`, `position` | citações, e remontar em ordem os pedaços de um documento |
| `path` | o cabeçalho da fonte no prompt, aula 7, e a recuperação do pequeno para o grande |
| `status`, `updated`, `doc_version` | os filtros do que está em vigor, aula 14 |
| `audience`, `owner` | os filtros de quem pode ler, aula 14, e a quem avisar quando um pedaço está errado |
| `tokens` | o orçamento de contexto, aula 12, e o custo por consulta, aula 17 |
| `model` | a verificação de que todo vetor veio do mesmo modelo |

A aula 2 defendeu que o momento mais barato de guardar o público, o dono, a versão e o status de um
documento é a primeira vez que ele é cortado em pedaços. Esta tabela é esse momento: os quatro são
copiados do cabeçalho de cada documento pelo `chunks_of`, então um documento que os declara nunca chega
ao índice sem eles.

## O que tem nela

```
ana@lab:~/rag$ psql -c "SELECT doc_id, count(*) AS chunks, sum(tokens) AS tokens FROM chunks GROUP BY doc_id ORDER BY doc_id"
         doc_id          | chunks | tokens 
-------------------------+--------+--------
 affiliate-api           |     10 |    706
 ebooks-and-audiobooks   |     10 |    543
 finance-refund-controls |      8 |    368
 gift-cards              |      5 |    268
 payments-and-invoices   |     10 |    536
 privacy-notice          |      9 |    512
 returns-policy          |     17 |    918
 returns-policy-2025     |      7 |    304
 seller-agreement        |     11 |    582
 shipping-and-delivery   |     14 |    722
 support-handbook        |     15 |    770
 terms-of-sale           |     14 |    674
 warehouse-runbook       |      7 |    417
(13 rows)
ana@lab:~/rag$ psql -c "SELECT id, path, status, audience FROM chunks WHERE doc_id = 'returns-policy' ORDER BY position LIMIT 4"
             id              |                        path                        | status  | audience 
-----------------------------+----------------------------------------------------+---------+----------
 returns-policy:fbe325d9ffef | Returns and refunds policy > The return window     | current | public
 returns-policy:cbd2372c3344 | Returns and refunds policy > The return window     | current | public
 returns-policy:0652374b6c43 | Returns and refunds policy > The return window     | current | public
 returns-policy:c459a83c0029 | Returns and refunds policy > How to start a return | current | public
(4 rows)
```

O regulamento de devoluções virou 17 pedaços, três deles em *The return window*. As contagens de tokens
somam 918 contra 1.113 do arquivo inteiro na aula 1: a diferença é o cabeçalho, o título e os títulos de
seção, que estão em `path` e não em `text`. Os ids são o id do documento seguido de doze caracteres
hexadecimais, e a próxima seção trata de onde eles vêm.
