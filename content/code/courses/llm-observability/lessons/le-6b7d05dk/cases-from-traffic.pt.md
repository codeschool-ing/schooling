---
title: Casos a partir do tráfego
version: 1
---

A melhor fonte de casos novos são as respostas de que alguém já duvidou, a amostra dirigida da aula 9.
O `harvest.py` percorre a semana reproduzida, tira os dados de cada pergunta com os padrões da aula 2,
junta as que ficaram idênticas, e conta quantas vezes cada uma foi feita e quantas dessas receberam um
polegar para baixo ou uma recusa:

```python
"""harvest.py: candidate cases for the evaluation set: every question of the week somebody doubted,
redacted, grouped and counted. Doubted means a thumb down, or a refusal."""
import json
from collections import Counter

import checks
import redact

thumbs = {f["trace"]: f["value"] for f in map(json.loads, open("feedback.jsonl")) if f["kind"] == "thumbs"}
asked, doubted = Counter(), Counter()
for s in map(json.loads, open("spans.jsonl")):
    a = s["attributes"]
    if s["name"] != "ask" or a["app.feature"] == "summary":
        continue
    text = redact.redact(a["app.question"])
    asked[text] += 1
    doubted[text] += thumbs.get(s["trace"]) == "down" or checks.is_refusal(a["app.reply"])
print(f"{len(asked)} different questions after redaction; doubted, of asked:")
for text, n in doubted.most_common(16):
    print(f"{n:4} of {asked[text]:3}  {text}")
```

```
ana@lab:~/obs$ python harvest.py
59 different questions after redaction; doubted, of asked:
  53 of  53  what does next day delivery cost
  20 of  55  My parcel [order] still hasn't arrived, two weeks now. You can call me on [phone]. When is it considered lost?
  18 of  18  Order [order] - I want to return it. Who pays for the return postage? Tiago Moura, [phone]
  17 of  31  when is shipping free
  15 of  47  express shipping price
  15 of  15  Which carrier do you use in Portugal?
  14 of  14  Can I place an order by phone?
  14 of  14  Hi, I'm Joana Prado ([email]). My order [order] has not arrived after 12 working days. Is it lost?
  14 of  14  carrier portugal
  14 of  14  Order [order] - I want to return it. Who pays for the return postage? Joana Prado, [phone]
  13 of  13  pay in instalments
  12 of  12  Order [order] - I want to return it. Who pays for the return postage? Rafael Lima, [phone]
  12 of  12  order by telephone
  11 of  11  Hi, I'm Tiago Moura ([email]). My order [order] has not arrived after 12 working days. Is it lost?
  11 of  11  physical shop porto alegre
  11 of  60  return window for books
```

Três achados em dezesseis linhas, e nenhum deles os trinta casos poderiam ter mostrado:

- **"what does next day delivery cost" foi posta em dúvida em todas as suas 53 vezes.** O conjunto
  pergunta "How much is express delivery?", que recebe uma resposta, ainda que errada (a aula 10 a
  leu). Os clientes também dizem "next day", e o assistente não liga uma coisa à outra. É a pergunta
  mais posta em dúvida da semana.
- **Os clientes escrevem com palavras-chave.** "express shipping price", "when is shipping free",
  "carrier portugal": curtas, em minúsculas, sem verbo. As perguntas do conjunto são frases inteiras,
  e um assistente ajustado nelas está ajustado num jeito de perguntar que os clientes quase não usam.
- **As mensagens sobre pedidos falham muito mais do que a mesma pergunta feita sozinha**, como a aula 5
  rastreou: o nome, o endereço e o número do pedido puxam a busca para longe dos documentos. O conjunto
  não tem nenhum caso com dados pessoais, então não consegue ver essa falha.

E um aviso, nas próprias linhas: **os nomes sobrevivem.** A remoção por padrões tira endereços de
e-mail, telefones e números de pedido, e "Tiago Moura" não tem nenhum desses formatos. A aula 2 mostrou
o Presidio achando nomes com um modelo de linguagem; o harvest.py não o usou, e uma lista de candidatos
como esta é dado de clientes até alguém passar por ela.

## De candidato a caso

Um candidato vira caso quando uma pessoa escreve qual é a resposta certa. O curso escreveu doze, em
`data/eval-additions.jsonl`, mantendo a redação e o formato de cada pergunta:

```
ana@lab:~/obs$ wc -l data/eval.jsonl data/eval-additions.jsonl
  30 data/eval.jsonl
  12 data/eval-additions.jsonl
  42 total
ana@lab:~/obs$ grep e39 data/eval-additions.jsonl
{"id": "e39", "question": "Order MG-00000002 - I want to return it. Who pays for the return postage? Ana Teste, +55 11 5550-0101", "gold": [["returns-policy", "How to start a return"]], "facts": ["Returns are free"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-06", "synthetic": ["MG-00000002", "Ana Teste", "+55 11 5550-0101"]}
```

**A redação é do cliente, e os dados não.** O e39 mantém o formato que fez as mensagens sobre pedidos
falharem, um número de pedido, um nome e um telefone em volta da pergunta, porque esse formato é o
objetivo do caso. Todo valor nele foi inventado para o teste, e o caso diz isso em `synthetic`, para que
a verificação de duas seções adiante saiba distinguir um valor de teste declarado de um de cliente.

**Os fatos e o gold vêm dos documentos**, exatamente como nos trinta primeiros, e **cada caso registra
de onde veio** (`source`) e quando foi acrescentado. Um conjunto cresce por anos, e "por que este caso
está aqui" é uma pergunta que alguém vai fazer sobre cada um deles.
