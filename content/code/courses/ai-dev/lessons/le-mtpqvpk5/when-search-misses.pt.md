---
title: Quando a busca pelo significado erra
version: 1
---

Embeddings são bons com paráfrase e ruins com sequências exatas. A aula 1 seção 05 previu isso, e o
manual tem o caso que prova: um código de erro. Um cliente cola o que o fechamento de compra disse:

```
ana@dev:~/shop$ python lab/search.py vector "checkout says E1042"
vector: checkout says E1042
    0.542  payment-errors.md#4  Payment errors at checkout. E2003: the billing address does no…
    0.498  payment-errors.md#1  Payment errors at checkout. The checkout shows a code when a p…
    0.492  payment-errors.md#2  Payment errors at checkout. E1001: the card was declined by th…
```

**O trecho sobre o E1042 não está entre os três primeiros.** Os três resultados são sobre erros de
pagamento no fechamento, que é o assunto, e falta justamente o que explica este código. Para um
embedding, `E1042` é uma sequência curta e rara que carrega quase nenhum significado, e os trechos
sobre E2003 e E1001 estão tão perto em significado quanto o certo.

## Buscando por palavras

A técnica mais antiga ordena os trechos pelas palavras que dividem com a pergunta, dando mais peso a
uma palavra quando ela é rara na coleção. A fórmula padrão é a **BM25**, e cabe numa função:

```python
def keyword_search(query, k=3):
    """BM25: a word counts more when it is rare in the handbook and frequent in the chunk."""
    cs, _ = load()
    docs = [words(c["text"]) for c in cs]
    avg = sum(map(len, docs)) / len(docs)
    df = Counter(w for d in docs for w in set(d))
    scores = []
    for d in docs:
        tf = Counter(d)
        s = 0.0
        for w in set(words(query)):
            if w in tf:
                idf = math.log(1 + (len(docs) - df[w] + 0.5) / (df[w] + 0.5))
                s += idf * tf[w] * 2.2 / (tf[w] + 1.2 * (0.25 + 0.75 * len(d) / avg))
        scores.append(s)
    order = sorted(range(len(cs)), key=lambda i: -scores[i])[:k]
    return [(cs[i], scores[i]) for i in order]
```

```
ana@dev:~/shop$ python lab/search.py keyword "checkout says E1042"
keyword: checkout says E1042
    3.943  payment-errors.md#3  Payment errors at checkout. E1042: the payment timed out betwe…
    2.272  payment-errors.md#1  Payment errors at checkout. The checkout shows a code when a p…
    1.777  payment-errors.md#4  Payment errors at checkout. E2003: the billing address does no…
```

**Em primeiro, com folga.** `e1042` aparece num trecho só, então pesa mais que qualquer outra palavra
da pergunta. A busca por palavras tem a fraqueza oposta, porém:

```
ana@dev:~/shop$ python lab/search.py keyword "my parcel never arrived"
keyword: my parcel never arrived
    3.367  shipping.md#4        Shipping. A customer can follow the parcel with the tracking c…
    2.662  contact.md#1         Contacting support. Support answers by email and chat from 9:0…
    2.417  contact.md#2         Contacting support. The target for a first reply is four worki…
ana@dev:~/shop$ python lab/search.py vector "my parcel never arrived"
vector: my parcel never arrived
    0.568  shipping.md#4        Shipping. A customer can follow the parcel with the tracking c…
    0.297  contact.md#2         Contacting support. The target for a first reply is four worki…
    0.254  shipping.md#3        Shipping. The shop ships only to addresses in Brazil. It does …
```

*Never arrived* não divide palavras raras com *no tracking update for ten working days*. A busca
por palavras põe o trecho certo em primeiro só porque *parcel* está nele, e completa o resto com
trechos sobre o horário do suporte que por acaso têm palavras comuns. A busca vetorial põe o mesmo
trecho em primeiro com folga, 0,568, porque lê o significado.

## As duas juntas

A **busca híbrida** roda as duas e junta as duas ordens. A junção usada aqui é a **fusão por posição
recíproca** (reciprocal rank fusion): cada lista dá a um trecho um voto de 1/(60 + posição), e os
votos se somam. Não precisa de ajuste, porque usa só as posições, nunca os dois tipos de nota, que não
se comparam:

```python
def hybrid_search(query, k=3):
    """Reciprocal rank fusion: each list votes 1/(60 + rank) for each chunk it found."""
    votes = Counter()
    by_id = {}
    for found in (vector_search(query, 10), keyword_search(query, 10)):
        for rank, (c, _) in enumerate(found):
            votes[c["id"]] += 1 / (60 + rank)
            by_id[c["id"]] = c
    return [(by_id[i], v) for i, v in votes.most_common(k)]
```

```
ana@dev:~/shop$ python lab/search.py hybrid "checkout says E1042"
hybrid: checkout says E1042
    0.033  payment-errors.md#4  Payment errors at checkout. E2003: the billing address does no…
    0.033  payment-errors.md#1  Payment errors at checkout. The checkout shows a code when a p…
    0.033  payment-errors.md#3  Payment errors at checkout. E1042: the payment timed out betwe…
ana@dev:~/shop$ python lab/search.py hybrid "my parcel never arrived"
hybrid: my parcel never arrived
    0.033  shipping.md#4        Shipping. A customer can follow the parcel with the tracking c…
    0.033  contact.md#2         Contacting support. The target for a first reply is four worki…
    0.032  contact.md#1         Contacting support. Support answers by email and chat from 9:0…
```

O trecho do E1042 volta aos três primeiros, em terceiro, e a pergunta da encomenda ainda acha o trecho
de rastreio em primeiro. **A busca híbrida não sai de graça**, porém, e a aula 6 seção 09 mede onde ela
vai pior que cada uma das partes.
