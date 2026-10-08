---
title: Guardar o texto por menos tempo que os números
version: 2
---

A tabela do início desta aula deu ao texto e aos números vidas diferentes: dias para as palavras que
as pessoas digitaram, meses para os tokens, os tempos e os resultados. Manter isso exige um job que
rode num horário marcado e tire o texto dos spans que passaram da data, deixando todo o resto no lugar.

O `expire.py` faz isso no arquivo de spans:

```python
"""expire.py: take what people typed out of spans older than --days, and keep everything else."""
import argparse
import json
import os
from datetime import datetime, timedelta

TEXT = ("app.question", "app.reply")
p = argparse.ArgumentParser()
p.add_argument("--now", required=True)
p.add_argument("--days", type=int, required=True)
p.add_argument("--spans", default="spans.jsonl")
a = p.parse_args()

since = datetime.fromisoformat(a.now) - timedelta(days=a.days)
cutoff = since.timestamp() * 1e9
spans, expired = [json.loads(line) for line in open(a.spans)], 0
for s in spans:
    if s["start"] < cutoff and any(k in s["attributes"] for k in TEXT):
        for k in TEXT:
            s["attributes"].pop(k, None)
        expired += 1
with open(a.spans + ".new", "w") as f:
    f.writelines(json.dumps(s, ensure_ascii=False) + "\n" for s in spans)
os.replace(a.spans + ".new", a.spans)
print(f"{len(spans)} spans; text removed from {expired}, every one that started before {since:%Y-%m-%d %H:%M}")
```

Ainda não há nada velho para expirar. O `replay.py` cria: ele reproduz o arquivo de tráfego através
do assistente, com cada pedido carimbado no momento que o arquivo lhe dá, e encena as reações dos
clientes simulados por regras escritas no topo dele. A aula 3 o desmonta e reproduz a semana inteira;
salve-o em `~/obs` agora:

```python
"""replay.py: a week of data/traffic.jsonl through the assistant, in under an hour.

    python replay.py [--from 2026-09-28] [--to 2026-10-05] [--workers 1] [--processor MODULE:CLASS]

Each request runs for real: the embedding, the search, the streamed reply, all
measured. What is simulated is the calendar and the people. The calendar:
every span is stamped with the moment the traffic file gives its request, and
the durations inside it are the measured ones. The people: what a customer
does after reading a reply is decided by the rules below, which the course
wrote, with a generator seeded by the request's id so that a rerun decides
the same way. They are written down so that nobody mistakes them for a
measurement of how people behave.

  - A reply is RIGHT if it contains one of its topic's facts, or, for a topic
    the documents do not answer, if it contains the refusal.
  - 25% of customers rate a reply. A wrong reply gets a thumbs down 85% of the
    time; a right one gets a thumbs up 92% of the time.
  - After a wrong reply, 45% ask again in other words, 40 to 120 seconds
    later, in the same session. If that is wrong too, 60% ask for a person.
  - Summaries are for the support team, who do not rate them.

Feedback is appended to feedback.jsonl, keyed by the trace id of the reply it
is about.
"""
import argparse
import importlib
import json
import random
import threading
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta

import assistant
import telemetry

p = argparse.ArgumentParser()
p.add_argument("--traffic", default="data/traffic.jsonl")
p.add_argument("--from", dest="since", default="0000")
p.add_argument("--to", dest="until", default="9999")
p.add_argument("--workers", type=int, default=1)
p.add_argument("--spans", default="spans.jsonl")
p.add_argument("--processor", action="append", default=[], help="MODULE:CLASS, a span processor to add")
a = p.parse_args()

TOPICS = json.load(open("data/topics.json"))
LOCK = threading.Lock()
counts = {"requests": 0, "errors": 0, "feedback": 0}


def right(reply, topic):
    facts = TOPICS[topic - 1]["facts"]
    if not facts:
        return assistant.REFUSAL in reply
    return any(f.lower() in reply.lower() for f in facts)


def record(**row):
    with LOCK, open("feedback.jsonl", "a") as f:
        f.write(json.dumps(row) + "\n")
        counts["feedback"] += 1


def one(row, at, text):
    """Ask, as if at AT; (reply, trace id), or (None, None) if the assistant failed."""
    t = datetime.fromisoformat(at)
    token = telemetry.OFFSET_NS.set(int(t.timestamp() * 1e9) - telemetry.time.time_ns())
    try:
        reply, _, trace_id = assistant.ask(text, user=row["user"], session=row["session"],
                                           feature=row["feature"], at=at)
        return reply, trace_id
    except Exception:
        with LOCK:
            counts["errors"] += 1
        return None, None
    finally:
        telemetry.OFFSET_NS.reset(token)
        with LOCK:
            counts["requests"] += 1


def person(row):
    rng = random.Random(row["id"])
    reply, trace_id = one(row, row["at"], row["text"])
    if row["feature"] == "summary" or reply is None:
        return
    ok = right(reply, row["topic"])
    t = datetime.fromisoformat(row["at"])
    if rng.random() < 0.25:
        up = rng.random() < 0.92 if ok else rng.random() >= 0.85
        record(trace=trace_id, request=row["id"], at=(t + timedelta(seconds=rng.randrange(5, 30))).isoformat(),
               kind="thumbs", value="up" if up else "down")
    if ok or rng.random() >= 0.45:
        return
    t += timedelta(seconds=rng.randrange(40, 121))
    others = [x for x in TOPICS[row["topic"] - 1]["phrasings"] if x != row["text"]] or [row["text"]]
    again = rng.choice(others)
    record(trace=trace_id, request=row["id"], at=t.isoformat(), kind="rephrase", value=again)
    reply2, trace2 = one(row, t.isoformat(timespec="seconds"), again)
    if reply2 is not None and not right(reply2, row["topic"]) and rng.random() < 0.6:
        record(trace=trace2, request=row["id"], at=(t + timedelta(seconds=20)).isoformat(),
               kind="escalate", value="asked for a person")


telemetry.setup(a.spans, processors=[getattr(importlib.import_module(m), c)() for m, c in
                                     (x.split(":") for x in a.processor)])
rows = [r for r in map(json.loads, open(a.traffic)) if a.since <= r["at"] < a.until]
with ThreadPoolExecutor(a.workers) as pool:
    list(pool.map(person, rows))
print(f"replayed {len(rows)} requests from {a.traffic}: {counts['requests']} asked, "
      f"{counts['errors']} failed, {counts['feedback']} feedback events")
```

