---
title: O formato é um contrato
version: 1
---

Um prompt que pede JSON faz uma promessa a quem quer que leia a resposta em seguida. Três linhas do
`v2-json.txt` são a promessa:

```
ana@lab:~/triage$ sed -n 3,6p prompts/v2-json.txt
Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs
```

**As verificações são o outro lado dela**: aquilo em que o programa que lê a resposta se apoia,
escrito como código. As duas do meio são um esquema em miniatura:

```
ana@lab:~/triage$ grep -n -A12 'elif c == "fields"' promptlab/cli.py
223:        elif c == "fields":
224-            missing = [k for k in ("category", "urgency") if k not in obj]
225-            extra = [k for k in obj if k not in ("category", "urgency", "summary", "confidence")]
226-            ok = not missing and not extra
227-            reason = ("missing " + ", ".join(missing)) if missing else ("unexpected " + ", ".join(extra))
228-        elif c == "labels":
229-            bad = []
230-            if obj["category"] not in LABELS:
231-                bad.append("category %r" % obj["category"])
232-            if obj["urgency"] not in URGENCIES:
233-                bad.append("urgency %r" % obj["urgency"])
234-            ok, reason = not bad, "; ".join(bad)
235-        elif c == "category":
```

`fields` exige duas chaves, `category` e `urgency`, e recusa qualquer chave fora de uma lista de
quatro. `labels` exige que cada valor venha da sua lista. São as três coisas que um esquema JSON diz
com mais frequência: **quais chaves precisam estar lá, quais podem estar e que valores cada uma pode
ter.** A verificação da aula 1 que pegou um número de pedido copiado de um exemplo era a segunda
delas:

```
ana@lab:~/triage$ pl run prompts/v3-leaky.txt cases/dev.jsonl --out runs/leaky.jsonl
40 calls, prompt 0acdc3c7, written to runs/leaky.jsonl
ana@lab:~/triage$ pl check runs/leaky.jsonl --failures | sed -n 9,11p
t01    fields    unexpected order
t02    fields    unexpected order
t03    fields    unexpected order
```

## Leia o contrato, não o prompt

A verificação não é uma cópia do prompt, e as diferenças são decisões. O prompt pede três campos; a
verificação exige dois. Uma resposta sem `summary` passa em `fields`, porque o programa que
encaminha uma mensagem precisa da categoria e da urgência e de mais nada, e o resumo existe para a
pessoa que abre o chamado. A quarta chave permitida, `confidence`, é para a aula 21, em que o modelo
declara uma. **Escrever o que o leitor de fato exige é como você descobre em que o prompt pode se dar
ao luxo de ser frouxo.**

Depois que uma resposta passou nas três primeiras verificações, o programa pode supor um objeto, as
duas chaves, um valor de cada lista e nenhuma chave desconhecida. Não pode supor que o resumo está
lá, que ele está correto, nem que a categoria está certa.

## Duas verificações que rodam em produção, e duas que não

As duas últimas verificações, `category` e `urgency`, comparam a resposta com a que uma pessoa deu.
No conjunto de teste essa resposta existe. **Em produção ninguém rotulou a mensagem ainda**, e é
justamente por isso que um modelo a está classificando. Então `json`, `fields` e `labels` são
verificações que o programa consumidor pode rodar em toda resposta que receber, e deve. `category` e
`urgency` só podem ser medidas num conjunto de teste; as aulas 11 e 12 tratam de fazer isso bem.

Essa divisão é o sentido prático de um contrato. **O formato pode ser verificado em cada chamada; o
conteúdo só pode ser estimado.** Uma resposta que quebra o formato é barrada na porta. Uma resposta
com uma categoria errada e confiante passa direto.
