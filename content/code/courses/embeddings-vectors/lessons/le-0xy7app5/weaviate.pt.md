---
title: Weaviate, um servidor com módulos
version: 1
---

O Weaviate fica entre os outros dois. Ele é de código aberto, então você pode rodá-lo por conta
própria, num contêiner, por exemplo. Também é vendido como serviço hospedado, o Weaviate Cloud. E o
cliente Python tem um modo **embutido** (*embedded*) que baixa um servidor Weaviate e o inicia como
filho do seu programa. Em todas essas formas **o seu programa é cliente de um servidor Weaviate**,
nunca o próprio banco, e essa é a diferença em relação ao `PersistentClient` do Chroma.

Nenhuma das três rodou aqui. O modo embutido busca o servidor no GitHub, que a máquina em que este curso foi gravado não
alcança, e não havia outro servidor a que se conectar. O programa abaixo foi escrito para o pacote
`weaviate-client` e conferido contra as assinaturas da versão 4.23.1 num ambiente separado. Ele
nunca recebeu resposta, então nenhuma saída é mostrada.

```python
import json
import weaviate
from weaviate.classes.config import Configure, DataType, Property, VectorDistances
from weaviate.classes.data import DataObject
from weaviate.classes.query import Filter, MetadataQuery
from weaviate.util import generate_uuid5
from minilm import embed

client = weaviate.connect_to_local()
articles = client.collections.create(
    "Article",
    properties=[Property(name="article_id", data_type=DataType.TEXT),
                Property(name="category", data_type=DataType.TEXT),
                Property(name="title", data_type=DataType.TEXT),
                Property(name="body", data_type=DataType.TEXT)],
    vector_config=Configure.Vectors.self_provided(
        vector_index_config=Configure.VectorIndex.hnsw(
            distance_metric=VectorDistances.COSINE)),
)

help = [json.loads(line) for line in open("data/help.jsonl")]
vectors = embed([h["title"] + ". " + h["body"] for h in help])
articles.data.insert_many([
    DataObject(uuid=generate_uuid5(h["id"]), vector=v.tolist(),
               properties={"article_id": h["id"], "category": h["category"],
                           "title": h["title"], "body": h["body"]})
    for h, v in zip(help, vectors)])

q = embed("how do I get my money back")[0].tolist()
res = articles.query.near_vector(
    near_vector=q, limit=3,
    filters=Filter.by_property("category").equal("returns"),
    return_metadata=MetadataQuery(distance=True))
for o in res.objects:
    print(f"{o.metadata.distance:.4f}  {o.properties['article_id']}  {o.properties['title']}")

res = articles.query.hybrid(query="refund", vector=q, alpha=0.5, limit=3)
client.close()
```

## Uma coleção tem um esquema

**A coleção do Weaviate declara as suas propriedades com tipos**, enquanto os metadados do Chroma
eram qualquer dicionário que você passasse. `article_id` guarda o id da Marginalia porque o
identificador do próprio Weaviate é um UUID: `generate_uuid5("h15")` deriva um a partir do id do
artigo, então h15 recebe o mesmo UUID a cada importação em vez de um novo aleatório.

O lado vetorial da coleção é configurado em `vector_config`, e é aqui que o desenho do Weaviate
aparece. **`self_provided` quer dizer que você traz os vetores**, como `weav.py` faz com o
all-MiniLM-L6-v2 e o índice HNSW medindo a distância cosseno. A alternativa é um **módulo
vetorizador**: `Configure.Vectors.text2vec_openai(model="text-embedding-3-small")` faz o próprio
Weaviate chamar a OpenAI quando objetos são inseridos e quando uma consulta chega como texto, por
`query.near_text(...)`. É a função de embedding do Chroma levada para o servidor, com a chave do
fornecedor guardada no servidor e a conta do fornecedor chegando a cada inserção.

## Distância, de novo

`MetadataQuery(distance=True)` pede a distância de cada resultado, e para um índice cosseno o
Weaviate usa a mesma convenção do Chroma: um menos a similaridade, menor é mais perto. Então h15,
que o Chroma pôs a 0,5624 da pergunta, voltaria com essa distância aqui também, se os vetores forem
os mesmos. Isso sai da definição e não foi medido.

Os filtros são montados com um pequeno construtor,
`Filter.by_property("category").equal("returns")`, em vez de um dicionário, e vários se combinam com
`&` e `|`.

## Busca híbrida numa chamada só

**`query.hybrid` roda uma busca por palavras e uma busca vetorial e funde as duas listas**, que é a
busca híbrida da aula 3 feita pelo banco. O Weaviate mantém um índice de palavras das propriedades
de texto, então `query="refund"` é pontuada com BM25 enquanto `vector=q` é pontuado pela distância.

`alpha` regula o equilíbrio: 1 é uma busca puramente vetorial, 0 uma busca puramente por palavras, e
0,5 pesa as duas igualmente. `fusion_type` escolhe como as duas listas são fundidas, pela posição,
como a fusão por posição recíproca da aula 3, ou pela nota normalizada. O `alpha` certo para a
Marginalia é uma medida, feita do jeito que a aula 3 fez, com as 24 perguntas de `queries.jsonl`, e
não um valor para copiar.
