---
title: Uma semana de latência, em percentis
version: 2
---

O `latency.py` pega cada chamada a modelo bem-sucedida da semana que a aula 3 reproduziu, que ainda
está no `spans.jsonl`, e cada pedido, e imprime os três relógios como percentis:

```python
"""latency.py: the week's successful model calls and requests, as percentiles."""
import json

spans = [json.loads(line) for line in open("spans.jsonl")]
chats = [s for s in spans if s["name"].startswith("chat ") and s["status"] != "ERROR"]
asks = [s for s in spans if s["name"] == "ask"]
ms = lambda s: (s["end"] - s["start"]) / 1e6
ttft = lambda s: s["attributes"]["app.time_to_first_token_ms"]
per_token = lambda s: (ms(s) - ttft(s)) / max(s["attributes"]["gen_ai.usage.output_tokens"] - 1, 1)
rows = {"whole request": [ms(s) for s in asks], "model call": [ms(s) for s in chats],
        "first token": [ttft(s) for s in chats], "each token after": [per_token(s) for s in chats]}
print(f"{'':17} {'n':>5} {'mean':>6} {'p50':>6} {'p90':>6} {'p95':>6} {'p99':>6} {'max':>6}   ms")
for name, xs in rows.items():
    xs.sort()
    q = lambda p: xs[min(len(xs) - 1, int(p * len(xs)))]
    print(f"{name:17} {len(xs):5} {sum(xs) / len(xs):6.0f} {q(.5):6.0f} {q(.9):6.0f} {q(.95):6.0f} {q(.99):6.0f} {xs[-1]:6.0f}")
```

```
ana@dev:~/obs$ python latency.py
                      n   mean    p50    p90    p95    p99    max   ms
whole request       311   3317   2962   6078   8447   9838  11164
model call          265   3721   3099   6022   8996   9684  11003
first token         265    744    748   1346   1431   1954   2190
each token after    265    102    101    109    110    120    123
```

## Por que não a média

Leia a linha `model call`. A mediana é 3.099 ms e o percentil 95 é 8.996: dezenove chamadas em vinte
terminaram em menos de nove segundos, e a mais lenta levou onze. A média, 3.721, fica acima da
mediana, puxada pelas poucas lentas, e não descreve ninguém: é alta demais para a chamada típica e
baixa demais para a lenta.

Essa forma, um corpo e uma cauda longa e fina para um lado, é a cara da latência quase em todo
lugar, e é por isso que a latência é informada em percentis. A aula 6 do `observability` constrói os
histogramas que tornam percentis baratos de calcular em escala; aqui uma lista ordenada de algumas
centenas de números basta.

A cauda aqui tem uma causa, e a próxima seção a acha: **as respostas longas**. O que ela não tem é a
causa que uma cauda de produção costuma ter. Um modelo que precisa ser carregado na memória
primeiro, um pedido mandado para uma máquina ocupada, uma fila na hora em que os jobs de todo mundo
começam: nada disso aconteceu, porque o modelo nunca saiu da memória durante uma semana reproduzida
em dezessete minutos e nada mais estava pedindo. A última seção desta aula faz a primeira dessas
acontecer de propósito.

## Qual percentil acompanhar

**p50** diz o que a maioria vê, e se move quando algo muda para todos, um modelo novo, um prompt mais
longo. **p95 e p99** dizem o que os azarados veem, e é neles que a tarde ruim de um fornecedor aparece
primeiro. Um cliente que faz dez perguntas numa sessão tem uma chance em dez de topar com uma chamada
de p99 pelo menos uma vez, então o percentil 99 não é um cliente raro, é uma *chamada* rara numa sessão
comum.

A linha `whole request` é a chamada ao modelo mais tudo em volta, e a cauda dela é a mesma cauda,
pela mesma causa, porque o modelo é quase tudo. A linha `each token after` é o segundo relógio: 101
ms na mediana, 120 no p99. Ele quase não varia, e isso é característico de um modelo com uma máquina
só para ele: depois que começa, escreve no próprio ritmo.