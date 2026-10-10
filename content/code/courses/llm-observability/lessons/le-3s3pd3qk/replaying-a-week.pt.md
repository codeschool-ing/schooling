---
title: Uma semana de produção, reproduzida
version: 2
---

Custo, latência e qualidade são perguntas sobre muitos pedidos, e as aulas 1 e 2 tiveram um punhado.
Daqui em diante o curso precisa de uma semana de produção para olhar. Ele tem os pedidos, em
`data/traffic.jsonl`; o que não tem é a semana em si. O `replay.py`, que a aula 2 salvou, toca o
arquivo através do assistente, e esta seção o desmonta.

**Todo pedido roda de verdade.** A pergunta vira embedding, os documentos são buscados, a resposta
vem em streaming do `llama3.2:3b`, e todo span é medido. Duas coisas são simuladas, e o arquivo diz
isso no primeiro parágrafo. **O calendário**: os spans de cada pedido são carimbados com o momento
que o arquivo de tráfego lhe dá, e não com o momento em que a reprodução o rodou, por um
deslocamento que o `telemetry.py` soma ao seu relógio. **As pessoas**: o que um cliente faz depois
de ler uma resposta é decidido por regras que o curso escreveu, e a aula 5 trata de como essas
reações aparecem nos dados.

```schooling-example
{
  "language": "python",
  "file": "replay.py",
  "parts": [
    {
      "code": "\"\"\"replay.py: a week of data/traffic.jsonl through the assistant, in under an hour.\n\n    python replay.py [--from 2026-09-28] [--to 2026-10-05] [--workers 1] [--processor MODULE:CLASS]\n\nEach request runs for real: the embedding, the search, the streamed reply, all\nmeasured. What is simulated is the calendar and the people. The calendar:\nevery span is stamped with the moment the traffic file gives its request, and\nthe durations inside it are the measured ones. The people: what a customer\ndoes after reading a reply is decided by the rules below, which the course\nwrote, with a generator seeded by the request's id so that a rerun decides\nthe same way. They are written down so that nobody mistakes them for a\nmeasurement of how people behave.\n\n  - A reply is RIGHT if it contains one of its topic's facts, or, for a topic\n    the documents do not answer, if it contains the refusal.\n  - 25% of customers rate a reply. A wrong reply gets a thumbs down 85% of the\n    time; a right one gets a thumbs up 92% of the time.\n  - After a wrong reply, 45% ask again in other words, 40 to 120 seconds\n    later, in the same session. If that is wrong too, 60% ask for a person.\n  - Summaries are for the support team, who do not rate them.\n\nFeedback is appended to feedback.jsonl, keyed by the trace id of the reply it\nis about.\n\"\"\"\n",
      "note": "As regras que as pessoas simuladas seguem, escritas no topo para que ninguém as confunda com uma medida de como as pessoas se comportam."
    },
    {
      "code": "import argparse\nimport importlib\nimport json\nimport random\nimport threading\nfrom concurrent.futures import ThreadPoolExecutor\nfrom datetime import datetime, timedelta\n\nimport assistant\nimport telemetry\n\np = argparse.ArgumentParser()\np.add_argument(\"--traffic\", default=\"data/traffic.jsonl\")\np.add_argument(\"--from\", dest=\"since\", default=\"0000\")\np.add_argument(\"--to\", dest=\"until\", default=\"9999\")\np.add_argument(\"--workers\", type=int, default=1)\np.add_argument(\"--spans\", default=\"spans.jsonl\")\np.add_argument(\"--processor\", action=\"append\", default=[], help=\"MODULE:CLASS, a span processor to add\")\na = p.parse_args()\n\nTOPICS = json.load(open(\"data/topics.json\"))\nLOCK = threading.Lock()\ncounts = {\"requests\": 0, \"errors\": 0, \"feedback\": 0}\n\n\n"
    },
    {
      "code": "def right(reply, topic):\n    facts = TOPICS[topic - 1][\"facts\"]\n    if not facts:\n        return assistant.REFUSAL in reply\n    return any(f.lower() in reply.lower() for f in facts)\n\n\n",
      "note": "O que decide se uma resposta estava certa, para o cliente simulado: um dos fatos do assunto dela está nela, ou, para uma pergunta que os documentos não respondem, ela contém a recusa."
    },
    {
      "code": "def record(**row):\n    with LOCK, open(\"feedback.jsonl\", \"a\") as f:\n        f.write(json.dumps(row) + \"\\n\")\n        counts[\"feedback\"] += 1\n\n\n",
      "note": "Cada reação é uma linha no `feedback.jsonl`, com o id de trace da resposta a que se refere."
    },
    {
      "code": "def one(row, at, text):\n    \"\"\"Ask, as if at AT; (reply, trace id), or (None, None) if the assistant failed.\"\"\"\n    t = datetime.fromisoformat(at)\n    token = telemetry.OFFSET_NS.set(int(t.timestamp() * 1e9) - telemetry.time.time_ns())\n    try:\n        reply, _, trace_id = assistant.ask(text, user=row[\"user\"], session=row[\"session\"],\n                                           feature=row[\"feature\"], at=at)\n        return reply, trace_id\n    except Exception:\n        with LOCK:\n            counts[\"errors\"] += 1\n        return None, None\n    finally:\n        telemetry.OFFSET_NS.reset(token)\n        with LOCK:\n            counts[\"requests\"] += 1\n\n\n",
      "note": "Um pedido, feito como se fosse no momento AT. O deslocamento é a diferença entre esse momento e agora, definida só para esta thread; todo span que o assistente abre enquanto ele vale leva o horário do arquivo de tráfego, e a sua duração é a medida."
    },
    {
      "code": "def person(row):\n    rng = random.Random(row[\"id\"])\n    reply, trace_id = one(row, row[\"at\"], row[\"text\"])\n    if row[\"feature\"] == \"summary\" or reply is None:\n        return\n    ok = right(reply, row[\"topic\"])\n    t = datetime.fromisoformat(row[\"at\"])\n    if rng.random() < 0.25:\n        up = rng.random() < 0.92 if ok else rng.random() >= 0.85\n        record(trace=trace_id, request=row[\"id\"], at=(t + timedelta(seconds=rng.randrange(5, 30))).isoformat(),\n               kind=\"thumbs\", value=\"up\" if up else \"down\")\n    if ok or rng.random() >= 0.45:\n        return\n    t += timedelta(seconds=rng.randrange(40, 121))\n    others = [x for x in TOPICS[row[\"topic\"] - 1][\"phrasings\"] if x != row[\"text\"]] or [row[\"text\"]]\n    again = rng.choice(others)\n    record(trace=trace_id, request=row[\"id\"], at=t.isoformat(), kind=\"rephrase\", value=again)\n    reply2, trace2 = one(row, t.isoformat(timespec=\"seconds\"), again)\n    if reply2 is not None and not right(reply2, row[\"topic\"]) and rng.random() < 0.6:\n        record(trace=trace2, request=row[\"id\"], at=(t + timedelta(seconds=20)).isoformat(),\n               kind=\"escalate\", value=\"asked for a person\")\n\n\n",
      "note": "Um cliente: pergunta, talvez avalia, talvez pergunta de novo com outras palavras, talvez pede uma pessoa. O gerador é semeado com o id do pedido, então uma nova execução decide do mesmo jeito."
    },
    {
      "code": "telemetry.setup(a.spans, processors=[getattr(importlib.import_module(m), c)() for m, c in\n                                     (x.split(\":\") for x in a.processor)])\nrows = [r for r in map(json.loads, open(a.traffic)) if a.since <= r[\"at\"] < a.until]\nwith ThreadPoolExecutor(a.workers) as pool:\n    list(pool.map(person, rows))\nprint(f\"replayed {len(rows)} requests from {a.traffic}: {counts['requests']} asked, \"\n      f\"{counts['errors']} failed, {counts['feedback']} feedback events\")\n",
      "note": "Um pedido de cada vez, por padrão, porque o Ollama num computador responde a um de cada vez: vários juntos só fariam fila lá, e cada espera na fila seria medida como lentidão do modelo."
    }
  ]
}
```

