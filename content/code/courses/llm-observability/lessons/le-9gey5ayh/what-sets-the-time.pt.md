---
title: O que define o tempo
version: 1
---

Um percentil diz quão lento; não diz por quê. Numa chamada a modelo, duas coisas valem ser conferidas
primeiro, porque já estão em todo span: quanto foi lido e quanto foi escrito. O `drivers.py` agrupa as
chamadas da semana por cada uma e tira a mediana de cada grupo:

```python
"""drivers.py: what the length of a model call goes with, in the week's spans."""
import json
from statistics import median

chats = [s for s in map(json.loads, open("spans.jsonl"))
         if s["name"].startswith("chat ") and s["status"] != "ERROR"]
a = lambda s, k: s["attributes"][k]


def table(title, key, value, edges):
    print(title)
    for lo, hi in zip(edges, edges[1:]):
        xs = [value(s) for s in chats if lo <= key(s) < hi]
        if xs:
            print(f"  {lo:4} to {hi - 1:4}  {len(xs):5} calls  median {median(xs):6.0f} ms")


table("whole call, by output tokens", lambda s: a(s, "gen_ai.usage.output_tokens"),
      lambda s: (s["end"] - s["start"]) / 1e6, [0, 20, 40, 60, 80, 100, 200])
table("first token, by input tokens", lambda s: a(s, "gen_ai.usage.input_tokens"),
      lambda s: a(s, "app.time_to_first_token_ms"), [0, 100, 200, 300, 400, 600])
cold = [s for s in chats if a(s, "app.time_to_first_token_ms") > 3000]
print(f"first token over 3 s: {len(cold)} of {len(chats)} calls")
```

```
ana@lab:~/obs$ python drivers.py
whole call, by output tokens
     0 to   19    361 calls  median    555 ms
    20 to   39    154 calls  median    997 ms
    40 to   59    318 calls  median   1603 ms
    60 to   79    128 calls  median   2146 ms
    80 to   99    147 calls  median   2498 ms
first token, by input tokens
     0 to   99    124 calls  median    236 ms
   100 to  199    214 calls  median    247 ms
   200 to  299    304 calls  median    288 ms
   300 to  399    466 calls  median    329 ms
first token over 3 s: 16 of 1108 calls
```

**A chamada inteira acompanha a saída.** De menos de 20 tokens a 80 ou mais, a mediana vai de 555 ms a
2.498, uma linha quase reta de uns 25 ms por token. É o segundo relógio, multiplicado. Uma resposta
longa é uma resposta lenta, seja o que for que mais seja verdade.

**O primeiro token acompanha a entrada, devagar.** De menos de 100 tokens de entrada a mais de 300, o
primeiro token mediano vai de 236 a 329 ms. Ler é muito mais rápido que escrever, então um prompt três
vezes mais longo custa um décimo de segundo, não três vezes mais. Com prompts de dezenas de milhares de
tokens, como num agente que carrega um histórico longo, a mesma inclinação soma segundos.

E **dezesseis chamadas em 1.108 esperaram mais de três segundos** pelo primeiro token, em todos os
grupos. A lentidão delas não tem nada a ver com o tamanho, que é a assinatura de uma causa fora do
pedido: o fornecedor, a rede, uma fila. Elas são a cauda da seção anterior, e nenhuma mudança no prompt
vai removê-las.

## O que isso decide

A aula 3 descobriu que a entrada era a maior parte do **custo**. Esta seção descobre que a saída é a
maior parte do **tempo**. As duas alavancas são diferentes, e qual puxar depende de qual reclamação se
está respondendo:

| para ficar | mude | porque |
|---|---|---|
| mais barato | a entrada: menos fontes, um prompt de sistema mais curto | tokens de entrada são a maior parte da conta |
| com cara de mais rápido | o tempo até o primeiro token: prompt mais curto, uma região mais perto, streaming na tela | é a espera de tela vazia |
| terminando antes | a saída: pedir respostas mais curtas, limitar `max_tokens` | cada token soma os seus 25 ms |
| doendo menos na cauda | timeouts e uma nova tentativa, as últimas seções | a cauda não é causada pelo pedido |

A aula 16 do `prompt-reliability` e a aula 18 do `agents-mcp` puxam essas alavancas nos próprios
sistemas e medem o resultado. O que este curso acrescenta é que os spans já guardam o que é preciso
para escolher: nenhum experimento à parte, só um agrupamento sobre uma semana de produção.
