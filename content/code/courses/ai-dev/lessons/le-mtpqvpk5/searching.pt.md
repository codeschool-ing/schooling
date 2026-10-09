---
title: Buscando pelo significado
version: 2
---

Com cada trecho como um vetor normalizado, a busca é uma multiplicação: o vetor da pergunta contra a
matriz dá um cosseno para cada trecho de uma vez, e os primeiros são o resultado.

```python
def vector_search(query, k=3):
    cs, vectors = load()
    scores = vectors @ WordLlama.load().embed([query], norm=True)[0]
    return [(cs[i], float(scores[i])) for i in np.argsort(-scores)[:k]]
```

O `scratch/search.py` roda uma das três buscas desta aula e imprime os três primeiros, com as notas
e o começo de cada trecho:

```python
import sys

from rag import hybrid_search, keyword_search, vector_search

mode, query = sys.argv[1], sys.argv[2]
search = {"vector": vector_search, "keyword": keyword_search, "hybrid": hybrid_search}[mode]
print(f"{mode}: {query}")
for c, score in search(query):
    print(f"  {score:7.3f}  {c['id']:<20} {c['text'][:62]}…")
```

Um cliente perguntando de uma devolução com as próprias palavras:

```
ana@dev:~/shop$ python scratch/search.py vector "Can I send back a mug I bought last week?"
vector: Can I send back a mug I bought last week?
    0.318  returns.md#1         Returns and refunds. A customer may return any item within 30 …
    0.276  returns.md#3         Returns and refunds. The refund goes back to the original paym…
    0.266  warranty.md#3        Warranty. Under warranty the shop replaces the item, or refund…
```

**O trecho certo vem primeiro, e a pergunta quase não divide palavras com ele.** O cliente escreveu
*send back* e *bought last week*; o manual diz *return* e *within 30 days of delivery*. É o caso para
o qual embeddings existem, e o que uma busca por palavras erraria, como a aula 6 seção 06 mostra.

```
ana@dev:~/shop$ python scratch/search.py vector "How long does delivery take to Recife?"
vector: How long does delivery take to Recife?
    0.481  shipping.md#1        Shipping. Orders ship within two working days from the warehou…
    0.327  shipping.md#4        Shipping. A customer can follow the parcel with the tracking c…
    0.299  returns.md#1         Returns and refunds. A customer may return any item within 30 …
```

O manual nunca menciona Recife. Menciona *a entrega dentro do Brasil leva de três a oito dias úteis*,
e esse trecho vem primeiro, com uma vantagem clara: 0,481 contra
0,327 do seguinte.

## Lendo as notas

- **Só a ordem é usada.** A busca pega os três primeiros quaisquer que sejam as notas, o que quer
  dizer que ela sempre devolve três trechos, relevantes ou não. A aula 6 seção 07 mostra o que o prompt
  faz quanto a isso.
- **Um limiar é tentador e frágil.** "Ignore o que ficar abaixo de 0,3" parece sensato nestas duas
  perguntas e teria quase descartado a resposta certa da primeira, com 0,318. As notas mudam com o
  modelo, o tamanho da pergunta e a redação dos trechos. Se usar um, defina-o a partir de uma avaliação
  (aula 6 seção 09), não de dois exemplos.
- **O segundo e o terceiro resultados fazem parte do contexto da resposta.** Aqui são outros trechos
  sobre devolução e entrega, o que não faz mal. Em outra pergunta podem ser trechos que parecem
  relacionados e dizem outra coisa, e o modelo os lê também.
