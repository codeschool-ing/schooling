---
title: Medindo a recuperação
version: 1
---

Uma resposta só pode ser tão boa quanto os trechos que recebeu. Então a primeira coisa a medir num
sistema de RAG não são as respostas, mas a busca: **para cada pergunta, o trecho que a responde está
entre os recuperados?** Essa fração é o **recall em k**, em que k é quantos trechos o prompt leva.

## Um conjunto rotulado de doze

A ana escreve doze perguntas com as palavras que os clientes usam, cada uma com o id do trecho que a
responde, e roda as três buscas sobre elas:

```python
"""Recall at 3: for each question, is the passage that answers it among the three retrieved?"""
from rag import hybrid_search, keyword_search, vector_search

CASES = [
    ("Can I send back a mug I bought last week?", "returns.md#1"),
    ("How long does delivery take to Recife?", "shipping.md#1"),
    ("checkout says E1042", "payment-errors.md#3"),
    ("card declined with E1001", "payment-errors.md#2"),
    ("my parcel never arrived", "shipping.md#4"),
    ("Do you deliver to Portugal?", "shipping.md#3"),
    ("Is shipping free if my order is 210 with a coupon?", "shipping.md#2"),
    ("Is the WELCOME10 coupon still valid in December?", "coupons.md#1"),
    ("Can I use two coupons on one order?", "coupons.md#2"),
    ("how do I change my password", "account.md#2"),
    ("is the hand-painted mug ok in the dishwasher", "products.md#1"),
    ("when is support open", "contact.md#1"),
]
for name, search in [("vector", vector_search), ("keyword", keyword_search), ("hybrid", hybrid_search)]:
    missed = [q for q, want in CASES if want not in [c["id"] for c, _ in search(q)]]
    print(f"{name:8} recall@3 = {len(CASES) - len(missed)}/{len(CASES)}")
    for q in missed:
        print(f"           missed: {q}")
```

```
ana@dev:~/shop$ python scratch/eval_retrieval.py
vector   recall@3 = 11/12
           missed: checkout says E1042
keyword  recall@3 = 10/12
           missed: Can I send back a mug I bought last week?
           missed: How long does delivery take to Recife?
hybrid   recall@3 = 11/12
           missed: Can I send back a mug I bought last week?
```

Três resultados, e cada um ensina alguma coisa:

- **Busca vetorial, 11 de 12**, errando só o código de erro, como a aula 6 seção 06 achou.
- **Busca por palavras, 10 de 12**, errando as duas perguntas escritas com palavras que o manual não
  usa.
- **Busca híbrida, 11 de 12**, e a que ela erra é uma pergunta que **a busca vetorial acertou**. A
  fusão achou o E1042, e em troca empurrou *send back a mug* para fora dos três primeiros, porque a
  busca por palavras pôs esse trecho lá embaixo e os votos somaram menos que os de outros três.

**A busca híbrida não venceu a vetorial aqui; trocou um erro por outro.** Num manual diferente, com
mais códigos e referências de produto, a troca iria para o outro lado. É esse o motivo de medir: a
decisão é tomada nas suas perguntas, não na reputação de uma técnica.

## Mantendo o conjunto útil

- **Perguntas de usuários reais**, com as palavras deles, inclusive erros de digitação e mensagens de
  erro coladas. Um conjunto escrito por quem escreveu o manual usa as palavras do manual, e toda busca
  vai bem nele.
- **Acrescente todo erro relatado em produção.** Um cliente que recebeu a resposta errada é um caso
  rotulado.
- **Rode a cada mudança** no corte, no modelo de embedding, no k ou na busca, como a aula 5 seção 09
  roda a avaliação do prompt. Doze casos rodam em segundos; algumas centenas também.
- **Meça as respostas à parte.** O recall diz que o trecho estava disponível. Se a resposta o usou
  direito é a checagem de citações da aula 6 seção 08 mais uma pessoa lendo uma amostra.
