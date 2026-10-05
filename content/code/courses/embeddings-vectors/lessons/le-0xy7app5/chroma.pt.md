---
title: O Chroma num diretório
version: 1
---

Banco de dados de vetores soa como servidor: um processo em algum lugar, uma porta, uma string de
conexão. **O Chroma pode ser isso, e também pode ser uma biblioteca que cuida de um diretório.**
`pip install chromadb` instala um pacote que roda dentro do seu próprio processo Python e grava os
arquivos onde você mandar. O laboratório fixa a versão 1.5.9, e tudo nesta seção e nas duas
seguintes rodou nela.

Aqui vão os 40 artigos da central de ajuda para dentro dele, com o mesmo texto que a aula 3
transformou em vetor: o título e o corpo juntos.

```schooling-example
{
  "language": "python",
  "file": "load.py",
  "parts": [
    {
      "code": "import json\nimport chromadb\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]",
      "note": "Leia os 40 artigos da central de ajuda, como toda aula desde a aula 3."
    },
    {
      "code": "client = chromadb.PersistentClient(path=\"chroma\")\ncol = client.create_collection(\"help\", configuration={\"hnsw\": {\"space\": \"cosine\"}})",
      "note": "`PersistentClient` guarda o banco num diretório, aqui `chroma`, ao lado do programa. A coleção é criada com o espaço cosseno; sem a configuração, o Chroma usa L2, que a seção sobre distâncias mede."
    },
    {
      "code": "col.add(\n    ids=[h[\"id\"] for h in help],\n    documents=[h[\"title\"] + \". \" + h[\"body\"] for h in help],\n    metadatas=[{\"category\": h[\"category\"], \"lang\": h[\"lang\"], \"updated\": h[\"updated\"]}\n               for h in help],\n)\nprint(col.count(), \"records in\", col.name)",
      "note": "Entregue ids, textos e metadados, e nenhum vetor. Sem o argumento `embeddings`, o próprio Chroma passa a função de embedding da coleção sobre os documentos."
    }
  ],
  "output": "ana@lab:~/emb$ python load.py\n40 records in help"
}
```

**O programa não calcula nenhum vetor.** Ele entrega ao Chroma ids, textos e metadados, e o Chroma
passa a sua **função de embedding** sobre os textos. A padrão é o all-MiniLM-L6-v2 num arquivo ONNX,
e isso não é coincidência: a cópia que o `minilm.py` roda desde a aula 1 é a exportação do próprio
Chroma, baixada do bucket do Chroma. Então os vetores que o Chroma guardou deveriam ser os que você
teria feito:

```python
import chromadb
from minilm import embed

col = chromadb.PersistentClient(path="chroma").get_collection("help")
got = col.get(ids=["h15"], include=["documents", "embeddings"])
stored = got["embeddings"][0]
mine = embed(got["documents"][0])[0]
print(stored.shape, abs(stored - mine).max())
```

```
ana@lab:~/emb$ python same.py
(384,) 3.725290298461914e-08
```

A maior diferença entre os 384 números está na oitava casa decimal, que é o que sobra de dois
programas fazendo a mesma conta numa ordem um pouco diferente. Mesmo modelo, mesmos vetores.

Essa comodidade também é uma decisão que alguém tomou por você. A coleção agora depende de um
modelo escolhido pelo padrão do Chroma, e a aula 1 disse o que isso compromete: toda pergunta tem de
virar vetor pelo mesmo modelo, e trocá-lo significa recalcular o vetor de todo registro. Passe
`embedding_function=` ao criar a coleção, ou passe você mesmo `embeddings=`, e a escolha fica sua e
visível no código.

## Perguntando

A pergunta pode ir como texto, porque a coleção conhece a sua função de embedding:

```schooling-example
{
  "language": "python",
  "file": "ask.py",
  "parts": [
    {
      "code": "import chromadb\n\ncol = chromadb.PersistentClient(path=\"chroma\").get_collection(\"help\")\nquestion = \"how do I get my money back\"",
      "note": "Abra a coleção de novo a partir do diretório. A função de embedding foi registrada com ela, então a pergunta pode ir como texto."
    },
    {
      "code": "r = col.query(query_texts=[question], n_results=3)\nfor i, d, doc in zip(r[\"ids\"][0], r[\"distances\"][0], r[\"documents\"][0]):\n    print(f\"{d:.4f}  {i}  {doc[:44]}\")",
      "note": "Os três artigos mais próximos, cada um com a sua distância e o começo do texto."
    },
    {
      "code": "r = col.query(query_texts=[question], n_results=3,\n              where={\"category\": {\"$in\": [\"payments\", \"ebooks\"]}})\nprint(\"payments or e-books:\", r[\"ids\"][0])",
      "note": "`where` filtra pelos metadados. `$in` fica com os registros cuja categoria está na lista."
    },
    {
      "code": "r = col.query(query_texts=[question], n_results=3,\n              where_document={\"$contains\": \"card\"})\nprint(\"text says card:     \", r[\"ids\"][0])",
      "note": "`where_document` filtra pelo próprio texto: `$contains` fica com os registros cujo documento contém a sequência."
    }
  ],
  "output": "ana@lab:~/emb$ python ask.py\n0.5544  h18  Returning a gift. The person who received th\n0.5624  h15  When your refund arrives. We refund within t\n0.6006  h22  Charged twice for one order. When a payment \npayments or e-books: ['h22', 'h33', 'h21']\ntext says card:      ['h18', 'h15', 'h02']"
}
```

