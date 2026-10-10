---
title: Polegar para cima e para baixo
version: 2
---

O sinal de qualidade mais direto que existe: perguntar ao cliente. Um polegar embaixo de cada resposta,
para cima ou para baixo, não custa nada para mostrar e um clique para dar. Nesta semana, **os clientes
são simulados**, e o que cada um faz depois de uma resposta é decidido pelas regras que o `replay.py`
declara no topo:

```
  - A reply is RIGHT if it contains one of its topic's facts, or, for a topic
    the documents do not answer, if it contains the refusal.
  - 25% of customers rate a reply. A wrong reply gets a thumbs down 85% of the
    time; a right one gets a thumbs up 92% of the time.
  - After a wrong reply, 45% ask again in other words, 40 to 120 seconds
    later, in the same session. If that is wrong too, 60% ask for a person.
  - Summaries are for the support team, who do not rate them.
```

Os números são do curso, escolhidos para parecer o que equipes de atendimento relatam, e não medidos
de ninguém. O que a aula mede é o que o assistente respondeu e como essas regras então se somam.

## Ligando um polegar à sua resposta

Cada clique é uma linha no `feedback.jsonl`, e ela traz **o id de trace da resposta a que se refere**,
que a tela recebeu junto com a resposta:

```
ana@dev:~/obs$ head -3 feedback.jsonl
{"trace": "a97ca428c676540ebab912432abec13c", "request": "r009", "at": "2026-09-28T09:29:35", "kind": "thumbs", "value": "up"}
{"trace": "9d3fe5c38cadad8bdb8f799e9374929c", "request": "r010", "at": "2026-09-28T09:40:12", "kind": "thumbs", "value": "up"}
{"trace": "2f467df1fd3622649fbdc311f53d6ddf", "request": "r011", "at": "2026-09-28T10:10:13", "kind": "thumbs", "value": "down"}
```

A ligação é exata, por id, como a aula 1 disse que tinha de ser: um cliente que perguntou duas vezes
num minuto gera dois traces e um polegar num deles. O `signals.py` liga cada linha à versão do seu trace
e conta:

```python
"""signals.py: feedback joined to its trace by id, and counted per release."""
import json
from collections import Counter, defaultdict

import costs

release = {r["trace"]: r["release"] for r in costs.requests()}
asked = Counter(r["release"] for r in costs.requests() if r["feature"] != "summary")
seen = defaultdict(Counter)
for f in map(json.loads, open("feedback.jsonl")):
    seen[release[f["trace"]]][f["kind"] if f["kind"] != "thumbs" else "thumbs " + f["value"]] += 1
print(f"{'release':10} {'requests':>8} {'rated':>6} {'down':>5} {'down %':>7} {'rephrased':>9} {'person':>7}  per 100 requests")
for rel, c in sorted(seen.items()):
    rated = c["thumbs up"] + c["thumbs down"]
    print(f"{rel:10} {asked[rel]:8} {rated:6} {c['thumbs down']:5} {c['thumbs down'] / rated:7.0%} "
          f"{c['rephrase'] / asked[rel] * 100:9.1f} {c['escalate'] / asked[rel] * 100:7.1f}")
```

```
ana@dev:~/obs$ python signals.py
release    requests  rated  down  down % rephrased  person  per 100 requests
2026.09.4       134     32     5     16%       6.7     0.0
2026.10.1       141     26     4     15%      12.8     2.8
```

Sob a versão antiga, **16% dos polegares foram para baixo**; sob a nova, **15%**. Só pelos
polegares, a versão que recusou quase o dobro de perguntas de ajuda não mudou nada, e vale ter
cuidado com isso.

## O que um polegar mede, e o que não mede

**Pouca gente avalia.** 32 avaliações numa versão e 26 na outra, de 134 e 141 pedidos: nove
polegares para baixo na semana inteira. Nesses tamanhos, uma diferença de dois ou três polegares é
ruído, para qualquer lado, e um painel que mostre a taxa de polegares para baixo de um dia sobre
cinco avaliações vai pular só com o ruído. A aula 9 põe uma margem de erro numa taxa assim.

**Quem avalia não é quem pergunta.** Aqui é um quarto sorteado, porque a regra manda. Em produtos
reais, as pessoas avaliam mais quando estão irritadas, ou mais quando estão encantadas, e a mistura
muda com a tela: um polegar sempre visível atrai um público diferente de um que aparece depois de
uma pausa. Uma taxa de polegares para baixo é uma medida da experiência de quem avalia, e é seguro
compará-la entre duas versões da mesma tela, não entre dois produtos.

**Um polegar diz que algo estava errado, não o quê.** Um polegar para baixo numa recusa, num fato errado
e numa resposta lenta parecem iguais. O valor dele é apontar traces que valem ser lidos, e ser
independente de qualquer coisa que o sistema pense de si mesmo.
