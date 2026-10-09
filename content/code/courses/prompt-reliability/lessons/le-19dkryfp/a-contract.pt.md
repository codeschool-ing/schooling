---
title: O formato é um contrato
version: 2
---

Um prompt que pede JSON está fazendo uma promessa a quem quer que leia a resposta em seguida. Três
linhas do `v2-json.txt` são a promessa:

```
ana@lab:~/triage$ sed -n 3,6p prompts/v2-json.txt
Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs
```

**As verificações são o outro lado dela**: aquilo em que o programa que lê a resposta se apoia,
escrito como código. Elas estão no `pl.py`, numa função só:

```
ana@lab:~/triage$ grep -n -A20 "^def judge" pl.py
130:def judge(row, expect, lenient=False):
131-    """The first check a reply fails, and why; (None, None) if it passes them all."""
132-    obj = parse(row["text"], lenient)
133-    if obj is None:
134-        return "json", "cut off at num_predict" if row["stop"] == "length" else "not a JSON object"
135-    missing = [k for k in LABELS if k not in obj]
136-    extra = [k for k in obj if k not in LABELS and k != "summary"]
137-    if missing:
138-        return "fields", "missing " + ", ".join(missing)
139-    if extra:
140-        return "fields", "unexpected " + ", ".join(extra)
141-    for k in LABELS:
142-        if obj[k] not in LABELS[k]:
143-            return "labels", "%s %r" % (k, obj[k])
144-    for k in LABELS:
145-        if obj[k] != expect[k]:
146-            return k, "%s, expected %s" % (obj[k], expect[k])
147-    return None, None
148-
149-
150-def verdicts(path, lenient=False):
```

A verificação `fields` exige duas chaves, `category` e `urgency`, e recusa qualquer chave fora
delas e de `summary`. `labels` exige que cada valor venha da sua lista. São as três coisas que um
esquema JSON diz com mais frequência: **quais chaves precisam estar ali, quais podem estar, e que
valores cada uma pode ter.** A verificação da aula 1 que pegou um número de pedido copiado de um
exemplo foi a segunda delas, e continua pegando:

```
ana@lab:~/triage$ pl run prompts/v3-leaky.txt cases/dev.jsonl --out runs/leaky.jsonl
40 calls, prompt 0acdc3c7, llama3.2:3b, written to runs/leaky.jsonl
ana@lab:~/triage$ pl check runs/leaky.jsonl --failures | grep fields
fields       34     6
t01    fields    unexpected order
t08    fields    unexpected order
t16    fields    unexpected order
t31    fields    unexpected order
```

## Leia o contrato, não o prompt

A verificação não é uma cópia do prompt, e as diferenças são decisões. O prompt pede três campos; a
verificação exige dois. Uma resposta sem `summary` passa em `fields`, porque o programa que
encaminha uma mensagem precisa da categoria e da urgência e de mais nada, e o resumo está ali para
a pessoa que abre o chamado. **Escrever o que o leitor realmente exige é como você descobre onde o
prompt pode se dar ao luxo de ser frouxo.**

Depois que uma resposta passou nas três primeiras verificações, o programa pode supor um objeto, as
duas chaves, um valor de cada lista e nenhuma chave da qual nunca ouviu falar. Não pode supor que o
resumo está ali, que é preciso, ou que a categoria está certa.

## Duas verificações que rodam em produção, e duas que não

As duas últimas verificações, `category` e `urgency`, comparam uma resposta com a resposta que uma
pessoa deu. No conjunto de teste essa resposta existe. **Em produção ninguém rotulou a mensagem
ainda**, e é justamente por isso que um modelo a está classificando. Então `json`, `fields` e
`labels` são verificações que o programa consumidor pode rodar em toda resposta que receber, e
deve. `category` e `urgency` só podem ser medidas num conjunto de teste; as aulas 11 e 12 tratam de
fazer isso bem.

Essa divisão é o sentido prático de um contrato. **O formato pode ser verificado em toda chamada; o
conteúdo só pode ser estimado.** Uma resposta que quebra o formato é barrada na porta. Uma resposta
com uma categoria errada e confiante passa direto por ela.
