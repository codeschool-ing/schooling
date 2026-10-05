---
title: Chamando o endpoint embed do Cohere
version: 1
---

O SDK do Cohere, `cohere`, manda a mesma requisição com outras palavras: `texts` onde o Google diz
`contents`, `input_type` onde o Google diz `task_type`. A única diferença que não é de nome é que
**o Cohere não transforma um texto em vetor até você dizer para que ele serve.** O `task_type` do
Google é opcional; o `input_type` do Cohere é obrigatório nos modelos de embedding a partir da
versão 3.

`ClientV2` recebe a chave e, aqui, o endereço do labembed. Contra o Cohere, você deixa `base_url` de
fora e usa um nome de modelo real, como `embed-v4.0`:

```schooling-example
{
  "language": "python",
  "file": "cohere_embed.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport cohere"
    },
    {
      "code": "co = cohere.ClientV2(api_key=os.environ[\"CO_API_KEY\"], base_url=os.environ[\"CO_API_URL\"])",
      "note": "`ClientV2` é o cliente do SDK para a versão 2 da API do Cohere. `base_url` o manda para o labembed."
    },
    {
      "code": "help = [json.loads(line) for line in open(\"data/help.jsonl\")]\nr = co.embed(\n    model=\"lab-minilm\",\n    texts=[h[\"title\"] + \". \" + h[\"body\"] for h in help],\n    input_type=\"search_document\",\n    embedding_types=[\"float\"],\n)\nprint(len(r.embeddings.float_), len(r.embeddings.float_[0]))\nprint(\"billed:\", int(r.meta.billed_units.input_tokens), \"tokens\")",
      "note": "Os 40 artigos numa chamada, cada um como título e corpo, declarados como documentos a serem buscados. Imprima quantos vetores voltaram, o tamanho de cada um e quanto a chamada cobrou."
    },
    {
      "code": "def embed_all(texts, input_type, size=96):\n    out = []\n    for i in range(0, len(texts), size):\n        r = co.embed(model=\"lab-minilm\", texts=texts[i:i + size],\n                     input_type=input_type, embedding_types=[\"float\"])\n        out += r.embeddings.float_\n        print(f\"  call {i // size + 1}: {len(texts[i:i + size])} texts\")\n    return out",
      "note": "Qualquer lista, por maior que seja, em fatias de no máximo 96, uma chamada por fatia. Os vetores são acrescentados na ordem em que os textos foram mandados."
    },
    {
      "code": "tickets = [json.loads(line)[\"text\"] for line in open(\"data/tickets.jsonl\")]\nvectors = embed_all(tickets, \"classification\")\nprint(len(vectors), \"vectors\")",
      "note": "Os 150 tickets, como entradas para um classificador."
    }
  ],
  "output": "ana@lab:~/emb$ python cohere_embed.py\n40 384\nbilled: 2296 tokens\n  call 1: 96 texts\n  call 2: 54 texts\n150 vectors"
}
```

**Os vetores estão em `r.embeddings.float_`, com um sublinhado no fim.** A resposta traz uma lista
por codificação pedida, e `float` é um nome embutido do Python, então o SDK chama esse atributo de
`float_` e os outros de `int8`, `ubinary` e assim por diante. A seção sobre saídas quantizadas pede
várias codificações de uma vez; aqui, `embedding_types=["float"]` pede a comum. `meta.billed_units`
é o que a chamada cobraria: 2.296 tokens pelos 40 artigos, contados com o modelo do próprio
laboratório, então a contagem de um provedor de verdade para o mesmo texto seria outra.

## Noventa e seis textos por vez

Os 40 artigos foram numa chamada só. Os 150 tickets não, porque **o Cohere documenta um limite de 96
textos por chamada**, e o labembed aplica o mesmo número. `embed_all` corta a lista em fatias de 96
e manda uma chamada por fatia, que é o laço de que todo processamento em lote contra este endpoint
precisa. Aqui foram duas chamadas, 96 textos e depois os 54 que sobraram, e os 150 vetores voltaram
em ordem.

Os tickets foram como `classification`, não como `search_document`, porque a aula 4 usa os vetores
dos tickets como atributos de um classificador, e não como coisas a buscar. A próxima seção lista os
quatro input types e quando cada um se aplica.

## Duas recusas, e onde cada uma acontece

```schooling-example
{
  "language": "python",
  "file": "cohere_errors.py",
  "parts": [
    {
      "code": "import os\nimport cohere\n\nco = cohere.ClientV2(api_key=os.environ[\"CO_API_KEY\"], base_url=os.environ[\"CO_API_URL\"])\ntry:\n    co.embed(model=\"lab-minilm\", texts=[\"Audiobooks\"])\nexcept TypeError as e:\n    print(\"TypeError:\", e)\ntry:\n    co.embed(model=\"lab-minilm\", texts=[\"Audiobooks\"] * 97, input_type=\"search_document\")\nexcept cohere.errors.BadRequestError as e:\n    print(e.status_code, e.body)",
      "note": "Uma chamada sem `input_type` e uma chamada com um texto a mais."
    }
  ],
  "output": "ana@lab:~/emb$ python cohere_errors.py\nTypeError: V2Client.embed() missing 1 required keyword-only argument: 'input_type'\n400 {'message': 'too many texts: 97 (the limit is 96)'}"
}
```

**O `input_type` que faltava nunca chegou ao servidor.** O SDK o declara como argumento nomeado
obrigatório, então o Python recusa a chamada com um `TypeError` antes de montar qualquer
requisição. A mesma requisição mandada à mão, sem o SDK, recebe a resposta do próprio servidor, que é
a versão HTTP da mesma regra:

```
ana@lab:~/emb$ cat no-type.json
{"model": "lab-minilm", "texts": ["Audiobooks"]}
ana@lab:~/emb$ curl -s -w " %{http_code}\n" -H "authorization: Bearer $CO_API_KEY" -H "content-type: application/json" -d @no-type.json $CO_API_URL/v2/embed
{"message": "input_type is required for embed models v3 and higher"} 400
```

Os 97 textos chegaram ao servidor, e ele respondeu com um 400 cujo corpo diz qual é o limite. O SDK
levanta isso como `cohere.errors.BadRequestError`, com `status_code` e `body` para ler. Um
processamento em lote que esbarra nisso tem um defeito, não azar: o tamanho da fatia está errado, e
repetir a mesma chamada nunca vai dar certo.
