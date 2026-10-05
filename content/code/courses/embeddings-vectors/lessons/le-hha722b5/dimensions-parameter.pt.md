---
title: O parâmetro dimensions
version: 1
---

O text-embedding-3-small devolve 1.536 números e o text-embedding-3-large, 3.072. É muito para
guardar por pedaço de cada documento, e a aula 18 soma a conta. A resposta da OpenAI, para os
modelos text-embedding-3, é um parâmetro da requisição: **`dimensions`** pede um vetor mais curto,
e a OpenAI descreve o vetor mais curto como uma troca de um pouco de precisão por tamanho.

Isso funciona porque, segundo a OpenAI, esses modelos foram treinados para que as **primeiras**
coordenadas carreguem mais informação, e um prefixo do vetor é um vetor utilizável por si só. Nem
todo modelo é feito assim. Um modelo comum espalha o que aprendeu por todas as coordenadas, e
cortar o vetor dele perde parte disso sem garantia nenhuma sobre qual parte.

O laboratório tem um modelo treinado desse jeito. Os 256 números do WordLlama foram treinados para
que os primeiros 64 ou 128 ainda funcionem sozinhos, e o labembed o serve como `lab-wordllama`, com
`dimensions` de 1 a 256. Então a troca pode ser medida, com as 24 perguntas da aula 3 e suas
respostas:

```schooling-example
{
  "language": "python",
  "file": "dims.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nimport openai\nfrom openai import OpenAI\n\nclient = OpenAI()\nhelp = [json.loads(l) for l in open(\"data/help.jsonl\")]\nqueries = [json.loads(l) for l in open(\"data/queries.jsonl\")]\nids = [h[\"id\"] for h in help]\ndocs = [h[\"title\"] + \". \" + h[\"body\"] for h in help]\nasks = [q[\"text\"] for q in queries]\n\n\ndef embed(texts, **kw):\n    r = client.embeddings.create(model=\"lab-wordllama\", input=texts, **kw)\n    return np.array([d.embedding for d in r.data], dtype=np.float32)\n\n\ndef recall(D, Q):\n    top = np.argsort(-(Q @ D.T), axis=1)[:, :3]\n    at1 = sum(ids[t[0]] in q[\"relevant\"] for t, q in zip(top, queries))\n    at3 = sum(any(ids[i] in q[\"relevant\"] for i in t) for t, q in zip(top, queries))\n    return f\"recall@1 {at1}/{len(queries)}  recall@3 {at3}/{len(queries)}\"",
      "note": "`embed` pede vetores ao `lab-wordllama`, repassando `dimensions` quando informado. `recall` é a medida da aula 3: quantas das 24 perguntas acham um artigo certo em primeiro lugar, e entre os três primeiros."
    },
    {
      "code": "for dims in (256, 128, 64):\n    D, Q = embed(docs, dimensions=dims), embed(asks, dimensions=dims)\n    print(f\"dimensions={dims:<3}  {D[0].nbytes:4} bytes a vector  {recall(D, Q)}\")",
      "note": "Peça à API 256, 128 e 64 números e meça cada tamanho nas mesmas perguntas."
    },
    {
      "code": "D, Q = embed(docs)[:, :64], embed(asks)[:, :64]\nlengths = np.linalg.norm(D, axis=1)\nprint(f\"cut to 64 by hand: lengths {lengths.min():.2f} to {lengths.max():.2f}  {recall(D, Q)}\")\nD /= np.linalg.norm(D, axis=1, keepdims=True)\nQ /= np.linalg.norm(Q, axis=1, keepdims=True)\nprint(f\"cut, then renormalised:           {recall(D, Q)}\")",
      "note": "Agora pegue os 256 completos e guarde você mesmo os 64 primeiros. Os vetores cortados não têm mais comprimento 1; meça-os assim, depois divida cada um pelo comprimento e meça de novo."
    },
    {
      "code": "try:\n    client.embeddings.create(model=\"lab-minilm\", input=\"Tracking a parcel\", dimensions=128)\nexcept openai.BadRequestError as e:\n    print(\"lab-minilm, dimensions=128:\", e.status_code, e.body[\"message\"])",
      "note": "`lab-minilm` é um modelo de tamanho único, como o text-embedding-ada-002."
    }
  ]
}
```

```
ana@lab:~/emb$ python dims.py
dimensions=256  1024 bytes a vector  recall@1 20/24  recall@3 24/24
dimensions=128   512 bytes a vector  recall@1 17/24  recall@3 23/24
dimensions=64    256 bytes a vector  recall@1 20/24  recall@3 21/24
cut to 64 by hand: lengths 0.56 to 0.70  recall@1 19/24  recall@3 20/24
cut, then renormalised:           recall@1 20/24  recall@3 21/24
lab-minilm, dimensions=128: 400 This model does not support specifying dimensions.
```

## O que os números dizem

**Cortar o vetor pela metade custou menos do que a metade sugere.** Com 128 números, cada vetor
ocupa metade dos bytes e acha um artigo certo entre os três primeiros para 23 de 24 perguntas,
contra 24 no tamanho cheio. Com 64, acha 21. A contagem do primeiro lugar oscila mais, e 24
perguntas são poucas o bastante para que uma pergunta valha quatro pontos; leia a coluna como
tendência, não como ranking dos tamanhos.

O que a medição não diz é como o text-embedding-3 se comporta. É outro modelo, em outro texto, e os
números da própria OpenAI são sobre benchmarks, não sobre a sua central de ajuda. O método vale:
rode as suas perguntas em cada tamanho antes de escolher um.

## Cortando você mesmo

`dimensions` é uma comodidade. Você poderia pedir o vetor inteiro e guardar os 64 primeiros números
você mesmo, e a terceira parte do programa faz isso. Os vetores cortados não têm mais comprimento
1: os comprimentos se espalham, como mostra a saída, porque cada texto guardou uma fração diferente
do seu comprimento nos primeiros 64 números. Ordenados pelo produto escalar assim mesmo, vetores
mais compridos ganham por serem compridos, coisa contra a qual a aula 2 alertou, e o resultado fica
uma pergunta abaixo do da API.

**Divida cada vetor cortado pelo seu comprimento** e os números batem exatamente com os da API,
porque foi isso que o servidor fez. Se você encurtar vetores guardados por conta própria,
normalize-os no mesmo passo, e faça o mesmo com cada consulta.

## Um modelo de tamanho único

A última linha é o `lab-minilm` recusando `dimensions`. O all-MiniLM-L6-v2 não foi treinado para ser
cortado, então o laboratório responde do jeito que a OpenAI documenta para o text-embedding-ada-002,
o modelo mais antigo dela: o parâmetro não é aceito. Confira se um modelo aceita `dimensions` antes
de construir em cima disso; um modelo que o ignorasse em silêncio entregaria 1.536 números onde a
sua tabela espera 256.