Aqui ele reproduz o fim de semana, para haver o que expirar:

```
ana@dev:~/obs$ rm -f spans.jsonl feedback.jsonl; python replay.py --from 2026-10-03 --to 2026-10-05
replayed 63 requests from data/traffic.jsonl: 70 asked, 0 failed, 18 feedback events
ana@dev:~/obs$ grep -c "app.question" spans.jsonl
70
ana@dev:~/obs$ python expire.py --now 2026-10-05T00:00 --days 1
366 spans; text removed from 36, every one that started before 2026-10-04 00:00
ana@dev:~/obs$ grep -c "app.question" spans.jsonl
34
```

Dois dias, 70 perguntas em spans raiz. Com um dia de vida para o texto, rodando à meia-noite da
noite de domingo, as 36 perguntas de sábado perdem as palavras e mantêm o seu lugar em toda
contagem: o span continua lá, com a funcionalidade, a versão, os tokens, a duração e o resultado. As
34 de domingo guardam o texto até a próxima execução.

## Como é uma política de retenção para traces

| o quê | guardado por | por que tanto |
|---|---|---|
| spans sem texto: nomes, tempos, tokens, resultados, notas | 13 meses | um ano de tendência mais o mês para comparar |
| a pergunta e a resposta num span | 7 dias | o bastante para depurar uma reclamação e amostrar para avaliação |
| uma amostra escolhida para avaliação (aulas 9 e 13) | até o conjunto de avaliação ser substituído | ela vira dado de teste, com dono e revisão próprios |
| o prompt inteiro, fontes incluídas | não é guardado | as fontes estão no banco e os ids dos trechos no span as acham |

Os números dessa tabela são um ponto de partida, não uma regra que alguém publicou. O que a torna uma
política é que cada linha tem um propósito e um fim, e que o job que a aplica roda quer alguém se
lembre dele ou não.

Dois detalhes decidem se funciona. **Expirar reescreve, e alguns armazéns tornam isso difícil**: um
backend de rastreamento feito para acrescentar pode só conseguir apagar traces inteiros por idade, e
nesse caso o texto pertence a um armazém separado, com retenção própria e mais curta, ligado ao trace
pelo id. E **a eliminação tem de chegar ao texto antes da expiração**. Um cliente que pede à loja que
apague o que ela guarda sobre ele tem direito a isso hoje, não daqui a sete dias. O pseudônimo torna o
pedido encontrável: faça o hash do id de usuário com a chave, apague o texto de todo span com esse
valor, e os números ficam nas contagens sem nada que identifique. A aula 10 do `observability` tem o
mesmo problema com logs e chega à mesma resposta.
