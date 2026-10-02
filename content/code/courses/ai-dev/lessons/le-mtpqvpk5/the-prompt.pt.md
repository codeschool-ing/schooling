---
title: Pondo os trechos no prompt
version: 1
---

A recuperação achou os trechos; o prompt decide o que o modelo faz com eles. Três instruções carregam
a maior parte do peso: **responder só a partir destes trechos, dizer de que trecho vem cada frase, e
dizer quando os trechos não têm a resposta.**

```python
def prompt(question, found):
    passages = "\n".join(f"[{c['id']}] {c['text']}" for c, _ in found)
    return ("Answer only from the passages below. Cite the passage id in square brackets after "
            "every sentence that uses it. If the passages do not contain the answer, say so.\n\n"
            f"{passages}\n\nQuestion: {question}")
```

Cada trecho entra com o id entre colchetes, o mesmo id que a resposta deve citar. Aqui está o prompt
inteiro de uma pergunta, exatamente como seria enviado:

```
ana@dev:~/shop$ PYTHONPATH=lab python -c 'import rag; q = "Do you deliver to Portugal?"; print(rag.prompt(q, rag.hybrid_search(q)))'
Answer only from the passages below. Cite the passage id in square brackets after every sentence that uses it. If the passages do not contain the answer, say so.

[shipping.md#3] Shipping. The shop ships only to addresses in Brazil. It does not ship abroad and does not deliver to post office boxes.
[contact.md#1] Contacting support. Support answers by email and chat from 9:00 to 18:00, Monday to Friday, Brasília time, except public holidays. Messages that arrive outside those hours are answered the next working day, in the order they arrived.
[returns.md#3] Returns and refunds. The refund goes back to the original payment method once the item arrives at the warehouse and is checked, which takes up to five working days. Shipping costs are refunded only when the whole order is returned.

Question: Do you deliver to Portugal?
```

**Dois dos três trechos não têm nada a ver com a pergunta.** A busca sempre devolve três, e o prompt os
leva. Isso é normal e quase sempre inofensivo, desde que as instruções digam ao modelo que ele pode
ignorar o que não responde.

## A resposta

O `lab/ask.py` recupera, monta o prompt, pergunta ao `scripted-1` e roda a checagem de citações da
aula 6 seção 08 na resposta. As respostas desta aula foram escritas pelo curso; a recuperação e a
checagem são reais:

```
ana@dev:~/shop$ python lab/ask.py "Do you deliver to Portugal?"
retrieved: shipping.md#3, contact.md#1, returns.md#3
No. "The shop ships only to addresses in Brazil" [shipping.md#3].
citations: every citation checks out
```

## Quando a resposta não está lá

Uma pergunta que o manual não responde ainda recupera três trechos, porque a busca sempre devolve
alguma coisa:

```
ana@dev:~/shop$ python lab/ask.py "Do you sell bicycles?"
retrieved: contact.md#2, payment-errors.md#2, coupons.md#3
The passages do not say whether the shop sells bicycles.
citations: every citation checks out
```

Nenhum dos três fala de produtos, e a resposta diz que os trechos não dizem. **Essa frase é o motivo
da terceira instrução.** Sem ela, a continuação provável de uma pergunta sobre bicicletas no chat de
suporte de uma loja é uma resposta sobre bicicletas, e a aula 1 seção 07 mostrou de onde vêm as
continuações prováveis.

## Escolhas no prompt

- **Trechos antes da pergunta.** O modelo lê os trechos sabendo o que procurar quando a pergunta vem
  no fim, e os trechos formam um prefixo estável que a aula 2 seção 07 consegue pôr em cache quando
  muitas perguntas os dividem.
- **Quantos trechos.** Mais trechos aumentam a chance de a resposta estar entre eles, e acrescentam
  tokens e distrações. Três é pouco; dezenas é comum. Meça (aula 6 seção 09) em vez de chutar.
- **Marcados claramente como dados.** Os trechos são texto de documentos, e um documento pode conter
  frases que parecem instruções. A aula 11 mostra por que isso importa, e por que os trechos são
  marcados como material de onde responder e não como parte das instruções.
