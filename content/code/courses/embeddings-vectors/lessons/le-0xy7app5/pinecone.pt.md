---
title: Pinecone, rodado por outros
version: 1
---

O Pinecone é um banco de vetores que você usa como serviço. Você cria uma conta e uma chave de API,
e o Pinecone roda os índices; não existe diretório seu guardando-os nem processo seu para iniciar.
**Essa é toda a diferença em relação ao Chroma, e quase tudo o que vem a seguir sai dela.**

Isso também quer dizer que nada nesta seção rodou. A máquina em que este curso foi gravado não tem rota até a API do
Pinecone,
e seria preciso uma conta de qualquer jeito. O programa abaixo foi escrito para o pacote Python
`pinecone` e conferido contra as assinaturas da versão 10.0.0, num ambiente separado. As requisições
dele nunca foram respondidas, então nenhuma saída é mostrada e nenhuma é inventada.

```python
import json
import os
from pinecone import Pinecone, ServerlessSpec
from minilm import embed

pc = Pinecone(api_key=os.environ["PINECONE_API_KEY"])
pc.create_index(name="help", dimension=384, metric="cosine",
                spec=ServerlessSpec(cloud="aws", region="us-east-1"))
index = pc.Index("help")

help = [json.loads(line) for line in open("data/help.jsonl")]
vectors = embed([h["title"] + ". " + h["body"] for h in help])
for lang in ("en", "pt"):
    index.upsert(namespace=lang, vectors=[
        {"id": h["id"], "values": v.tolist(),
         "metadata": {"category": h["category"], "title": h["title"]}}
        for h, v in zip(help, vectors) if h["lang"] == lang])

q = embed("how do I get my money back")[0]
res = index.query(vector=q.tolist(), top_k=3, namespace="en",
                  filter={"category": {"$in": ["returns", "payments"]}},
                  include_metadata=True)
for m in res.matches:
    print(f"{m.score:.4f}  {m.id}  {m.metadata['title']}")
```

## O que o programa pede

**Um índice é criado com a sua dimensão e a sua métrica**, e as duas ficam fixas dali em diante,
como o espaço do Chroma. 384 e `cosine` combinam com o all-MiniLM-L6-v2. `ServerlessSpec` diz onde o
índice mora, uma nuvem e uma região; você escolhe a região porque os dados ficam lá e toda consulta
viaja até ela. A versão 10.0.0 do cliente ainda aceita essa chamada e marca `dimension`, `metric` e
`spec` como obsoletos, em favor de um argumento `schema=` e de um `deployment=`. Confira a forma
atual antes de copiar.

**O Pinecone guarda vetores, não textos.** O programa transforma os artigos em vetores ele mesmo e
manda os números, que é o arranjo comum: não há `documents=` nem função de embedding padrão. O
Pinecone também oferece índices com um modelo de embedding acoplado (`create_index_for_model` no
cliente), que transformam o texto em vetor do lado do Pinecone, mas aí o modelo é um dos deles.

**Um registro é um id, os seus valores e um dicionário de metadados**, e os metadados são o que um
filtro consegue ler. O título vai nos metadados para que um resultado possa ser impresso sem uma
segunda busca. O corpo não vai, e o padrão comum o deixa onde já mora, no banco de dados da própria
Marginalia, ligado pelo id.

**Um namespace é uma partição dentro de um índice.** Os artigos em inglês vão para `en` e os três em
português para `pt`, e uma consulta nomeia exatamente um namespace, então ela nunca vê o outro. É um
jeito barato e rígido de separar idiomas, ou clientes, e a aula 17 volta a isso.

**Uma consulta manda um vetor, `top_k` e um filtro.** A linguagem de filtro segue o estilo do
MongoDB, com operadores como `$eq`, `$in` e `$gte`. O `where` do Chroma usa o mesmo estilo, então o
filtro de `pine.py` e o de `ask.py` se parecem.

## As notas apontam para o outro lado

`m.score` não é uma distância. Para um índice `cosine`, o Pinecone devolve a similaridade, então o
melhor resultado tem a nota **mais alta**, o contrário do Chroma. A própria documentação do cliente
diz isso com todas as letras: `cosine` e `dotproduct` põem as notas mais altas primeiro, `euclidean`
põe as mais baixas primeiro. Levar um limiar de um banco para o outro exige convertê-lo, e a seção
anterior mostrou como um corte dá errado quando ninguém converte.

## Do que você abre mão, e o que ganha

Você não roda nada. Não há diretório para guardar cópia, processo para reiniciar, índice para
reconstruir à mão; o Pinecone escala o índice e o mantém disponível. Em troca, os dados saem das
suas máquinas, toda consulta é uma ida e volta pela rede até a região escolhida, e a conta depende
de quanto você guarda e de quanto lê e grava. A comparação no fim desta aula põe isso ao lado dos
outros dois.
