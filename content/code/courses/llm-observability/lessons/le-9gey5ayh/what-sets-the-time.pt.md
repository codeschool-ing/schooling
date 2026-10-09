---
title: O que define o tempo
version: 2
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
ana@dev:~/obs$ python drivers.py
whole call, by output tokens
     0 to   19    112 calls  median   2095 ms
    20 to   39     63 calls  median   3250 ms
    40 to   59     72 calls  median   4929 ms
    60 to   79      3 calls  median   8068 ms
    80 to   99     15 calls  median   9482 ms
first token, by input tokens
     0 to   99     21 calls  median    237 ms
   100 to  199    109 calls  median    744 ms
   200 to  299    125 calls  median    829 ms
   300 to  399     10 calls  median   1358 ms
first token over 3 s: 0 of 265 calls
```

**A chamada inteira acompanha a saída.** De menos de 20 tokens a 80 ou mais, a mediana vai de 2.095
ms a 9.482, uma linha quase reta de uns 100 ms por token. É o segundo relógio, multiplicado. Uma
resposta longa é uma resposta lenta, seja o que for que mais seja verdade.

**O primeiro token acompanha a entrada.** De 100 tokens de entrada a mais de 300, o primeiro token
mediano vai de 744 ms a 1.358. Ler é mais rápido que escrever, mas em quatro núcleos não tanto
quanto no hardware de um fornecedor: um prompt três vezes mais longo custa mais de meio segundo. Os
prompts menores, abaixo de 100 tokens, são os resumos da equipe de atendimento, e eles voltam mais
rápido por um segundo motivo além do tamanho. Só duas conversas se repetem a semana toda, e o Ollama
guarda o que calculou para o começo do último prompt e o reaproveita quando o próximo começa do
mesmo jeito; é a contagem de cache que o span instrumentado da aula 1 informou. Com prompts de
dezenas de milhares de tokens, como num agente que carrega um histórico longo, a mesma inclinação
soma minutos numa máquina como esta.

E **nenhuma chamada em 265 esperou mais de três segundos** pelo primeiro token. Em produção essa
linha raramente fica vazia: algumas chamadas esperam muito mais do que o tamanho delas explica, em
todo grupo, que é a assinatura de uma causa fora do pedido, o fornecedor, a rede, uma fila. Aqui o
modelo tinha a máquina só para ele e nunca saiu da memória, então não houve nenhuma. Quando houver,
nenhuma mudança no prompt vai removê-las.

## O que isso decide

A aula 3 descobriu que a entrada era a maior parte do **custo**. Esta seção descobre que a saída é a
maior parte do **tempo**. As duas alavancas são diferentes, e qual puxar depende de qual reclamação se
está respondendo:

| para ficar | mude | porque |
|---|---|---|
| mais barato | a entrada: menos fontes, um prompt de sistema mais curto | tokens de entrada são a maior parte da conta |
| com cara de mais rápido | o tempo até o primeiro token: prompt mais curto, uma região mais perto, streaming na tela | é a espera de tela vazia |
| terminando antes | a saída: pedir respostas mais curtas, limitar `max_tokens` | cada token soma os seus 100 ms |
| doendo menos na cauda | timeouts e uma nova tentativa, as últimas seções | a cauda não é causada pelo pedido |

A aula 16 do `prompt-reliability` e a aula 18 do `agents-mcp` puxam essas alavancas nos próprios
sistemas e medem o resultado. O que este curso acrescenta é que os spans já guardam o que é preciso
para escolher: nenhum experimento à parte, só um agrupamento sobre uma semana de produção.
