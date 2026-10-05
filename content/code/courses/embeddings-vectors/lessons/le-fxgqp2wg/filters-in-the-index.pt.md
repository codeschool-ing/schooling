---
title: Filtros dentro do índice
version: 1
---

Nenhuma das duas ordens serve em todo lugar, então os bancos vetoriais fizeram o que o pgvector 0.6.0
não faz: recebem o filtro **junto** com a consulta e decidem dentro do motor como aplicá-lo. A
interface parece a mesma em todos, um vetor, um k e uma condição, e o que muda é o que acontece com
a condição. Os três que rodaram nas aulas 12 e 13 rodaram todos aqui, na central de ajuda, com a
mesma pergunta e o filtro `lang = 'pt'`.

## Chroma

```schooling-example
{
  "language": "python",
  "file": "chroma_filter.py",
  "parts": [
    {
      "code": "import chromadb\nfrom minilm import embed\nfrom store import help, ids, D\n\nclient = chromadb.PersistentClient(path=\"chroma\")\ncol = client.create_collection(\"help\", configuration={\"hnsw\": {\"space\": \"cosine\"}})\ncol.add(ids=ids, embeddings=D,\n        metadatas=[{\"lang\": h[\"lang\"], \"category\": h[\"category\"]} for h in help])",
      "note": "Os 40 artigos entram com os vetores e dois campos de metadados cada."
    },
    {
      "code": "q = embed(\"how do I return a book\")\nr = col.query(query_embeddings=q, n_results=3, where={\"lang\": \"pt\"})\nprint(r[\"ids\"][0])\nr = col.query(query_embeddings=q, n_results=3,\n              where={\"$and\": [{\"lang\": \"en\"}, {\"category\": \"returns\"}]})\nprint(r[\"ids\"][0])",
      "note": "`where` recebe um dicionário: um campo e um valor, ou `$and` e `$or` em volta de vários."
    }
  ],
  "output": "ana@lab:~/emb$ python chroma_filter.py\n['h40', 'h39', 'h38']\n['h14', 'h17', 'h16']"
}
```

**O Chroma devolveu três artigos em português**, os mesmos três que o pré-filtro achou em
`filtered.py`, na mesma ordem. A condição `where` decidiu quais registros podiam ser devolvidos
antes que os três fossem escolhidos, então a falta da seção de pós-filtragem não acontece. A segunda
consulta combina dois campos com `$and`. O Chroma também tem `where_document`, que filtra pelo
próprio texto guardado, por exemplo se ele contém uma palavra.

## LanceDB

O LanceDB deixa você escolher, o que faz dele o lugar mais claro para ver a diferença entre as duas
ordens numa só tabela:

```schooling-example
{
  "language": "python",
  "file": "lance_filter.py",
  "parts": [
    {
      "code": "import lancedb\nfrom minilm import embed\nfrom store import help, D\n\ndb = lancedb.connect(\"lance\")\ntable = db.create_table(\"help\", [{\"id\": h[\"id\"], \"lang\": h[\"lang\"], \"vector\": v}\n                                 for h, v in zip(help, D)])\nq = embed(\"how do I return a book\")[0]",
      "note": "Uma tabela com uma coluna `vector` e uma coluna `lang`, uma linha por artigo."
    },
    {
      "code": "for prefilter in (True, False):\n    rows = (table.search(q).metric(\"cosine\")\n            .where(\"lang = 'pt'\", prefilter=prefilter).limit(3).to_list())\n    print(f\"prefilter={prefilter}:\", [r[\"id\"] for r in rows])",
      "note": "O mesmo filtro duas vezes. `prefilter` diz se ele é aplicado antes da busca ou depois."
    }
  ],
  "output": "ana@lab:~/emb$ python lance_filter.py\nprefilter=True: ['h40', 'h39', 'h38']\nprefilter=False: []"
}
```

**`prefilter=True`, o padrão, devolveu os três artigos em português; `prefilter=False` não devolveu
nenhum**, a mesma lista vazia que `post_filter` deu para a mesma pergunta. Sem índice vetorial numa
tabela de 40 linhas, o LanceDB buscou de forma exata nos dois casos, então a única diferença entre
as duas linhas é a ordem. Numa tabela grande com índice ANN, a troca da seção de pré-filtragem vale,
e o parâmetro é como você escolhe um lado dela por consulta.

