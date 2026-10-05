---
title: Acompanhando as mudanças
version: 1
---

Uma central de ajuda não vira vetor uma vez só. Artigos são editados, aposentados e criados toda
semana, e cada mudança tem um custo próprio. **Uma edição custa um embedding. Uma exclusão quase não
custa nada na hora e cobra depois**, porque a maioria dos índices vetoriais não remove um vetor
apagado: só o marca. Esta seção mede para onde esse custo vai e o que o limpa.

## Uma edição é uma linha

Quando um artigo muda, o vetor dele precisa mudar junto, ou a busca continua respondendo pelo texto
antigo. Isso é uma chamada ao modelo, cobrada pelos tokens como qualquer outra, e uma atualização na
linha. O perigo não é o custo, é o esquecimento: grave o texto e o vetor na mesma transação, ou pelo
mesmo processo, para que nenhum leitor veja um sem o outro.

## Uma exclusão deixa uma lápide

Um grafo HNSW não pode simplesmente perder um nó, porque outros nós passam por ele. Então o hnswlib
o marca:

```schooling-example
{
  "language": "python",
  "file": "tombstones.py",
  "parts": [
    {
      "code": "import os\nimport hnswlib\nimport numpy as np\nfrom synth import unit_vectors\n\nX = np.load(\"v384.npy\")\nN = len(X)\nh = hnswlib.Index(space=\"ip\", dim=384)\nh.init_index(max_elements=N, M=16, ef_construction=64, allow_replace_deleted=True)\nh.add_items(X, np.arange(N))\nh.save_index(\"live.bin\")\nprint(\"built:   \", h.get_current_count(), \"elements\", os.path.getsize(\"live.bin\"), \"bytes\")",
      "note": "Constrói um índice dos 20.000 vetores com `allow_replace_deleted=True`, que precisa ser decidido na criação do índice, e salva."
    },
    {
      "code": "for i in range(0, N, 2):\n    h.mark_deleted(i)\nh.save_index(\"live.bin\")\nprint(\"deleted: \", h.get_current_count(), \"elements\", os.path.getsize(\"live.bin\"), \"bytes\")\nlabels, _ = h.knn_query(X[:100], k=10)\nprint(\"deleted ids among 1,000 results:\", int((labels % 2 == 0).sum()))",
      "note": "Apaga um vetor sim, outro não. O hnswlib só os marca: a contagem e o arquivo continuam iguais, e as buscas pulam os marcados."
    },
    {
      "code": "new = unit_vectors(5_000, 384, seed=5)\ntry:\n    h.add_items(new, np.arange(N, N + 5_000))\nexcept RuntimeError as e:\n    print(\"add:     \", e)\nh.add_items(new, np.arange(N, N + 5_000), replace_deleted=True)\nh.save_index(\"live.bin\")\nprint(\"replaced:\", h.get_current_count(), \"elements\", os.path.getsize(\"live.bin\"), \"bytes\")",
      "note": "Cinco mil vetores novos. Como elementos novos eles não cabem, porque o índice foi dimensionado para 20.000. Com `replace_deleted=True`, ocupam as vagas dos apagados."
    }
  ]
}
```

```
ana@lab:~/emb$ python tombstones.py
built:    20000 elements 33691896 bytes
deleted:  20000 elements 33691896 bytes
deleted ids among 1,000 results: 0
add:      The number of elements exceeds the specified limit
replaced: 20000 elements 33691896 bytes
```

**Metade dos vetores foi apagada e o índice não diminuiu.** Ele ainda tem 20.000 elementos e o
arquivo continua com 33.691.896 bytes, igual a antes da exclusão. As buscas pulam os marcados, então
nenhum dos 1.000 resultados trouxe um id apagado; mas continuam passando por eles no caminho. E o
espaço também não fica livre para vetores novos, a não ser que o índice tenha sido criado com
`allow_replace_deleted=True` e os novos sejam acrescentados com `replace_deleted=True`. Aí 5.000
vetores novos ocupam 5.000 das vagas vazias e o tamanho não se mexe.

## No pgvector, o VACUUM é lento e o REINDEX encolhe

O PostgreSQL também nunca remove uma linha no `DELETE`. Ele a marca como morta, e o `VACUUM` depois
limpa as linhas mortas da tabela e de todos os índices:

