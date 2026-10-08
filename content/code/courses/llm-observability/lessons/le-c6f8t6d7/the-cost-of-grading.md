---
title: What grading costs
version: 1
---

Every judge call in this lesson went through `judge.py`, which wraps it in a span named `chat judge-1`
with the model and the tokens on it, exactly as the assistant's own calls are. So the price of grading
comes from the same place as the price of serving, by the same `costs.py` that lesson 3 wrote:

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
ana@lab:~/obs$ python judge_cost.py
judge calls   1865   input  459293   output  82050   US$ 0.314997   per call 0.00016890
assistant     1345   input  281072   output  46663   US$ 0.822803   per request 0.00061175
```

The 1,865 calls are everything this lesson graded: the whole week once (1,221), the three samples
(129, 120 and 393) and the two criteria of the first reply. Together they cost **US$0.31**, against
**US$0.82** for the 1,345 requests the assistant served in the same week.

Per call the comparison is sharper. **One judgement costs 0.00016890 dollars; one reply cost
0.00061175.** Grading one reply on one criterion adds 28% to what it cost to write. Two things set that
number, and both can be moved:

- **The judge's price per token.** judge-1 charges 0.40 and 1.60 dollars per million tokens, against
  extract-1's 1.50 and 6.00 from 1 October. A judge as expensive as the model it grades would cost more
  than the reply, because its prompt is longer.
- **The judge's prompt.** It carries the question, the reply and every source, so it is long: 246 input tokens a
  call on average, against 209 for a whole request of the assistant. The relevance rubric never asks about
  the sources, and they still travel with every relevance call. Sending only what the rubric reads is
  the cheapest saving there is.

## Where the money goes

The week's serving bill was US$0.82, and one judgement costs 0.00016890. The arithmetic of a policy
is short:

| Policy | Judge calls in the week | Grading as a share of serving |
| --- | --- | --- |
| Every reply, three criteria | 3,663 | about 75% |
| Every reply, one criterion | 1,221 | about 25% |
| Targeted, one criterion | 393 | about 8% |
| Stratified, 30 per group, three criteria | 360 | about 7% |

Only the second and third rows were run; the others are the same price per call multiplied out. The
summaries are never graded here, which is why every reply on one criterion comes to a quarter of the
bill rather than 28% of it. The table shows the shape of the choice: a small stratified sample on
every criterion costs less than a single criterion on everything, and says more, because it covers
faithfulness and correctness as well.

## The judge is a feature too

The judge's spans carry `app.criterion` and nothing marks them as the assistant's, so in this lab
they sit in a file of their own. In production they share the trace store with everything else, and
they should carry a feature of their own, such as `evaluation`, so that lesson 3's cost by feature
shows grading as a line beside help, order and summary. A cost nobody can see grows without anybody
deciding it should: a sampling rate raised for one investigation and never lowered again is the
usual way.

Lesson 16 puts the grading on a dashboard beside the traffic, with its cost.
