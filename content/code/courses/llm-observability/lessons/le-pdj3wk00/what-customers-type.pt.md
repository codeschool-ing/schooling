---
title: O que os clientes digitam
version: 1
---

Antes de decidir o que remover, conte o que chega. O `scan.py` passa cada pedido da semana pelo
`redact.found()`, a metade que conta da remoção que esta aula constrói, e informa quantos, em cada
funcionalidade, carregam algo que ela tiraria:

```python
"""scan.py: a week of what customers typed, and how much of it redact() would take out."""
import json
from collections import Counter

import redact

rows = [json.loads(line) for line in open("data/traffic.jsonl")]
total, hit, found = Counter(), Counter(), Counter()
for r in rows:
    total[r["feature"]] += 1
    f = redact.found(r["text"])
    hit[r["feature"]] += bool(f)
    found.update(f)
print("feature  requests  with something to redact")
for feature in total:
    print(f"{feature:8} {total[feature]:9} {hit[feature]:9}")
print("found:", dict(found))
```

```
ana@lab:~/obs$ python scan.py
feature  requests  with something to redact
help           786         0
summary        124       124
order          217       217
found: {'order': 341, 'email': 107, 'phone': 110}
```

Três funcionalidades, três respostas diferentes. **Nenhum dos 786 pedidos de `help`** traz um
endereço, um número ou um pedido: são perguntas sobre regras, as mesmas poucas dezenas de formulações
repetidas. **Todos os 217 pedidos de `order`** trazem, porque um cliente perguntando sobre o próprio
pedido identifica o pedido e muitas vezes a si mesmo. E **todos os 124 pedidos de `summary`** trazem,
porque uma conversa de atendimento sendo resumida está cheia de números de pedido.

O tráfego é gerado, e as proporções reais vão ser outras. A forma não: dados pessoais não se espalham
por igual num produto. Eles se concentram nas funcionalidades que tratam de uma pessoa em particular,
e uma política que trata todo trace igual ou protege demais as perguntas sobre vale-presente ou
protege de menos as perguntas sobre a encomenda perdida de alguém.

```
ana@lab:~/obs$ grep -m 3 "\"order\"" data/traffic.jsonl
{"id": "r0007", "at": "2026-09-28T03:55:08", "user": "u023", "session": "s0007", "feature": "order", "topic": 1, "text": "This is Marta Seixas, order MG-80660491: can I still return a book I got 3 weeks ago? My email is marta.s@example.org."}
{"id": "r0008", "at": "2026-09-28T04:34:28", "user": "u087", "session": "s0008", "feature": "order", "topic": 9, "text": "Hi, I'm Joana Prado (joana.prado@example.com). My order MG-16887804 has not arrived after 12 working days. Is it lost?"}
{"id": "r0009", "at": "2026-09-28T05:00:13", "user": "u062", "session": "s0009", "feature": "order", "topic": 9, "text": "My parcel MG-63273039 still hasn't arrived, two weeks now. You can call me on +55 21 5550-0187. When is it considered lost?"}
```

Leia a segunda e a terceira. Um nome e um endereço de e-mail numa, um número de telefone na outra,
cada um ao lado de um número de pedido, e cada um numa frase que um modelo, e portanto um trace,
recebe inteira. Conte mais uma vez nessa saída o que o `scan.py` não consegue contar: **os nomes**.
Marta Seixas, Joana Prado. Um padrão acha um endereço porque endereços têm forma. Um nome não tem, e a
seção sobre o que os padrões deixam passar volta a isso.

## Onde o texto vai parar, depois que chega

Seguindo uma pergunta sobre pedido pelo assistente, as suas palavras chegam:

- ao atributo `app.question` do span raiz, que o assistente escreve;
- ao prompt enviado ao fornecedor, que então passa a ser regido pelos termos do próprio fornecedor;
- a qualquer span que uma biblioteca de instrumentação escreva para a chamada, e a aula 1 mostrou que
  ela guarda o prompt inteiro por padrão;
- à resposta, se o modelo repetir qualquer parte, e daí ao atributo `app.reply`;
- e a onde quer que os spans vão depois: o arquivo, um serviço de rastreamento, os backups dele.

As duas próximas seções tratam do primeiro e do terceiro. O lado do fornecedor é uma questão de
contrato, que a aula 11 do `ai-dev` e a aula 2 do `ai-models` abordam, e nenhum trace o conserta.
