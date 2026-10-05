---
title: Qdrant, em modo local
version: 1
---

O Qdrant é um servidor de banco de vetores, de código aberto e escrito em Rust, que você roda por
conta própria ou aluga como Qdrant Cloud. O cliente Python dele também tem um **modo local**: passe um
`path` em vez de uma URL e ele roda, dentro do seu processo, uma implementação em Python da mesma API,
guardando os dados num diretório. **O modo local é o que rodou aqui.** O servidor do Qdrant é um
programa à parte que o laboratório não conseguiu baixar, então tudo abaixo é o cliente sozinho, e
esta seção diz onde isso difere da coisa de verdade.

```schooling-example
{
  "language": "python",
  "file": "qd.py",
  "parts": [
    {
      "code": "import json\nfrom qdrant_client import QdrantClient\nfrom qdrant_client.models import (Distance, FieldCondition, Filter, MatchValue,\n                                  PointStruct, VectorParams)\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nX = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])",
      "note": "Os artigos e os seus vetores, como antes."
    },
    {
      "code": "client = QdrantClient(path=\"qdrant\")\nclient.create_collection(\"help\", vectors_config=VectorParams(size=384, distance=Distance.COSINE))",
      "note": "`path=` é o modo local: sem servidor, um diretório. A coleção é criada com o seu tamanho e a sua distância."
    },
    {
      "code": "client.upsert(\"help\", points=[\n    PointStruct(id=int(h[\"id\"][1:]), vector=v.tolist(),\n                payload={\"article\": h[\"id\"], \"category\": h[\"category\"], \"title\": h[\"title\"]})\n    for h, v in zip(help, X)])\nprint(client.count(\"help\").count, \"points\")",
      "note": "Um ponto é um id, um vetor e um payload. O id tem de ser um inteiro ou um UUID, então h15 vira 15 de novo; o id do artigo vai no payload."
    },
    {
      "code": "q = embed(\"how do I get my money back\")[0].tolist()\nfor p in client.query_points(\"help\", query=q, limit=3).points:\n    print(f\"{p.score:.4f}  {p.id}  {p.payload['title']}\")",
      "note": "Os três mais próximos, cada um com a sua nota."
    },
    {
      "code": "ebooks = Filter(must=[FieldCondition(key=\"category\", match=MatchValue(value=\"ebooks\"))])\nfor p in client.query_points(\"help\", query=q, query_filter=ebooks, limit=3).points:\n    print(f\"{p.score:.4f}  {p.id}  {p.payload['title']}\")",
      "note": "Um filtro que fica só com os artigos de e-book."
    }
  ],
  "output": "ana@lab:~/emb$ python qd.py\n40 points\n0.4456  18  Returning a gift\n0.4376  15  When your refund arrives\n0.3994  22  Charged twice for one order\n0.3905  33  Refunds for e-books\n0.1633  35  Lending and sharing e-books\n0.1624  37  Audiobooks"
}
```

## Uma nota, de novo

O `score` do Qdrant para uma coleção cosseno é a similaridade, 0,4456 para o artigo do presente, a
mais alta primeiro. São três convenções para a mesma comparação em duas aulas: a distância do Chroma,
um menos a similaridade; o L2 ao quadrado padrão do LanceDB; e a similaridade do Qdrant. Os artigos
voltaram na mesma ordem em todos eles.

**Um ponto é um id, um vetor e um payload.** Payload é a palavra do Qdrant para metadados, qualquer
objeto JSON, e o filtro lê o payload: `must` é uma lista de condições que precisam valer todas, e
`MatchValue` pede um valor exato. O Qdrant também tem `should` e `must_not`, as outras duas metades da
lógica booleana.

## Onde o modo local aparece

Três coisas saíram diferentes do que um servidor faria:

```schooling-example
{
  "language": "python",
  "file": "qd_local.py",
  "parts": [
    {
      "code": "import warnings\nfrom qdrant_client import QdrantClient\nfrom qdrant_client.models import PayloadSchemaType, PointStruct\n\nclient = QdrantClient(path=\"qdrant\")",
      "note": "Abra o mesmo diretório."
    },
    {
      "code": "try:\n    client.upsert(\"help\", points=[PointStruct(id=\"h15\", vector=[0.0] * 384)])\nexcept Exception as e:\n    print(type(e).__name__ + \":\", e)",
      "note": "Um ponto cujo id é uma string."
    },
    {
      "code": "try:\n    client.query_points(\"help\", query=[0.1] * 256, limit=3)\nexcept Exception as e:\n    print(type(e).__name__ + \":\", e)",
      "note": "Uma consulta com um vetor de 256 números numa coleção de 384."
    },
    {
      "code": "with warnings.catch_warnings(record=True) as said:\n    warnings.simplefilter(\"always\")\n    client.create_payload_index(\"help\", field_name=\"category\",\n                                field_schema=PayloadSchemaType.KEYWORD)\nprint(\"warning:\", said[0].message)\nprint(\"indexed vectors:\", client.get_collection(\"help\").indexed_vectors_count)",
      "note": "Peça um índice sobre o campo `category` do payload, guardando o aviso que o Python emite para que ele saia na ordem, e depois pergunte quantos vetores estão indexados."
    }
  ],
  "output": "ana@lab:~/emb$ python qd_local.py\nValueError: Point id h15 is not a valid UUID\nValueError: shapes (40,384) and (256,) not aligned: 384 (dim 1) != 256 (dim 0)\nwarning: Payload indexes have no effect in the local Qdrant. Please use server Qdrant if you need payload indexes.\nindexed vectors: 0"
}
```

**Um id é um inteiro sem sinal ou um UUID**, e o Qdrant faz valer isso: h15 é recusado, e é por isso
que o `qd.py` guardou 15 e levou "h15" no payload. Essa regra é do Qdrant, no servidor e no modo local.

A pergunta de 256 números falhou com a própria mensagem do NumPy sobre formatos que não se alinham.
**Essa mensagem é a implementação aparecendo**: o modo local guarda os vetores num array do NumPy e
multiplica a pergunta por todos eles, então a busca é exata e os erros são do NumPy. `indexed vectors:
0` diz o mesmo pelo outro lado. Um servidor constrói um índice HNSW quando a coleção fica grande o
bastante, e tem as próprias mensagens de erro; nenhum dos dois rodou aqui.

E um índice de payload, que num servidor permite responder a um filtro por um índice em vez de
conferir cada ponto, é aceito e ignorado, com um aviso que diz isso. A aula 17 mostra por que esse
índice importa quando filtros encontram um grafo HNSW. O diretório guarda um arquivo SQLite e dois
arquivos pequenos de controle:

```
ana@lab:~/emb$ find qdrant -type f | sort
qdrant/.lock
qdrant/collection/help/storage.sqlite
qdrant/meta.json
```

## Indo para o servidor

O mesmo programa roda contra um servidor mudando uma linha, a documentada para um servidor escutando
na porta padrão:

```python
client = QdrantClient(url="http://localhost:6333")
```

Isso não rodou, pelo motivo acima. Esse também é o uso honesto do modo local: escrever e testar
contra ele num notebook, sabendo que velocidade, indexação e concorrência só serão verdade no servidor.
