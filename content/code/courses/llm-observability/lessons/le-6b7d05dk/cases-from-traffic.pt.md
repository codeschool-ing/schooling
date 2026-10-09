---
title: Casos vindos do tráfego
version: 2
---

A melhor fonte de casos novos são as respostas de que alguém já duvidou, a amostra dirigida da aula 9.
O `harvest.py` percorre a semana reproduzida, limpa cada pergunta com os padrões da aula 2, agrupa as
que ficaram idênticas, e conta quantas vezes cada uma foi feita e quantas dessas levaram polegar para
baixo ou uma recusa:

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
ana@dev:~/obs$ python harvest.py
56 different questions after redaction; doubted, of asked:
   8 of   8  Can I place an order by phone?
   7 of   7  right of withdrawal days
   6 of   6  can I read on kindle
   6 of   6  kindle ebooks
   6 of   6  This is Marta Seixas, order [order]: can I still return a book I got 3 weeks ago? My email is [email].
   5 of   8  How long is the statutory right of withdrawal?
   4 of   4  split payment in three
   4 of   4  pickup point how many days
   4 of   4  Hi, I'm Beatriz Costa ([email]). My order [order] has not arrived after 12 working days. Is it lost?
   4 of   4  Is there a student discount?
   4 of   5  Order [order] - I want to return it. Who pays for the return postage? Tiago Moura, [phone]
   3 of   7  when is shipping free
   3 of   3  This is Beatriz Costa, order [order]: can I still return a book I got 3 weeks ago? My email is [email].
   3 of   5  This is Joana Prado, order [order]: can I still return a book I got 3 weeks ago? My email is [email].
   3 of   3  physical shop porto alegre
   3 of   3  Do you have a shop in Porto Alegre where I can pick up books?
```

Três descobertas em dezesseis linhas, nenhuma das quais os vinte e quatro casos poderiam ter mostrado:

- **O direito de arrependimento e o Kindle são postos em dúvida toda vez que aparecem**, em qualquer
  formulação: "right of withdrawal days" sete vezes em sete, "can I read on kindle" e "kindle ebooks"
  seis em seis. A aula 11 achou o porquê do Kindle: o modelo recebe o trecho certo e recusa. O conjunto
  pergunta cada um uma vez, numa frase completa.
- **Os clientes escrevem em palavras-chave.** "split payment in three", "pickup point how many days",
  "when is shipping free": curtas, em minúsculas, sem verbo. As perguntas do conjunto são frases
  completas, e um assistente ajustado nelas é ajustado num jeito de perguntar que os clientes quase não
  usam.
- **As mensagens de pedido são postas em dúvida mais que a mesma pergunta feita sozinha.** "Can I still
  return a book I got 3 weeks ago", embrulhada num nome, num número de pedido e num endereço, é posta em
  dúvida em todas as seis da Marta e nas três da Beatriz. O conjunto não tem nenhum caso com dados
  pessoais, então não consegue ver essa falha.

E um aviso, nas próprias linhas: **os nomes sobrevivem.** A remoção por padrão tira e-mails, telefones e
números de pedido, e "Marta Seixas" não tem nenhuma dessas formas. A aula 2 mostrou o Presidio achando
nomes com um modelo de linguagem; o `harvest.py` não o usa, e uma lista de candidatos como esta é dado de
clientes até alguém tê-la revisado.

## De candidato a caso

Um candidato vira caso quando uma pessoa escreve qual é a resposta certa. O curso escreveu oito a partir
da lista acima, mantendo a formulação e a forma de cada pergunta. Salve-os como
`data/eval-additions.jsonl`:

```json
{"id": "e25", "question": "right of withdrawal days", "gold": ["returns-policy:the-right-of-withdrawal"], "facts": ["seven days", "7 days"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08"}
{"id": "e26", "question": "can I read on kindle", "gold": ["ebooks-and-audiobooks:formats"], "facts": ["cannot open", "cannot be opened", "can't open"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08"}
{"id": "e27", "question": "split payment in three", "gold": ["payments-and-invoices:instalments"], "facts": ["three instalments", "3 instalments"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08"}
{"id": "e28", "question": "pickup point how many days", "gold": ["shipping-and-delivery:pickup-points"], "facts": ["ten days", "10 days"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08"}
{"id": "e29", "question": "This is Ana Teste, order MG-00000001: can I still return a book I got 3 weeks ago? My email is ana.teste@example.com.", "gold": ["returns-policy:the-return-window"], "facts": ["30 days"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08", "synthetic": ["Ana Teste", "MG-00000001", "ana.teste@example.com"]}
{"id": "e30", "question": "Hi, I'm Ana Teste (ana.teste@example.com). My order MG-00000002 has not arrived after 12 working days. Is it lost?", "gold": ["shipping-and-delivery:lost-parcels"], "facts": ["10 working days", "ten working days"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08", "synthetic": ["Ana Teste", "ana.teste@example.com", "MG-00000002"]}
{"id": "e31", "question": "Order MG-00000003 - I want to return it. Who pays for the return postage? Ana Teste, +55 11 5550-0101", "gold": ["returns-policy:how-to-start-a-return"], "facts": ["are free", "prepaid label"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08", "synthetic": ["MG-00000003", "Ana Teste", "+55 11 5550-0101"]}
{"id": "e32", "question": "when is shipping free", "gold": ["shipping-and-delivery:standard-delivery"], "facts": ["R$ 40"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08"}
```

```
ana@dev:~/obs$ wc -l data/eval.jsonl data/eval-additions.jsonl
  24 data/eval.jsonl
   8 data/eval-additions.jsonl
  32 total
ana@dev:~/obs$ grep e31 data/eval-additions.jsonl
{"id": "e31", "question": "Order MG-00000003 - I want to return it. Who pays for the return postage? Ana Teste, +55 11 5550-0101", "gold": ["returns-policy:how-to-start-a-return"], "facts": ["are free", "prepaid label"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08", "synthetic": ["MG-00000003", "Ana Teste", "+55 11 5550-0101"]}
```

**A formulação é do cliente, e os dados não.** A e29, a e30 e a e31 mantêm a forma que fez as mensagens
de pedido falharem: um nome, um número de pedido, um endereço ou um telefone em volta da pergunta. Essa
forma é o objetivo desses casos. Todo valor neles é inventado para o teste, e cada caso diz isso em
`synthetic`, para que a verificação da seção depois da próxima saiba separar um valor de teste declarado
de um de cliente. Os números de pedido são todos zeros e o telefone está numa faixa reservada para
ficção.

**Os fatos e o gold vêm dos documentos**, exatamente como nos primeiros vinte e quatro, e **cada caso
registra de onde veio** (`source`) e quando foi acrescentado. Um conjunto cresce por anos, e "por que
este caso está aqui" é uma pergunta que alguém vai fazer sobre cada um deles.
