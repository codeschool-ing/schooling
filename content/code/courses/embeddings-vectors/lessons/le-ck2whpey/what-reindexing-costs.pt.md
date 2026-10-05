---
title: O que custa reindexar
version: 1
---

A aula 1 disse que vetores de dois modelos não podem ser comparados, e a aula 10 traçou o plano de
migração que vem disso. A consequência para o orçamento é direta: **trocar de modelo quer dizer
transformar todos os documentos em vetores de novo e construir todos os índices de novo**, e por um
tempo manter os dois. As equipes costumam calcular só a conta de tokens. São três contas, e em
textos curtos a de tokens é a menor.

## Os tokens

Os preços deste curso vêm de um só lugar, a tabela do LiteLLM no commit b9e71e990aed, que o
`prices.py` lê; as páginas dos próprios provedores estavam fora de alcance na máquina em que isto
foi gravado.

```
ana@lab:~/emb$ python3 prices.py
LiteLLM price sheet at commit b9e71e990aed, USD per million input tokens
model                          provider                      USD/MTok   batch  dims  max in
text-embedding-3-small         openai                           0.020   0.010  1536    8191
text-embedding-3-large         openai                           0.130   0.065  3072    8191
text-embedding-ada-002         openai                           0.100       -  1536    8191
gemini/gemini-embedding-001    gemini                           0.150       -  3072    2048
cohere/embed-v4.0              cohere                           0.120       -  1536  128000
embed-english-v3.0             cohere                           0.100       -     -     512
embed-multilingual-v3.0        cohere                           0.100       -     -     512
voyage/voyage-3.5              voyage                           0.060       -     -   32000
voyage/voyage-3.5-lite         voyage                           0.020       -     -   32000
mistral/mistral-embed          mistral                          0.100       -     -    8192
ana@lab:~/emb$ python3 prices.py --json > prices.json
```

O segundo comando grava as mesmas linhas em JSON para um programa ler. O `reembed.py` conta os tokens
de todo texto do laboratório que não é pergunta, mede o tempo do modelo local sobre eles e escala as
duas coisas para um milhão:

```schooling-example
{
  "language": "python",
  "file": "reembed.py",
  "parts": [
    {
      "code": "import json\nimport time\nimport tiktoken\nfrom minilm import embed\n\nrows = lambda f: [json.loads(l) for l in open(f\"data/{f}.jsonl\")]\ntexts = ([h[\"title\"] + \". \" + h[\"body\"] for h in rows(\"help\")]\n         + [b[\"title\"] + \". \" + b[\"blurb\"] for b in rows(\"books\")]\n         + [t[\"text\"] for t in rows(\"tickets\")])\nenc = tiktoken.get_encoding(\"cl100k_base\")\ntokens = sum(len(enc.encode(t)) for t in texts)\nprint(f\"{len(texts)} texts, {tokens:,} tokens, {tokens / len(texts):.1f} per text\")",
      "note": "Todo texto de `data/` que não é pergunta, contado em tokens do cl100k_base, a codificação pela qual os modelos text-embedding-3 da OpenAI são cobrados."
    },
    {
      "code": "t = time.perf_counter()\nembed(texts)\ntook = time.perf_counter() - t\nrate = len(texts) / took\nprint(f\"all-MiniLM-L6-v2 on one core: {took:.2f} s, {rate:.0f} texts per second\")",
      "note": "Transforma todos em vetores uma vez com o modelo local e mede o tempo. `minilm.py` roda numa só thread, então essa é a taxa de um núcleo."
    },
    {
      "code": "N = 1_000_000\nper = tokens / len(texts)\nprint(f\"{N:,} texts like these = {N * per:,.0f} tokens\")\nprint(f\"  here, one core:  {N / rate / 3600:5.1f} hours\")\nfor p in json.load(open(\"prices.json\")):\n    if p[\"model\"].startswith((\"text-embedding-3\", \"gemini\", \"cohere\", \"voyage\")):\n        print(f\"  {p['model']:28} ${N * per / 1e6 * p['usd_per_mtok']:8.2f}\")",
      "note": "Escala para um milhão de textos do mesmo tamanho médio: horas neste núcleo e dólares em cada modelo com preço na tabela."
    }
  ]
}
```

