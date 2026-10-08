---
title: What grading costs
version: 2
---

Every judge call in this lesson went through `judge.py`, which wraps it in a span named
`chat llama3.2:3b` with the model and the tokens on it, exactly as the assistant's own calls are. So
the price of grading comes from the same place as the price of serving, by the same `costs.py` that
lesson 3 wrote, at the same course-written prices:

```python
"""judge_cost.py: what the grading cost, from the judge's own spans, beside what the assistant cost."""
import costs

judged = costs.requests("judge-spans.jsonl")
served = costs.requests("spans.jsonl")
cost = lambda rs: sum(r["cost"] for r in rs)
print(f"judge calls  {len(judged):5}   input {sum(r['input'] for r in judged):7}   output {sum(r['output'] for r in judged):6}"
      f"   US$ {cost(judged):.6f}   per call {cost(judged) / len(judged):.8f}")
print(f"assistant    {len(served):5}   input {sum(r['input'] for r in served):7}   output {sum(r['output'] for r in served):6}"
      f"   US$ {cost(served):.6f}   per request {cost(served) / len(served):.8f}")
```

```
ana@dev:~/obs$ python judge_cost.py
judge calls    510   input  112728   output  23391   US$ 0.309438   per call 0.00060674
assistant      311   input   53240   output   8005   US$ 0.143428   per request 0.00046118
```

The 510 calls are everything this lesson graded: the whole week once (275), the three samples (23,
120 and 90) and the two criteria of the first reply. Together they cost **US$0.31**, against **US$0.14**
for the 311 requests the assistant served in the same week. Grading cost twice what serving did.

Per call it is the same story. **One judgement costs 0.00060674 dollars; one request cost 0.00046118.**
Grading one reply on one criterion costs a third more than writing it. Two things set that number, and
both can be moved:

- **The judge's price per token.** Here the judge is the model it grades, at the same price. A judge
  that is cheaper per token than the assistant, a smaller model or a cheaper provider, brings the ratio
  down in proportion, and a larger judge, which reads a rubric more carefully, pushes it up.
- **The judge's prompt.** It carries the question, the reply and every source, so it is long: 221
  input tokens a call on average, against 171 for a whole request of the assistant. The relevance
  rubric never asks about the sources, and they still travel with every relevance call. Sending only
  what the rubric reads is the cheapest saving there is.

And on your own machine the price is **time**. Five and a half seconds a judgement, one at a time, on
the processor the assistant also needs: grading the whole week took 25.6 minutes, during which the
assistant would have answered more slowly.

## Where the money goes

The week's serving bill was US$0.14, and one judgement costs 0.00060674. The arithmetic of a policy
is short:

| Policy | Judge calls in the week | Grading as a share of serving |
| --- | --- | --- |
| Every reply, three criteria | 825 | about 350% |
| Every reply, one criterion | 275 | about 115% |
| Stratified, 30 per group, three criteria | 360 | about 150% |
| Targeted, one criterion | 90 | about 40% |

Only the second and fourth rows were run; the others are the same price per call multiplied out. The
summaries are never graded here, which is why every reply on one criterion comes to a little more than
the bill rather than a third more than it. With a judge as dear as the assistant, every policy that
covers the whole week costs more than the week did, and the only cheap ones are the small samples. The
table shows the shape of the choice: decide what each number is for, then grade the fewest replies that
answer it.

## The judge is a feature too

The judge's spans carry `app.criterion` and nothing marks them as the assistant's, so here they
sit in a file of their own. In production they share the trace store with everything else, and
they should carry a feature of their own, such as `evaluation`, so that lesson 3's cost by feature
shows grading as a line beside help, order and summary. A cost nobody can see grows without anybody
deciding it should: a sampling rate raised for one investigation and never lowered again is the
usual way.

Lesson 16 puts the grading on a dashboard beside the traffic, with its cost.