```
ana@dev:~/obs$ python replay.py
replayed 284 requests from data/traffic.jsonl: 311 asked, 0 failed, 89 feedback events
ana@dev:~/obs$ wc -l spans.jsonl feedback.jsonl
  1666 spans.jsonl
    89 feedback.jsonl
  1755 total
```

Os 284 pedidos do arquivo viraram 311 perguntas ao assistente: as outras 27 são clientes perguntando
de novo com outras palavras depois de uma resposta errada, o que as regras deixam 45% deles fazer.
Nada falhou. A reprodução levou 17 minutos na máquina da gravação. 1.666 spans foram para o
`spans.jsonl` e 89 reações para o `feedback.jsonl`: polegares, reformulações e pedidos de uma
pessoa.

O primeiro trace da semana, um resumo que a equipe de atendimento pediu cedo na segunda-feira:

```
ana@dev:~/obs$ python tree.py --attrs $(head -1 spans.jsonl | python -c "import json,sys; print(json.load(sys.stdin)[\"trace\"])") | head -12
trace a29f0116fe1e3be0426f246294af1ba2   start(ms) took(ms)
      0   4,930 ms  ask
                     app.feature = "summary"
                     app.release = "2026.09.4"
                     gen_ai.request.model = "llama3.2:3b"
                     user.hash = "f71cf97066359de1"
                     session.id = "s001"
                     app.question = "Summarise this conversation in at most 40 words.\nHello, this is Rafael Lima. My order [order] has not arrived.\nIt was sent by standard delivery and the tracking has not changed for twelve working days.\nI would prefer a refund rather than waiting for a new parcel."
                     app.outcome = "summarised"
                     app.reply = "Rafael Lima is contacting customer service regarding a missing order ([order]) that has not arrived after 12 working days. He prefers a refund over waiting for a new parcel."
      0   4,929 ms    generate
                       app.attempts = 1
```

A versão é a `2026.09.4`, a de antes de o piso subir, porque na segunda-feira, 28 de setembro, era a
versão em vigor; o `assistant.py` escolhe a versão pelo horário do pedido, não pelo de hoje. Um
resumo não busca nada, então o único filho dele é o `generate`.

Leia a pergunta e a resposta. O número do pedido foi removido na entrada, como a aula 2 arranjou.
**O nome do cliente não foi, e o modelo o repetiu no resumo**, então ele está no span duas vezes. A
aula 2 disse que um nome não tem forma que um padrão ache; aqui está o primeiro trace da semana
provando isso.

## Por que reproduzir, e não um teste de carga

Um teste de carga manda muitos pedidos para achar onde um sistema quebra. Uma reprodução manda **os
pedidos que aconteceram** para descobrir quanto custaram, quanto levaram e o que receberam de volta. A
diferença está na entrada: uma reprodução é tão representativa quanto o tráfego que ela toca, e o
tráfego aqui é uma semana que o curso inventou. Ela serve para o que este curso a usa: uma semana
fixa e repetível que toda aula seguinte pode medir, mudar e medir de novo, onde uma semana real de
produção nunca mais voltaria.