O primeiro bloco é a pergunta da aula 1 com a resposta da aula 1: o artigo do presente em primeiro,
o artigo do reembolso em segundo, logo atrás. **Mas os números não são as notas da aula 1.** A aula
1 deu 0,446 a *Returning a gift* (devolver um presente), e aqui ele tem 0,5544, e o número menor é o
melhor. O Chroma devolve **distâncias**, e a seção depois da próxima as desmonta.

As outras duas consultas filtram. `where` lê os metadados, e com as categorias limitadas a
pagamentos e e-books os artigos de reembolso somem: *Refunds for e-books* (h33) sobe para segundo.
`where_document` lê o próprio texto, e `$contains` é um simples teste de substring: todo artigo sem
a sequência é descartado antes de ordenar, então os três que voltaram mencionam um cartão. A aula 17 trata de
como um filtro e o índice trabalham juntos, e de onde isso dá errado.

## Um modelo por coleção, conferido pelo tamanho

Pergunte à mesma coleção com um vetor do WordLlama e o Chroma recusa:

```python
import chromadb
from wordllama import WordLlama

col = chromadb.PersistentClient(path="chroma").get_collection("help")
v = WordLlama.load().embed(["how do I get my money back"], norm=True)
try:
    col.query(query_embeddings=v, n_results=3)
except Exception as e:
    print(type(e).__name__ + ":", e)
```

```
ana@lab:~/emb$ python dims.py
InvalidArgumentError: Collection expecting embedding with dimension of 384, got 256
```

O primeiro `add` fixou a dimensão em 384, e todo vetor depois disso é conferido contra ela. **Essa
conferência é sobre tamanho, não sobre o modelo.** Um outro modelo que também devolva 384 números
seria aceito sem uma palavra e devolveria lixo, que é o aviso da aula 1 sobre vetores de dois
modelos. O banco não tem como saber de onde veio um vetor. Guarde o nome do modelo junto da coleção,
nos metadados dela ou no nome.

## Mudando o que está guardado

`add`, `upsert`, `update` e `delete` são as quatro escritas. Elas nem sempre se comportam como o
nome sugere, e este programa testa cada uma num registro de um artigo que não existe, h41, para que
os quarenta de verdade fiquem intactos:

```schooling-example
{
  "language": "python",
  "file": "change.py",
  "parts": [
    {
      "code": "import chromadb\n\ncol = chromadb.PersistentClient(path=\"chroma\").get_collection(\"help\")\nmeta = {\"category\": \"payments\", \"lang\": \"en\", \"updated\": \"2026-10-05\"}\nshow = lambda: print(col.count(), col.get(ids=[\"h41\"])[\"documents\"])",
      "note": "Um registro para um artigo que ainda não existe, h41, para que os quarenta de verdade fiquem como estavam. `show` imprime a contagem e o texto de h41."
    },
    {
      "code": "col.add(ids=[\"h41\"], documents=[\"Gift cards by email.\"], metadatas=[meta])\nshow()",
      "note": "`add` com um id novo guarda o registro."
    },
    {
      "code": "col.add(ids=[\"h41\"], documents=[\"Gift cards by post.\"], metadatas=[meta])\nshow()",
      "note": "`add` de novo com o mesmo id e outro texto."
    },
    {
      "code": "col.upsert(ids=[\"h41\"], documents=[\"Gift cards by email or by post.\"], metadatas=[meta])\nshow()",
      "note": "`upsert` com o mesmo id."
    },
    {
      "code": "col.update(ids=[\"h99\"], documents=[\"An article nobody wrote.\"])\ncol.delete(ids=[\"h41\"])\nshow()",
      "note": "`update` num id que ninguém guardou, e depois `delete` do registro novo."
    }
  ],
  "output": "ana@lab:~/emb$ python change.py\n41 ['Gift cards by email.']\n41 ['Gift cards by email.']\n41 ['Gift cards by email or by post.']\n40 []"
}
```

**O segundo `add` não mudou nada e não disse nada.** O id já estava lá, então o Chroma manteve o
primeiro texto e seguiu em frente. `upsert` é a escrita que substitui: insere se for novo, sobrescreve
se não for. E o `update` em h99, um id que ninguém guardou, também não levantou erro. Um programa que
reimporta a central de ajuda toda noite com `add` ficaria para sempre com a primeira versão de cada
artigo, e nada na saída dele mostraria isso. Use `upsert` para tudo que possa ser gravado duas vezes.

Um documento alterado ganha um vetor novo: o Chroma roda a função de embedding de novo no `upsert` e
num `update` que traga texto. O texto e o seu vetor não têm como se desencontrar, que é a coerência
que a aula 11 pediu de qualquer armazenamento.
