---
title: Uma semana de produção, reproduzida
version: 1
---

Custo, latência e qualidade são perguntas sobre muitos pedidos, e as aulas 1 e 2 tinham um punhado.
Daqui em diante o curso precisa de uma semana de produção para examinar. Ele tem os pedidos, no
`data/traffic.jsonl`; o que não tem é a semana em si. O `replay.py` toca o arquivo através do
assistente em poucos minutos.

**Todo pedido roda de verdade.** A pergunta vira embedding, os documentos são buscados, a resposta
vem em streaming do labobs, e todo span é medido. Duas coisas são simuladas, e o arquivo diz isso no
primeiro parágrafo. **O calendário**: os spans de cada pedido são carimbados com o momento que o
arquivo de tráfego lhe dá, e não com o momento em que a reprodução o rodou, por um deslocamento que o
`telemetry.py` soma ao seu relógio. **As pessoas**: o que um cliente faz depois de ler uma resposta é
decidido por regras que o curso escreveu, e a aula 5 trata de como essas reações aparecem nos dados.

```schooling-example
{
  "language": "python",
  "file": "replay.py",
  "parts": [
    {
      "code": "def right(reply, topic):\n    facts = TOPICS[topic - 1][\"facts\"]\n    if not facts:\n        return reply.startswith(assistant.REFUSAL)\n    return any(f.lower() in reply.lower() for f in facts)",
      "note": "O que decide se uma resposta estava certa, para o cliente simulado: um dos fatos do tópico está nela, ou, para uma pergunta que os documentos não respondem, ela é a recusa."
    },
    {
      "code": "def one(row, at, text):\n    \"\"\"Ask, as if at AT; (reply, trace id), or (None, None) if the assistant failed.\"\"\"\n    t = datetime.fromisoformat(at)\n    token = telemetry.OFFSET_NS.set(int(t.timestamp() * 1e9) - telemetry.time.time_ns())\n    try:\n        reply, _, trace_id = assistant.ask(text, user=row[\"user\"], session=row[\"session\"],\n                                           feature=row[\"feature\"], at=at)\n        return reply, trace_id\n    except Exception:\n        with LOCK:\n            counts[\"errors\"] += 1\n        return None, None\n    finally:\n        telemetry.OFFSET_NS.reset(token)\n        with LOCK:\n            counts[\"requests\"] += 1",
      "note": "Um pedido, feito como se fosse em AT. O deslocamento é a diferença entre esse momento e agora, definida só para esta thread; todo span que o assistente abre enquanto ela vale carrega o horário do arquivo de tráfego, e a sua duração é a medida."
    },
    {
      "code": "def person(row):\n    rng = random.Random(row[\"id\"])\n    reply, trace_id = one(row, row[\"at\"], row[\"text\"])\n    if row[\"feature\"] == \"summary\" or reply is None:\n        return\n    ok = right(reply, row[\"topic\"])\n    t = datetime.fromisoformat(row[\"at\"])\n    if rng.random() < 0.18:\n        up = rng.random() < 0.92 if ok else rng.random() >= 0.85\n        record(trace=trace_id, request=row[\"id\"], at=(t + timedelta(seconds=rng.randrange(5, 30))).isoformat(),\n               kind=\"thumbs\", value=\"up\" if up else \"down\")\n    if ok or rng.random() >= 0.45:\n        return\n    t += timedelta(seconds=rng.randrange(40, 121))\n    others = [x for x in TOPICS[row[\"topic\"] - 1][\"phrasings\"] if x != row[\"text\"]] or [row[\"text\"]]\n    again = rng.choice(others)\n    record(trace=trace_id, request=row[\"id\"], at=t.isoformat(), kind=\"rephrase\", value=again)\n    reply2, trace2 = one(row, t.isoformat(timespec=\"seconds\"), again)\n    if reply2 is not None and not right(reply2, row[\"topic\"]) and rng.random() < 0.6:\n        record(trace=trace2, request=row[\"id\"], at=(t + timedelta(seconds=20)).isoformat(),\n               kind=\"escalate\", value=\"asked for a person\")",
      "note": "Um cliente: pergunta, talvez dá nota, talvez pergunta de novo com outras palavras, talvez pede uma pessoa. O gerador tem como semente o id do pedido, então uma nova execução decide do mesmo jeito."
    },
    {
      "code": "telemetry.setup(a.spans, processors=[getattr(importlib.import_module(m), c)() for m, c in\n                                     (x.split(\":\") for x in a.processor)])\nrows = [r for r in map(json.loads, open(a.traffic)) if a.since <= r[\"at\"] < a.until]\nwith ThreadPoolExecutor(a.workers) as pool:\n    list(pool.map(person, rows))\nprint(f\"replayed {len(rows)} requests from {a.traffic}: {counts['requests']} asked, \"\n      f\"{counts['errors']} failed, {counts['feedback']} feedback events\")",
      "note": "Oito de cada vez, porque uma semana tocada pedido após pedido levaria uma hora."
    }
  ]
}
```

