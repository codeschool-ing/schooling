---
title: Steps, tokens, seconds and money
version: 2
---

A budget is a limit the host counts while the agent runs. `agent.py` counts three, and a fourth follows from them:

| budget | counted as | protects against |
|---|---|---|
| steps | requests sent to the model | loops; a model that never calls `finish` |
| tokens | input plus output, summed over the requests | a run whose conversation grows without bound |
| seconds | wall-clock time since the run started | a customer waiting; a queue backing up |
| money | tokens times the price of each | the bill; lesson 18 turns tokens into cents |

The same task, run three more times with `llama3.2:3b` and limits set low enough to fire on this model, which takes one step before it stops by itself:

```
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?" --max-steps 1
[1] find_books({"genre": "adventure", "max_results": 10}) -> [{"id": "b31", "title": "Moby-Dick", "author": "Herman Melvi
[1] get_order({"order_id": "M-1045"}) -> {"id": "M-1045", "customer_id": "c-104", "placed_on": "2026-
{
 "status": "stopped",
 "reason": "step limit: 1",
 "done": [],
 "not_done": [],
 "handoff": "Passed to a person. No plan was written."
}
```

```
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?" --max-tokens 500
[1] find_books({"genre": "adventure", "max_results": null}) -> ERROR invalid arguments: max_results: None is not of type 'integer
[1] get_order({"order_id": "M-1045"}) -> {"id": "M-1045", "customer_id": "c-104", "placed_on": "2026-
{
 "status": "answered",
 "steps": 1,
 "tokens": 583,
 "answer": "Find an adventure book for your nephew, such as “The Jungle Book” by Rudyard Kipling, and check the status of your order M-1045, which is on its way.",
 "sources": [
  "find_books",
  "get_order"
 ]
}
```

```
ana@lab:~/agents$ python recorder.py &
ana@lab:~/agents$ export ANTHROPIC_BASE_URL=http://127.0.0.1:11435
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?" --max-seconds 2
[1] find_books({"max_results": null, "genre": "adventure"}) -> ERROR invalid arguments: max_results: None is not of type 'integer
[1] get_order({"order_id": "M-1045"}) -> {"id": "M-1045", "customer_id": "c-104", "placed_on": "2026-
{
 "status": "stopped",
 "reason": "time budget: 2.0 s",
 "done": [],
 "not_done": [],
 "handoff": "Passed to a person. No plan was written."
}
ana@lab:~/agents$ python -c 'import json; [print(r["usage"]["output_tokens"], "output tokens in", r["ms"], "ms") for r in map(json.loads, open("requests.jsonl"))]'
1024 output tokens in 119835 ms
```

The step limit and the time budget stopped their runs before the second request, and **each reason names the limit and the number**, so whoever reads the outcome knows what to raise if raising it is right. The token budget never fired: the model called `finish` in its first reply, in the same reply as its two lookups, so the run ended at 583 tokens before the check that would have caught it could run. Its answer recommends *The Jungle Book*, which Marginalia does not sell, and says M-1045 is on its way, which it is not: both were written before either lookup returned. The host took them, because nothing in `agent.py` refuses a `finish` that arrives beside other calls. Section 05 comes back to that.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The loop with its budget. Before every request the host checks three counters: steps taken, tokens used and seconds elapsed. If any is at its limit, the run stops and returns what was done and what was not, for a person to pick up. Otherwise the request goes to the model, whose reply either calls finish, which ends the run with an answer, or calls tools, whose results go back into the conversation before the next check.\"><defs><marker id=\"l5budget-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l5budget-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l5budget-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"30\" y=\"90\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">budget check</text><text x=\"40\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">steps · tokens · seconds</text><rect x=\"270\" y=\"90\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the model</text><text x=\"280\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one request</text><rect x=\"500\" y=\"20\" width=\"190\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">finish</text><text x=\"510\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">answered</text><rect x=\"500\" y=\"100\" width=\"190\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"117.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tools</text><text x=\"510\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">results appended</text><rect x=\"30\" y=\"190\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">stopped</text><text x=\"40\" y=\"221.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">handoff to a person</text><path d=\"M200 120 L270 120\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-wire)\"></path><text x=\"235\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ok</text><path d=\"M420 110 L500 45\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-phosphor)\"></path><path d=\"M420 125 L500 125\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-wire)\"></path><path d=\"M595 150 L595 175 L115 175 L115 150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-wire)\"></path><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">next step</text><path d=\"M60 150 L60 190\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-amber)\"></path><text x=\"66\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">limit</text></svg>", "caption": "The check comes before the request, so a run can overshoot by at most one step."}
```

## The check comes before the request

The time budget was 2 seconds, and the recorder's line says the first request alone took 119835 ms, two minutes: the model wrote 1024 tokens, the most `agent.py` allows in one reply, before it stopped. `agent.py` checks its budgets **before** each request and cannot know in advance how long the next one will take or how large it will be, so the check after that first request was the first chance to stop, and it came 118 seconds late. **A budget checked between steps can be overrun by at most one step**, and the size of that step is the size of the overrun. For most agents that is acceptable and simple. Where it is not, the host can bound the step itself: a smaller `max_tokens` per reply, a timeout on the request, or, where the API offers one, a token count of the next request before sending it, refusing a request that would cross the line.

## Why three budgets and not one

They fail differently. A run of many tiny steps hits the step limit with few tokens used. A run that fetches one huge document hits the token budget in two steps. A run whose tools are slow, such as a web fetch or a long database query, hits the time budget while tokens and steps look modest. One limit would leave the other two failure modes open.
