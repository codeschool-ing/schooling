---
title: Os quatro input types do Cohere
version: 1
---

`input_type` é a versão do Cohere para o task type do Google, com quatro valores para texto em vez
de oito. O SDK aceita um quinto, `image`, para transformar imagens em vetor, o que este curso não
faz. A ideia é a mesma que a seção sobre task types desenhou: um modelo treinado de forma
assimétrica transforma um texto em vetor de acordo com o papel dele, então o papel tem de viajar
junto com o texto.

| `input_type` | o texto é | o task type mais próximo no Google |
|---|---|---|
| `search_document` | algo guardado para ser encontrado: um artigo, um trecho | `RETRIEVAL_DOCUMENT` |
| `search_query` | a pergunta para a qual se faz uma busca | `RETRIEVAL_QUERY` |
| `classification` | uma entrada de um classificador, como os tickets da aula 4 | `CLASSIFICATION` |
| `clustering` | um de muitos textos a agrupar sem rótulos | `CLUSTERING` |

**Os dois primeiros são um par, e os outros dois não.** Uma busca indexa com `search_document` e
pergunta com `search_query`, e os dois nunca podem ser trocados. `classification` e `clustering` são
simétricos: todo ticket é o mesmo tipo de texto, então todos recebem o mesmo tipo, o conjunto de
treino e o ticket novo. A aula 10 encontra a versão da Jina para a mesma lista, com o nome de
parâmetro `task`.

## Uma busca, escrita como deve ser

Aqui está a busca da central de ajuda pelo SDK do Cohere: os artigos como `search_document`, as 24
perguntas de clientes como `search_query`, e a medida que a aula 3 constrói, que conta uma pergunta
como respondida quando um dos artigos relevantes dela fica em primeiro, ou entre os três primeiros.
As duas últimas linhas mandam as perguntas com o tipo errado de propósito:

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport numpy as np\nimport cohere\n\nco = cohere.ClientV2(api_key=os.environ[\"CO_API_KEY\"], base_url=os.environ[\"CO_API_URL\"])\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]\nids = [h[\"id\"] for h in help]",
      "note": "Um cliente, os artigos, as perguntas com seus artigos relevantes e os ids na ordem do arquivo."
    },
    {
      "code": "def embed(texts, input_type):\n    r = co.embed(model=\"lab-minilm\", texts=texts, input_type=input_type,\n                 embedding_types=[\"float\"])\n    return np.array(r.embeddings.float_, dtype=np.float32)",
      "note": "Transforma uma lista de textos em vetores com um input type, como vetores float num array do NumPy."
    },
    {
      "code": "def found(D, Q, k):\n    hits = 0\n    for q, row in zip(queries, Q @ D.T):\n        top = [ids[j] for j in np.argsort(-row)[:k]]\n        hits += any(t in q[\"relevant\"] for t in top)\n    return hits",
      "note": "Quantas das 24 perguntas têm um artigo relevante entre os `k` primeiros resultados."
    },
    {
      "code": "D = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help], \"search_document\")\nfor qtype in [\"search_query\", \"search_document\", \"clustering\"]:\n    Q = embed([q[\"text\"] for q in queries], qtype)\n    print(f\"queries as {qtype:16} top 1: {found(D, Q, 1)}/24  top 3: {found(D, Q, 3)}/24\")",
      "note": "Os artigos uma vez, como documentos. As perguntas três vezes: com o tipo certo, depois como documentos, depois como textos a agrupar."
    }
  ],
  "output": "ana@lab:~/emb$ python search.py\nqueries as search_query     top 1: 19/24  top 3: 22/24\nqueries as search_document  top 1: 19/24  top 3: 22/24\nqueries as clustering       top 1: 19/24  top 3: 22/24"
}
```

**As três linhas são iguais, 19 na posição 1 e 22 entre os 3 primeiros.** O labembed transforma
cada pergunta em vetor do mesmo jeito, chegue ela com o tipo que chegar, então as três rodadas
compararam os mesmos vetores. É o resultado esperado neste laboratório e aquele de que se deve desconfiar em qualquer outro
lugar. Contra um modelo assimétrico, a primeira linha é aquela para a
qual ele foi treinado e as outras duas não, e um pipeline descuidado que indexa e pergunta com o
mesmo tipo está errado de um jeito que nenhum erro acusa.

É assim também que você descobre se o tipo importa para um modelo que está escolhendo. Rode a mesma
medida com o par certo e com um errado, nas suas próprias perguntas. Se as duas linhas forem
diferentes, o modelo é assimétrico e o tipo está trabalhando; se forem iguais, como aqui, não está.
De um jeito ou de outro, o código fica com o par certo, porque o próximo modelo pode ser do outro
tipo.

## Guarde o tipo junto com o vetor

Um vetor guardado sem o tipo é um vetor que alguém um dia vai comparar com o tipo errado. A aula 11
dá a cada vetor guardado um registro com metadados ao lado, e é ali que estes ficam: **o modelo, o
input type ou task type e a configuração de dimensão**, quando o provedor tem uma. Três campos são
baratos. Transformar uma coleção inteira em vetores de novo porque ninguém sabe dizer como ela foi
feita não é.