```schooling-example
{
  "language": "sql",
  "file": "vacuum.sql",
  "parts": [
    {
      "code": "SET maintenance_work_mem = '512MB';\nCREATE VIEW space AS\nSELECT (SELECT count(*) FROM v384)              AS \"rows\",\n       pg_relation_size(to_regclass('v384'))      AS heap,\n       pg_relation_size(to_regclass('v384_hnsw')) AS hnsw,\n       pg_relation_size(to_regclass('v384_ivf'))  AS ivf;",
      "note": "Uma view que mostra a contagem de linhas e o tamanho da tabela e dos seus dois índices vetoriais. `to_regclass` procura cada nome toda vez que a view é lida; escrito sem ele, o nome ficaria preso ao índice que existia quando a view foi criada. O `SET` dá à reconstrução do fim espaço para trabalhar em memória."
    },
    {
      "code": "TABLE space;\nDELETE FROM v384 WHERE id % 2 = 0;\nTABLE space;",
      "note": "Apaga metade das linhas e olha de novo."
    },
    {
      "code": "\\timing on\nVACUUM v384;\n\\timing off\nTABLE space;",
      "note": "`VACUUM` é o que recupera linhas mortas no PostgreSQL, e ele também passa por cada índice para tirar as entradas delas."
    },
    {
      "code": "\\timing on\nREINDEX TABLE CONCURRENTLY v384;\n\\timing off\nTABLE space;",
      "note": "`REINDEX ... CONCURRENTLY` constrói cópias novas dos índices da tabela ao lado das antigas e troca, sem bloquear leituras nem escritas."
    }
  ]
}
```

```
ana@lab:~/emb$ psql -f vacuum.sql
SET
CREATE VIEW
 rows  |   heap   |   hnsw   |   ivf    
-------+----------+----------+----------
 20000 | 32768000 | 40968192 | 33284096
(1 row)

DELETE 10000
 rows  |   heap   |   hnsw   |   ivf    
-------+----------+----------+----------
 10000 | 32768000 | 40968192 | 33284096
(1 row)

Timing is on.
VACUUM
Time: 128811.541 ms (02:08.812)
Timing is off.
 rows  |   heap   |   hnsw   |   ivf    
-------+----------+----------+----------
 10000 | 32768000 | 40968192 | 33284096
(1 row)

Timing is on.
REINDEX
Time: 6291.040 ms (00:06.291)
Timing is off.
 rows  |   heap   |   hnsw   |   ivf    
-------+----------+----------+----------
 10000 | 32768000 | 20488192 | 16891904
(1 row)
```

Três leituras, na ordem em que aconteceram.

**Depois da exclusão, nada mudou de tamanho.** 10.000 linhas, e a tabela e os dois índices
exatamente do tamanho que tinham com 20.000.

**O VACUUM levou `128811.541 ms` e ainda assim nada mudou de tamanho.** Ele tirou as linhas mortas
dos índices, e num índice HNSW isso quer dizer consertar as ligações de cada vizinho que apontava
para uma delas, e por isso é lento. O espaço liberado fica dentro dos arquivos, pronto para linhas
novas, e não é devolvido.

**O REINDEX levou `6291.040 ms` e cortou os dois índices pela metade**, para 20.488.192 e 16.891.904
bytes, porque os construiu de novo a partir das 10.000 linhas que sobraram. O `CONCURRENTLY` constrói
as cópias novas ao lado das antigas e troca, então as buscas continuam funcionando o tempo todo;
nesse intervalo, o índice existe duas vezes. A própria documentação do pgvector sugere reindexar
antes de rodar o vacuum num índice HNSW, por esse motivo. A tabela continua com os seus 32.768.000
bytes nos dois casos: o espaço livre dela é reaproveitado pelas próximas inserções.

**Então reconstrua quando uma parte grande tiver sido apagada ou substituída**, e não por
calendário. Um grafo cheio de lápides é maior do que precisa e mais lento de percorrer, e uma
reconstrução custa o que a seção 05 desta aula mediu: uma construção sobre as linhas que restam.

## Versões atrás de um nome

Uma mudança maior, um modelo novo, não pode ser feita no lugar, porque os vetores novos não cabem no
índice antigo. O arranjo de costume é uma **coleção versionada** para cada modelo e um nome estável
que a aplicação consulta, apontado para a versão que estiver no ar. O Qdrant chama esse nome de
alias; aqui ele roda em modo local, dentro do processo Python:

