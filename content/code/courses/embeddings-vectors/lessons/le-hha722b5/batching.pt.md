---
title: Lotes
version: 1
---

Transformar a central de ajuda em vetores com um artigo por requisição seriam quarenta idas e
voltas, cada uma pagando a demora da rede e cada uma contando contra um limite de uso. O endpoint
aceita uma **lista** em `input`, e uma requisição pode levar muitos textos. A pergunta é quantos.

## Os limites, como documentados

A OpenAI documenta dois limites para o endpoint de embeddings: no máximo **2.048 entradas** numa
requisição e no máximo **8.191 tokens** em cada entrada para os modelos text-embedding-3. A
planilha de preços que o curso cita lista os mesmos 8.191 como entrada máxima desses modelos. O
labembed impõe o primeiro e não o segundo, então só o primeiro aparece rodando abaixo; o limite de
tokens fica dito como documentado, sem teste.

Um limite de tokens pede uma contagem de tokens, e os modelos da OpenAI contam com a codificação
`cl100k_base`, que a biblioteca `tiktoken` traz. Contar antes de mandar diz quais textos são longos
demais para uma entrada e quanto a requisição vai custar:

```schooling-example
{
  "language": "python",
  "file": "batch.py",
  "parts": [
    {
      "code": "import json\nimport tiktoken\nfrom openai import OpenAI\n\nclient = OpenAI()\nhelp = [json.loads(l) for l in open(\"data/help.jsonl\")]\ntexts = [h[\"title\"] + \". \" + h[\"body\"] for h in help]",
      "note": "Os 40 artigos da central de ajuda, cada um como título e corpo, o mesmo texto que a aula 3 buscou."
    },
    {
      "code": "enc = tiktoken.get_encoding(\"cl100k_base\")\ncounts = [len(enc.encode(t)) for t in texts]\nprint(\"cl100k_base tokens:\", sum(counts), \" longest article:\", max(counts))",
      "note": "Conte os tokens do jeito que os modelos text-embedding-3 da OpenAI contam, com a codificação `cl100k_base` do tiktoken."
    },
    {
      "code": "def embed_all(texts, size=16):\n    vectors = []\n    for start in range(0, len(texts), size):\n        r = client.embeddings.create(model=\"lab-minilm\", input=texts[start:start + size])\n        vectors += [d.embedding for d in sorted(r.data, key=lambda d: d.index)]\n    return vectors",
      "note": "Mande os textos em fatias de 16 e ponha os vetores de cada fatia de volta na ordem do `index` antes de juntá-los à lista."
    },
    {
      "code": "vectors = embed_all(texts)\nprint(len(vectors), \"vectors from\", len(texts), \"articles\")",
      "note": "Quarenta textos em fatias de 16 são três requisições."
    }
  ]
}
```

```
ana@lab:~/emb$ python batch.py
cl100k_base tokens: 2205  longest article: 75
40 vectors from 40 articles
ana@lab:~/emb$ jq -c '{inputs, tokens, encoding_format}' labembed.jsonl | tail -n 3
{"inputs":16,"tokens":884,"encoding_format":"base64"}
{"inputs":16,"tokens":858,"encoding_format":"base64"}
{"inputs":8,"tokens":554,"encoding_format":"base64"}
```

O artigo mais longo fica muito abaixo de 8.191 tokens, então cada artigo cabe inteiro numa entrada.
A aula 3 cortou um texto longo em pedaços pela qualidade da busca; um texto acima do limite de
tokens precisa ser cortado por um motivo mais simples: a API o recusa.

O registro mostra as três requisições: 16 textos, 16, depois os 8 últimos. A coluna `tokens` é a
contagem do labembed, feita com **o tokenizador do próprio modelo do laboratório**, então ela não
soma o total de `cl100k_base` de cima. Essa diferença é real e vale guardar: o número que um
provedor cobra é contado com o tokenizador do provedor, então estime uma conta com o contador do
provedor e confira depois com `usage`.

## Duas recusas que vale conhecer

```python
import openai
from openai import OpenAI

client = OpenAI()
tries = [
    ("an empty string", ["Tracking a parcel", ""]),
    ("2,049 inputs", ["Tracking a parcel"] * 2049),
]
for name, batch in tries:
    try:
        client.embeddings.create(model="lab-minilm", input=batch)
    except openai.BadRequestError as e:
        print(f"{name}: {e.status_code} {e.body['message']}")
```

```
ana@lab:~/emb$ python limits.py
an empty string: 400 'input' cannot contain an empty string.
2,049 inputs: 400 'input' must have at most 2048 items, got 2049.
```

**Uma string vazia derruba o lote inteiro**, não só a posição dela. Num processo que transforma em
vetor o que um banco de dados devolver, uma linha em branco basta para perder os outros 2.047
textos da requisição, então filtre os textos vazios antes de mandar. E uma lista maior que o limite
é recusada de uma vez, não encurtada; o fatiamento em `embed_all` é a solução.

## Escolhendo o tamanho da fatia

Esta aula usa dezesseis para que a central de ajuda precise de mais de uma requisição. Na
prática, três coisas limitam a fatia: o limite de 2.048 entradas, os tokens da requisição e quanto
trabalho você aceita repetir quando uma requisição falha. Os tokens contam porque os limites de uso
medem tokens por minuto, além de requisições. Seja qual for o tamanho, mantenha a ordenação por `index`
dentro do laço, onde as posições de cada fatia ainda significam alguma coisa.