```
ana@lab:~/emb$ python reembed.py
250 texts, 5,684 tokens, 22.7 per text
all-MiniLM-L6-v2 on one core: 2.48 s, 101 texts per second
1,000,000 texts like these = 22,736,000 tokens
  here, one core:    2.8 hours
  text-embedding-3-small       $    0.45
  text-embedding-3-large       $    2.96
  gemini/gemini-embedding-001  $    3.41
  cohere/embed-v4.0            $    2.73
  voyage/voyage-3.5            $    1.36
  voyage/voyage-3.5-lite       $    0.45
```

**Um milhão de textos como estes custam US$ 0,45 no text-embedding-3-small e US$ 3,41 no
gemini-embedding-001.** Estes textos são curtos, 22,7 tokens em média, então a conta acompanha o
tamanho médio dos seus: trechos dez vezes mais longos custam dez vezes mais. Mesmo assim, a ordem de
grandeza é de dólares por milhão, e **raramente é a conta de tokens que torna uma migração cara.**

O modelo local não tem conta e tem um relógio no lugar: 101 textos por segundo num núcleo, 2,8 horas
para o milhão. Isso é um núcleo desta máquina; mais núcleos dividem o tempo, e textos mais longos o
multiplicam.

## O índice

Depois os vetores precisam entrar num índice novo, e um índice HNSW é construído uma inserção de
cada vez:

```python
import time
import hnswlib
import numpy as np
from synth import unit_vectors

for n in (5_000, 10_000, 20_000, 40_000):
    X = unit_vectors(n, 384, seed=n)
    t = time.perf_counter()
    h = hnswlib.Index(space="ip", dim=384)
    h.init_index(max_elements=n, M=16, ef_construction=64)
    h.add_items(X, np.arange(n))
    took = time.perf_counter() - t
    print(f"{n:>7,} vectors  {took:6.2f} s  {took / n * 1e6:6.1f} µs per vector")
```

```
ana@lab:~/emb$ nproc
4
ana@lab:~/emb$ python rebuild.py
  5,000 vectors    0.54 s   108.2 µs per vector
 10,000 vectors    1.08 s   107.6 µs per vector
 20,000 vectors    1.87 s    93.3 µs per vector
 40,000 vectors    4.76 s   119.0 µs per vector
```

Oito vezes mais vetores levaram 4,76 s contra 0,54 s, então **a construção cresce pelo menos na
proporção da quantidade**, porque cada inserção busca num grafo maior do que a anterior encontrou. A
coluna por vetor oscila de uma execução para outra numa máquina ocupada com outras coisas, então leia
os totais. No pgvector a mesma construção sobre 20.000 linhas levou `7385.761 ms` com 384 dimensões e
`46553.018 ms` com 1536 (seção 03 desta aula); a dimensão multiplica o custo de cada comparação que a
construção faz.

## Os dois ao mesmo tempo

Uma migração que não para a busca mantém os vetores antigos e o índice deles servindo enquanto os
novos são escritos e construídos, e só então muda as leituras. Nessa janela **você guarda os dois
conjuntos**: as linhas e o índice do modelo antigo mais os do novo, na dimensão do novo. Passar de
384 para 1536 dimensões no pgvector, com HNSW, leva uma linha de 1.676 + 2.048 bytes para 8.371 + 8.192,
e durante a mudança você guarda a soma. A seção 07 desta aula calcula uma mudança assim para um
acervo maior.

Então reindexar custa tokens ou horas de CPU, o tempo de construir o índice novo e um período de
armazenamento em dobro. Das três, a última é a que pede planejamento de capacidade, porque chega de
uma vez e precisa caber ao lado de um sistema que continua servindo.