```schooling-example
{
  "language": "python",
  "file": "alias.py",
  "parts": [
    {
      "code": "import json\nfrom qdrant_client import QdrantClient, models\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nhelp = [json.loads(l) for l in open(\"data/help.jsonl\")]\ntexts = [h[\"title\"] + \". \" + h[\"body\"] for h in help]\nwl = WordLlama.load()\nMODEL = {\"help_v1\": embed, \"help_v2\": lambda t: wl.embed(t, norm=True)}\nclient = QdrantClient(path=\"qdrant\")",
      "note": "Duas coleções para os mesmos 40 artigos, uma por modelo, e uma tabela dizendo com qual modelo cada uma foi construída. O Qdrant roda aqui em modo local, dentro do processo Python."
    },
    {
      "code": "def build(name):\n    V = MODEL[name](texts)\n    client.create_collection(name, vectors_config=models.VectorParams(\n        size=V.shape[1], distance=models.Distance.COSINE))\n    client.upsert(name, [models.PointStruct(id=i, vector=v.tolist(), payload={\"id\": h[\"id\"]})\n                         for i, (h, v) in enumerate(zip(help, V))])",
      "note": "Constrói uma coleção: transforma cada artigo em vetor com o modelo daquela coleção e guarda os vetores, dimensionados para o modelo."
    },
    {
      "code": "def point_alias(name):\n    ops = [models.CreateAliasOperation(create_alias=models.CreateAlias(\n        collection_name=name, alias_name=\"help\"))]\n    if behind_alias():\n        ops.insert(0, models.DeleteAliasOperation(delete_alias=models.DeleteAlias(alias_name=\"help\")))\n    client.update_collection_aliases(change_aliases_operations=ops)\n\ndef behind_alias():\n    return {a.alias_name: a.collection_name for a in client.get_aliases().aliases}.get(\"help\")",
      "note": "Aponta o alias `help` para uma coleção. Tirar o alias antigo e criar o novo vão numa só chamada, então nenhuma consulta vê `help` apontando para lugar nenhum. `behind_alias` pergunta para onde ele aponta agora."
    },
    {
      "code": "def search(question, embed_with):\n    hit = client.query_points(\"help\", query=embed_with([question])[0].tolist(), limit=1).points[0]\n    return hit.payload[\"id\"], round(hit.score, 3)\n\nq = \"how do I get my money back\"\nbuild(\"help_v1\"); point_alias(\"help_v1\")\nprint(behind_alias(), search(q, embed))\nbuild(\"help_v2\"); point_alias(\"help_v2\")\nprint(behind_alias(), search(q, MODEL[behind_alias()]))\ntry:\n    print(search(q, embed))\nexcept Exception as e:\n    print(type(e).__name__, str(e)[:90])\nclient.close()",
      "note": "Busca pelo alias, com a função de embedding que quem chama passar. O resto troca o alias de v1 para v2 e busca três vezes."
    }
  ]
}
```

```
ana@lab:~/emb$ python alias.py
help_v1 ('h18', 0.446)
help_v2 ('h15', 0.573)
ValueError shapes (40,256) and (384,) not aligned: 256 (dim 1) != 384 (dim 0)
```

Atrás de `help_v1`, a pergunta que abriu a aula 1 encontra `h18` com 0,446, a nota que `near.py`
imprimiu naquela aula. Atrás de `help_v2`, construída com o WordLlama, ela encontra `h15` com 0,573.
A troca é uma chamada, e as buscas antes dela veem a v1 e as buscas depois veem a v2.

**A última linha é o erro que o alias não pega.** O alias mudou e o código continuou transformando a
pergunta em vetor com o MiniLM. Aqui isso falha de forma barulhenta, porque 384 números não podem ser
comparados com 256; essa mensagem é do NumPy do modo local, e o servidor do Qdrant escreveria a
recusa de outro jeito. Dois modelos com a mesma dimensão não falhariam: devolveriam bobagem com toda
a confiança. **Guarde o nome do modelo junto da versão que ele construiu, e troque o embedding e o
alias na mesma entrega.** No PostgreSQL o mesmo arranjo é uma tabela por versão e uma view, ou uma
troca de nomes dentro de uma transação.
