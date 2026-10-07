---
title: Pondo os trechos no prompt
version: 2
---

A recuperação achou os trechos; o prompt decide o que o modelo faz com eles. Três instruções carregam
a maior parte do peso: **responder só a partir destes trechos, dizer de que trecho vem cada frase, e
dizer quando os trechos não têm a resposta**, numa frase fixa que um programa consiga reconhecer.

```python
NOT_THERE = "The handbook does not say."


def prompt(question, found):
    passages = "\n".join(f"[{c['id']}] {c['text']}" for c, _ in found)
    return ("Answer only from the passages below. Cite the passage id in square brackets after "
            "every sentence. If the passages do not contain the answer, reply with exactly: "
            f"{NOT_THERE}\n\n{passages}\n\nQuestion: {question}")
```

Cada trecho entra com o id entre colchetes, o mesmo id que a resposta deve citar. Aqui está o prompt
inteiro de uma pergunta, exatamente como seria enviado:

```
ana@dev:~/shop$ PYTHONPATH=scratch python -c 'import rag; q = "Do you deliver to Portugal?"; print(rag.prompt(q, rag.hybrid_search(q)))'
Answer only from the passages below. Cite the passage id in square brackets after every sentence. If the passages do not contain the answer, reply with exactly: The handbook does not say.

[shipping.md#3] Shipping. The shop ships only to addresses in Brazil. It does not ship abroad and does not deliver to post office boxes.
[contact.md#1] Contacting support. Support answers by email and chat from 9:00 to 18:00, Monday to Friday, Brasília time, except public holidays. Messages that arrive outside those hours are answered the next working day, in the order they arrived.
[returns.md#3] Returns and refunds. The refund goes back to the original payment method once the item arrives at the warehouse and is checked, which takes up to five working days. Shipping costs are refunded only when the whole order is returned.

Question: Do you deliver to Portugal?
```

**Dois dos três trechos não têm nada a ver com a pergunta.** A busca sempre devolve três, e o prompt
os leva. Isso é normal e quase sempre inofensivo, desde que as instruções digam ao modelo que ele pode
ignorar o que não responde.

## A resposta

O `scratch/ask.py` recupera, monta o prompt, pergunta ao `llama3.2:3b` e roda a checagem de citações
da aula 6 seção 08, na resposta. Ele põe a temperatura em 0, para o modelo pegar o token mais
provável toda vez (aula 1 seção 08) e a mesma pergunta receber quase sempre as mesmas palavras. Esta
versão do SDK da Anthropic não tem o argumento `temperature`, então ele vai em `extra_body`, que é
enviado como está e que o Ollama lê:

```python
import sys

import anthropic

from rag import check_citations, hybrid_search, prompt

question = sys.argv[1]
found = hybrid_search(question)
r = anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=400, extra_body={"temperature": 0},
                                          messages=[{"role": "user", "content": prompt(question, found)}])
answer = r.content[0].text
print("retrieved:", ", ".join(c["id"] for c, _ in found))
print(answer)
problems = check_citations(answer, found)
print("citations:", "; ".join(problems) if problems else "every citation checks out")
```

```
ana@dev:~/shop$ python scratch/ask.py "Do you deliver to Portugal?"
retrieved: shipping.md#3, contact.md#1, returns.md#3
The shop does not ship abroad. [shipping.md#3]
citations: every citation checks out
```

Uma frase, verdadeira, citando o trecho de onde veio. Os outros dois trechos foram ignorados, que é
para isso que serve a primeira instrução.

## Quando a resposta não está lá

Uma pergunta que o manual não responde ainda recupera três trechos, porque a busca sempre devolve
alguma coisa:

```
ana@dev:~/shop$ python scratch/ask.py "Do you sell bicycles?"
retrieved: contact.md#2, payment-errors.md#2, coupons.md#3
The handbook does not say.
citations: every citation checks out
```

Nenhum dos três é sobre produtos, e a resposta é a frase fixa, palavra por palavra. **Essa frase é o
motivo da terceira instrução.** Sem ela, a continuação provável de uma pergunta sobre bicicletas no
chat de suporte de uma loja é uma resposta sobre bicicletas, e a aula 1 seção 11, mostrou de onde
vêm as continuações prováveis. Fazer dela uma frase exata, em vez de "diga quando", é a aula 5, seção
05, de novo: um programa distingue essa resposta de todas as outras comparando duas strings, e o
verificador da próxima seção faz isso.

## Escolhas no prompt

- **Trechos antes da pergunta.** O modelo lê os trechos sabendo o que procurar quando a pergunta vem
  no fim, e os trechos formam um prefixo estável que a aula 2 seção 07 consegue pôr em cache quando
  muitas perguntas os dividem.
- **Quantos trechos.** Mais trechos aumentam a chance de a resposta estar entre eles, e acrescentam
  tokens e distrações. Três é pouco; dezenas é comum. Meça (aula 6 seção 09) em vez de chutar.
- **Marcados claramente como dados.** Os trechos são texto de documentos, e um documento pode conter
  frases que parecem instruções. A aula 11 mostra por que isso importa, e por que os trechos são
  marcados como material de onde responder e não como parte das instruções.
