---
title: Uma semana de latência, em percentis
version: 1
---

O `latency.py` pega cada chamada a modelo bem-sucedida da semana reproduzida, e cada pedido, e imprime
os três relógios como percentis:

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
ana@lab:~/obs$ python replay.py
replayed 1127 requests from data/traffic.jsonl: 1345 asked, 0 failed, 483 feedback events
ana@lab:~/obs$ python latency.py
                      n   mean    p50    p90    p95    p99    max   ms
whole request      1345   1253   1056   2541   2962   4846   6343
model call         1108   1438   1324   2591   3045   4862   6282
first token        1108    353    290    399    444   4257   4460
each token after   1108     26     26     35     38     48     54
```

## Por que não a média

Leia a linha `first token`. A mediana é 290 ms e o percentil 95 é 444: dezenove chamadas em vinte viram
o primeiro token em menos de meio segundo. Aí **o percentil 99 é 4.257 ms** e o máximo 4.460. Uma
chamada em cem esperou quase dez vezes mais que uma típica. A média, 353, fica entre os dois e não
descreve ninguém: é alta demais para a chamada típica e absurdamente baixa para a lenta.

Essa forma, um corpo apertado e uma cauda longa e fina, é a cara da latência em quase todo lugar, e é
por isso que latência se relata em percentis. A aula 6 do `observability` constrói os histogramas que
tornam percentis baratos de calcular em escala; aqui uma lista ordenada de mil números basta.

A cauda é a **partida a frio** do labobs: com probabilidade de uma em cem, um pedido espera quatro
segundos a mais antes do primeiro token. A cauda de um fornecedor real tem outras causas, um pedido
encaminhado para uma máquina ocupada, um modelo sendo carregado, uma fila longa na hora em que os jobs
em lote de todo mundo começam, e a mesma cara numa tabela de percentis.

## Qual percentil acompanhar

**p50** diz o que a maioria vê, e se move quando algo muda para todos, um modelo novo, um prompt mais
longo. **p95 e p99** dizem o que os azarados veem, e é neles que a tarde ruim de um fornecedor aparece
primeiro. Um cliente que faz dez perguntas numa sessão tem uma chance em dez de topar com uma chamada
de p99 pelo menos uma vez, então o percentil 99 não é um cliente raro, é uma *chamada* rara numa sessão
comum.

A linha `whole request` é a chamada ao modelo mais tudo em volta, e a cauda dela é a mesma cauda, pela
mesma causa, porque o modelo é quase tudo. A linha `each token after` é o segundo relógio: 26 ms na
mediana, 48 no p99. Ele varia muito menos que o primeiro token, e isso é característico: o que é lento
e imprevisível é começar.