```
ana@lab:~/obs$ python replay.py
replayed 1127 requests from data/traffic.jsonl: 1345 asked, 0 failed, 483 feedback events
ana@lab:~/obs$ wc -l spans.jsonl feedback.jsonl
   7224 spans.jsonl
    483 feedback.jsonl
   7707 total
```

Os 1.127 pedidos do arquivo viraram 1.345 perguntas ao assistente: as outras 218 são clientes
perguntando de novo com outras palavras depois de uma resposta errada, o que as regras deixam 45%
deles fazer. Nada falhou. 7.224 spans foram para o `spans.jsonl` e 483 reações para o
`feedback.jsonl`: polegares, reformulações e pedidos de uma pessoa.

O primeiro trace a terminar, uma pergunta sobre pedido do começo da segunda-feira:

```
ana@lab:~/obs$ python tree.py --attrs $(head -1 spans.jsonl | python -c "import json,sys; print(json.load(sys.stdin)[\"trace\"])") | head -12
trace 4f220ffffbfefd61b9a1358979bbb5de   start(ms) took(ms)
      0     845 ms  ask
                     app.feature = "order"
                     app.release = "2026.09.4"
                     gen_ai.request.model = "extract-1"
                     user.hash = "e2d8b841e513bb07"
                     session.id = "s0008"
                     app.question = "Hi, I'm Joana Prado ([email]). My order [order] has not arrived after 12 working days. Is it lost?"
                     app.outcome = "refused"
                     app.reply = "I could not find that in our documents."
      0     268 ms    embed
                       gen_ai.operation.name = "embeddings"
```

A versão é a `2026.09.4`, a de antes de o piso subir, porque na segunda-feira, 28 de setembro, era a
versão em vigor; o `assistant.py` escolhe a versão pelo horário do pedido, não pelo de hoje. O
embedding levou 268 ms, quando o da aula 1 levou 56: oito pedidos estavam sendo reproduzidos ao mesmo
tempo, e o labembed atende um de cada vez. Isso é uma propriedade da reprodução, não da semana, e é
por isso que a aula 4 mede a latência nos spans do modelo e não no pedido inteiro.

É também uma recusa, sob o piso antigo. A aula 5 conta quantas vezes isso aconteceu com perguntas sobre
pedido, e por quê.

## Por que reproduzir, e não um teste de carga

Um teste de carga manda muitos pedidos para achar onde um sistema quebra. Uma reprodução manda **os
pedidos que aconteceram** para descobrir quanto custaram, quanto levaram e o que receberam de volta. A
diferença está na entrada: uma reprodução é tão representativa quanto o tráfego que ela toca, e o
tráfego aqui é uma semana que o curso inventou. Ela serve para o que este curso a usa: uma semana
fixa e repetível que toda aula seguinte pode medir, mudar e medir de novo, onde uma semana real de
produção nunca mais voltaria.