## Qdrant

Este é o cliente Python do Qdrant em **modo local**, a implementação dentro do processo que a aula
13 usou, porque o servidor do Qdrant estava fora de alcance do laboratório:

```schooling-example
{
  "language": "python",
  "file": "qdrant_filter.py",
  "parts": [
    {
      "code": "from qdrant_client import QdrantClient, models\nfrom minilm import embed\nfrom store import help, D\n\nclient = QdrantClient(path=\"qdrant\")\nclient.create_collection(\"help\", vectors_config=models.VectorParams(\n    size=384, distance=models.Distance.COSINE))\nclient.upsert(\"help\", points=[\n    models.PointStruct(id=i, vector=v.tolist(), payload={\"article\": h[\"id\"], \"lang\": h[\"lang\"]})\n    for i, (h, v) in enumerate(zip(help, D))])",
      "note": "O Qdrant em modo local: a coleção mora num diretório e a busca roda dentro deste processo Python. Cada ponto leva um payload, a palavra do Qdrant para metadados."
    },
    {
      "code": "client.create_payload_index(\"help\", \"lang\", models.PayloadSchemaType.KEYWORD)",
      "note": "Um índice de payload é o que o servidor do Qdrant usa para filtrar dentro do grafo HNSW."
    },
    {
      "code": "only_pt = models.Filter(must=[models.FieldCondition(key=\"lang\", match=models.MatchValue(value=\"pt\"))])\nhits = client.query_points(\"help\", query=embed(\"how do I return a book\")[0].tolist(),\n                           query_filter=only_pt, limit=3)\nprint([p.payload[\"article\"] for p in hits.points])",
      "note": "Um filtro é um `Filter` de condições; `must` quer dizer que todas precisam valer."
    }
  ],
  "output": "ana@lab:~/emb$ python qdrant_filter.py\n/home/ana/emb/qdrant_filter.py:11: UserWarning: Payload indexes have no effect in the local Qdrant. Please use server Qdrant if you need payload indexes.\n  client.create_payload_index(\"help\", \"lang\", models.PayloadSchemaType.KEYWORD)\n['h40', 'h39', 'h38']"
}
```

**A consulta filtrada devolveu os três artigos em português.** O aviso é a linha interessante. O modo
local dá nota a todos os pontos e aplica o filtro como uma máscara, o que é exato e não precisa de
índice, então ele ignora o índice de payload e diz isso.

O **servidor** é onde o índice de payload importa, e ele não foi executado aqui. O Qdrant documenta a
sua abordagem como **HNSW filtrável** (filterable HNSW): com um índice de payload num campo, o
servidor estima quantos pontos um filtro deixa passar e, quando são poucos, busca neles de forma
exata, o que é um pré-filtro; senão, anda pelo grafo HNSW e confere a condição durante a caminhada,
então os pontos rejeitados não gastam a lista de resultados como gastaram no pgvector. Ele também
acrescenta ligações ao grafo para os valores indexados, para que a parte do grafo que um filtro
deixa continue conectada. Esse é o desenho que elimina a troca das duas seções anteriores, ao custo
de criar os índices de payload antes de carregar os dados.

## O que procurar num banco de dados

Três perguntas separam os motores que você vai encontrar, e cada uma tem resposta na documentação
deles:

- O filtro roda antes, depois ou durante a busca? Depois é o que encolhe o k, em silêncio.
- Uma consulta filtrada ainda devolve k resultados quando k linhas passam? Se não devolve, ache a
  configuração que faz isso, como o `hnsw.ef_search` no pgvector 0.6.0 ou as varreduras iterativas
  no 0.8.0.
- O campo precisa de um índice próprio? O servidor do Qdrant quer um índice de payload; o
  PostgreSQL usa uma B-tree na coluna, ou um índice parcial para um valor que você filtra com
  frequência.

Depois meça nos seus próprios dados, como `ten.sql` fez: conte o que uma consulta filtrada devolve,
para filtros de larguras diferentes, antes de confiar uma página de resultados a ela.
