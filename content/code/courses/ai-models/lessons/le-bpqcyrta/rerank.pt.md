---
title: Rerank, aquilo pelo que a Cohere é conhecida
version: 1
---

Um **reranker** é um modelo com uma tarefa só: dada uma pergunta e uma lista de documentos, pôr os
documentos em ordem de quão bem eles a respondem. Ele não escreve nada. É o segundo estágio da
recuperação, o conserto que a aula 1 seção 07 apontou para fatos ausentes: uma busca rápida acha
cinquenta trechos que podem ser relevantes, e um reranker escolhe os cinco que valem ir para o prompt.
`embeddings-vectors` e `rag`, os dois cursos depois deste, constroem esse caminho; esta seção é sobre o
que o modelo é e como ele é vendido.

A tabela dá preço ao reranker da Cohere numa unidade diferente de todo modelo de chat até aqui:

```
ana@desk:~/desk$ sheet show rerank-v4.0-pro | grep -E "^(input_cost_per_query|max_input|mode|source)"
input_cost_per_query                       0.0025
max_input_tokens                           32768
mode                                       rerank
source                                     https://cohere.com/pricing
```

**US$ 0,0025 por consulta**, não por token: uma busca é cobrada como uma unidade, seja qual for o
número de documentos. A janela dele, 32.768 tokens, limita quanto texto uma consulta consegue ordenar.

## Como é uma requisição de rerank

O `lab/rerank.py` faz a pergunta que o e-mail de um cliente levanta contra quatro linhas da política
da loja, com o SDK da própria Cohere:

```python
import os

import cohere

co = cohere.ClientV2(api_key=os.environ["CO_API_KEY"], base_url=os.environ["CO_API_URL"])
policies = [
    "Orders ship from our warehouse within two working days of payment.",
    "Refunds for damaged or misprinted books are paid to the original card within ten days.",
    "Gift vouchers are sent by e-mail on the date the buyer chooses.",
    "An address can be changed until the order leaves the warehouse.",
]
r = co.rerank(model="rerank-v4.0-pro", query="my book arrived damaged, I want my money back",
              documents=policies, top_n=2)
for hit in r.results:
    print(f"{hit.relevance_score:.4f}  {policies[hit.index]}")
```

```
ana@desk:~/desk$ python-cohere lab/rerank.py
0.1250  Refunds for damaged or misprinted books are paid to the original card within ten days.
0.0000  Orders ship from our warehouse within two working days of payment.
```

**As notas vêm do substituto, e o substituto não é um reranker.** Ele pontua cada documento pela
fração das palavras da pergunta que o documento contém, e foi por isso que "damaged" levou a política
de reembolso ao topo com um oitavo das palavras em comum. Um reranker de verdade lê significado, e
ligaria "I want my money back" a "refunds" sem nenhuma palavra em comum. O que é real é o SDK e o que
ele mandou:

```
ana@desk:~/desk$ wire --headers user-agent,authorization
POST /v2/rerank
user-agent: cohere/7.2.0
authorization: Bearer lab-c…

{
  "model": "rerank-v4.0-pro",
  "query": "my book arrived damaged, I want my money back",
  "documents": [
    "Orders ship from our warehouse within two working days of payment.",
    "Refunds for damaged or misprinted books are paid to the original card within ten days.",
    "Gift vouchers are sent by e-mail on the date the buyer chooses.",
    "An address can be changed until the order leaves the warehouse."
  ],
  "top_n": 2
}
```

A requisição é a interface inteira: um modelo, uma consulta, os documentos como strings simples e
quantos devolver. A resposta dá de cada acerto **o índice na lista que você mandou**
e uma nota de relevância, não o texto, então o programa volta para os próprios documentos, como o
`rerank.py` faz.
