---
title: MongoDB Atlas
version: 1
---

Nem toda loja roda PostgreSQL. Se a Marginalia guardasse o catálogo no MongoDB, o mesmo argumento
valeria: pôr os vetores ao lado dos documentos que eles descrevem. O **MongoDB Atlas**, o serviço
hospedado do MongoDB, faz isso com duas peças que o pgvector junta numa só. O vetor é um campo comum
do documento, um array de números. O índice que o busca é um objeto à parte, um **índice de busca
vetorial** (vector search index), definido ao lado da coleção.

**O Atlas não foi executado nesta aula.** É um serviço hospedado e esta máquina não o alcança, e o
driver `pymongo` não está entre as bibliotecas do laboratório. Os dois programas abaixo foram
escritos a partir da API documentada do MongoDB e não imprimiram nada aqui; nenhuma saída é mostrada
porque nenhuma foi produzida.

## Documentos com um campo de vetor

```schooling-example
{
  "language": "python",
  "file": "atlas_setup.py",
  "parts": [
    {
      "code": "import json\nimport os\nfrom pymongo import MongoClient\nfrom pymongo.operations import SearchIndexModel\nfrom minilm import embed\n\narticles = MongoClient(os.environ[\"ATLAS_URI\"])[\"shop\"][\"articles\"]",
      "note": "`ATLAS_URI` guardaria a string de conexão do cluster. Um banco e uma coleção são criados na primeira vez que algo é gravado neles."
    },
    {
      "code": "help = [json.loads(line) for line in open(\"data/help.jsonl\")]\nV = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])\narticles.insert_many([\n    {\"_id\": h[\"id\"], \"category\": h[\"category\"], \"title\": h[\"title\"],\n     \"body\": h[\"body\"], \"embedding\": v.tolist()}\n    for h, v in zip(help, V)])",
      "note": "Cada artigo vira um documento, com o id como `_id` e o vetor como uma lista simples de 384 números ao lado do título e do corpo. `tolist()` transforma o array do NumPy em números que o driver sabe codificar."
    },
    {
      "code": "articles.create_search_index(SearchIndexModel(\n    name=\"articles_vector\",\n    type=\"vectorSearch\",\n    definition={\"fields\": [\n        {\"type\": \"vector\", \"path\": \"embedding\",\n         \"numDimensions\": 384, \"similarity\": \"cosine\"},\n        {\"type\": \"filter\", \"path\": \"category\"},\n    ]},\n))",
      "note": "O índice de busca vetorial é definido à parte: o campo que guarda o vetor, sua dimensão e a similaridade, e um campo pelo qual as consultas vão filtrar. O Atlas o constrói em segundo plano depois que esta chamada retorna."
    }
  ]
}
```

**A definição do índice traz os mesmos dois fatos que todo banco de vetores fixa na criação**, os que
a aula 11 nomeou: a dimensão e a métrica. `similarity` aceita `euclidean`, `cosine` ou `dotProduct`,
os nomes do Atlas para os três operadores da segunda seção desta aula. Um campo pelo qual uma consulta
vai filtrar também é declarado no índice, com `type: "filter"`, porque o filtro é aplicado dentro da
busca no índice e não depois dela; a aula 17 explica por que isso importa.

O documento em si aceita qualquer array. Nada numa coleção do MongoDB exige que `embedding` tenha
384 números, como `vector(384)` exigia, então quem conhece a dimensão é o índice, que segundo a
documentação do MongoDB impõe `numDimensions` ao indexar e ao consultar. A inserção em si não é
recusada, então uma verificação na hora da escrita tem de ser sua.

## A busca é um estágio de um pipeline

O MongoDB escreve uma consulta de vários passos como um **pipeline de agregação**, uma lista de
estágios em que cada um transforma os documentos que o anterior produziu. A busca vetorial é um
estágio chamado `$vectorSearch`, e ele tem de ser o primeiro:

```schooling-example
{
  "language": "python",
  "file": "atlas_search.py",
  "parts": [
    {
      "code": "import os\nfrom pymongo import MongoClient\nfrom minilm import embed\n\narticles = MongoClient(os.environ[\"ATLAS_URI\"])[\"shop\"][\"articles\"]\nq = embed(\"how do I get my money back\")[0]",
      "note": "A mesma coleção, e a pergunta transformada em vetor pelo mesmo modelo dos artigos guardados, do lado de quem chama."
    },
    {
      "code": "pipeline = [\n    {\"$vectorSearch\": {\n        \"index\": \"articles_vector\",\n        \"path\": \"embedding\",\n        \"queryVector\": q.tolist(),\n        \"numCandidates\": 100,\n        \"limit\": 3,\n        \"filter\": {\"category\": \"returns\"},\n    }},",
      "note": "O primeiro estágio nomeia o índice e o campo, manda o vetor da pergunta, reúne 100 candidatos, fica com 3 e filtra por `category`, que o índice declarou como campo de filtro."
    },
    {
      "code": "    {\"$project\": {\"_id\": 1, \"title\": 1,\n                  \"score\": {\"$meta\": \"vectorSearchScore\"}}},\n]",
      "note": "Um estágio seguinte fica com o id e o título e acrescenta a nota, que o estágio de busca deixa como metadado em cada documento."
    },
    {
      "code": "for doc in articles.aggregate(pipeline):\n    print(doc)",
      "note": "`aggregate` roda o pipeline no servidor e devolve os documentos em ordem de nota."
    }
  ]
}
```

Dois dos campos dele não têm equivalente no SQL desta aula. `numCandidates` é quantos vizinhos a
busca aproximada reúne antes de ficar com os `limit` melhores; ele faz o papel que `hnsw.ef_search`
faz no pgvector, que a aula 16 apresentou, e aqui é escrito em cada consulta em vez de definido para
a sessão. Ele não pode ser menor que `limit`. Usar `exact: true` no lugar dele roda uma busca exata
sobre todos os documentos, o equivalente à varredura sequencial do PostgreSQL.

A nota pede cuidado. **`vectorSearchScore` não é um cosseno.** Para índices `cosine` e `dotProduct`,
a documentação do MongoDB diz que a nota é normalizada como (1 + cosseno) / 2, então ela vai de 0 a 1,
enquanto o `1 - (a <=> b)` do pgvector vai de −1 a 1. Um limiar ajustado num não pode ser copiado
para o outro; converta-o, ou ajuste-o de novo com as notas que o sistema novo devolve.

## Gravado agora, encontrado depois

O índice do pgvector é parte da tabela: o `INSERT` que acrescenta uma linha a acrescenta ao índice
na mesma transação, e a próxima consulta a encontra. **O Atlas mantém seus índices de busca
atualizados a partir da coleção em segundo plano**, e a documentação do MongoDB os chama de
eventualmente consistentes. Um documento gravado há um instante pode ainda não ser encontrado por
`$vectorSearch`. Um índice recém-criado não pode ser consultado até a primeira construção terminar;
o `list_search_indexes()` do driver informa quando ele pode. Um teste que insere e busca logo em
seguida tem de esperar por isso.
