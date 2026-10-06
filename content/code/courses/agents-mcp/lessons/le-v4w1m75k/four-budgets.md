---
title: Steps, tokens, seconds and money
version: 1
---

A budget is a limit the host counts while the agent runs. `agent.py` counts three, and a fourth follows from them:

| budget | counted as | protects against |
|---|---|---|
| steps | requests sent to the model | loops; a model that never calls `finish` |
| tokens | input plus output, summed over the requests | a run whose conversation grows without bound |
| seconds | wall-clock time since the run started | a customer waiting; a queue backing up |
| money | tokens times the price of each | the bill; lesson 18 turns tokens into cents |

The same task, run three more times with tighter limits:

```
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?" --max-steps 3
[1] plan
      [ ] Look up order M-1045
      [ ] Find adventure books in stock
      [ ] Answer both questions
[2] get_order({"order_id": "M-1045"}) -> {"id": "M-1045", "customer_id": "c-104", "placed_on": "2026-
[3] plan
      [x] Look up order M-1045
      [ ] Find adventure books in stock
      [ ] Answer both questions
[3] find_books({"genre": "adventure"}) -> [{"id": "b31", "title": "Moby-Dick", "author": "Herman Melvi
{
 "status": "stopped",
 "reason": "step limit: 3",
 "done": [
  "Look up order M-1045"
 ],
 "not_done": [
  "Find adventure books in stock",
  "Answer both questions"
 ],
 "handoff": "Passed to a person. Done: Look up order M-1045. Not done: Find adventure books in stock; Answer both questions."
}
```

```
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?" --max-tokens 1500
[1] plan
      [ ] Look up order M-1045
      [ ] Find adventure books in stock
      [ ] Answer both questions
[2] get_order({"order_id": "M-1045"}) -> {"id": "M-1045", "customer_id": "c-104", "placed_on": "2026-
[3] plan
      [x] Look up order M-1045
      [ ] Find adventure books in stock
      [ ] Answer both questions
[3] find_books({"genre": "adventure"}) -> [{"id": "b31", "title": "Moby-Dick", "author": "Herman Melvi
{
 "status": "stopped",
 "reason": "token budget: 1895 of 1500 used",
 "done": [
  "Look up order M-1045"
 ],
 "not_done": [
  "Find adventure books in stock",
  "Answer both questions"
 ],
 "handoff": "Passed to a person. Done: Look up order M-1045. Not done: Find adventure books in stock; Answer both questions."
}
```

```
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?" --max-seconds 1
[1] plan
      [ ] Look up order M-1045
      [ ] Find adventure books in stock
      [ ] Answer both questions
{
 "status": "stopped",
 "reason": "time budget: 1.0 s",
 "done": [],
 "not_done": [
  "Look up order M-1045",
  "Find adventure books in stock",
  "Answer both questions"
 ],
 "handoff": "Passed to a person. Not done: Look up order M-1045; Find adventure books in stock; Answer both questions."
}
ana@lab:~/agents$ tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; r = json.loads(sys.stdin.read()); print(r["usage"]["output_tokens"], "output tokens in", r["ms"], "ms")'
52 output tokens in 2282 ms
```

The step limit stopped the run after three requests, the token budget after three as well, and the time budget after one. **Each reason names the limit and the number**, so whoever reads the outcome knows what to raise if raising it is right.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The loop with its budget. Before every request the host checks three counters: steps taken, tokens used and seconds elapsed. If any is at its limit, the run stops and returns what was done and what was not, for a person to pick up. Otherwise the request goes to the model, whose reply either calls finish, which ends the run with an answer, or calls tools, whose results go back into the conversation before the next check.\"><defs><marker id=\"l5budget-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l5budget-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l5budget-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"30\" y=\"90\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">budget check</text><text x=\"40\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">steps · tokens · seconds</text><rect x=\"270\" y=\"90\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the model</text><text x=\"280\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one request</text><rect x=\"500\" y=\"20\" width=\"190\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">finish</text><text x=\"510\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">answered</text><rect x=\"500\" y=\"100\" width=\"190\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"117.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tools</text><text x=\"510\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">results appended</text><rect x=\"30\" y=\"190\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">stopped</text><text x=\"40\" y=\"221.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">handoff to a person</text><path d=\"M200 120 L270 120\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-wire)\"></path><text x=\"235\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ok</text><path d=\"M420 110 L500 45\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-phosphor)\"></path><path d=\"M420 125 L500 125\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-wire)\"></path><path d=\"M595 150 L595 175 L115 175 L115 150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-wire)\"></path><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">next step</text><path d=\"M60 150 L60 190\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-amber)\"></path><text x=\"66\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">limit</text></svg>", "caption": "The check comes before the request, so a run can overshoot by at most one step."}
```

## The check comes before the request

Look at the token run: `1895 of 1500 used`. The budget was exceeded, not met, because `agent.py` checks before each request and cannot know in advance how large the reply will be. After step 2 the total was under 1500, so step 3 was allowed; step 3 took the total to 1895; the check before step 4 stopped the run. **A budget checked between steps can be overrun by at most one step**, and the size of that step is the size of the overrun. For most agents that is acceptable and simple. Where it is not, the host can ask for the next request's size before sending it (Anthropic's API has a token-counting endpoint, and labllm implements it) and refuse a request that would cross the line.

The time budget behaves the same way. The last line of that transcript reads labllm's log: the first request wrote the plan, 52 tokens at 40 ms each after the first 200 ms, and took over two seconds. The check before the second request stopped the run with only the plan written.

## Why three budgets and not one

They fail differently. A run of many tiny steps hits the step limit with few tokens used. A run that fetches one huge document hits the token budget in two steps. A run whose tools are slow, such as a web fetch or a long database query, hits the time budget while tokens and steps look modest. One limit would leave the other two failure modes open.
