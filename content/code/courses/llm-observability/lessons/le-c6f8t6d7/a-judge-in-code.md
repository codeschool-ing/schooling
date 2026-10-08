---
title: A judge, in code
version: 1
---

Lesson 8 ended where rules stop: whether a reply answers the question, and whether what it says is true
of its sources. The usual instrument for those is a second model, asked to read the question, the reply
and the sources and say pass or fail. It is called **LLM-as-judge**, and `rag` lesson 8 and
`prompt-reliability` lesson 13 describe the method and its known biases. This lesson is about using one
on **live traffic**, where there is no answer key, and about what that costs.

Live traffic decides which criteria are possible. **Correctness** needs an expected answer, and a
customer's question has none. **Relevance**, does the reply address the question, and **faithfulness**,
is everything it says supported by the sources it was given, need only what the trace already holds.
Those two are what a judge can do on production.

`judge.py` asks the judge for one criterion at a time and traces the call like any other model call:

```python
"""judge.py: a model asked to grade one reply on one criterion, with the call traced and priced like any other.

    import judge
    verdict = judge.grade("relevance", question, reply, sources)   # {"criterion", "score", "verdict", "reason"}

The judge is llama3.2:3b, the same model that writes the replies, through the
same Ollama: the judge a team has when it has one model. It is asked at
temperature 0, so that the same reply is graded the same way twice as far as
the model allows. A reply it grades in a shape this file cannot read comes back
with the verdict "unreadable", never as a pass or a fail.
"""
import json

from openai import OpenAI

from telemetry import span

MODEL = "llama3.2:3b"
SYSTEM = """You grade replies written by Marginalia's help assistant to its customers.
Criterion: {criterion}
{rubric}
Reply with a JSON object and nothing else: {{"score": a number from 0 to 1, "verdict": "pass" or "fail", "reason": one sentence}}."""
RUBRIC = {
    "faithfulness": "Is every statement in the reply supported by the sources? A refusal states nothing and passes.",
    "relevance": "Does the reply address the question the customer asked?",
    "correctness": "Does the reply give the same answer as the expected one?",
}
client = OpenAI(max_retries=2, timeout=120)


def grade(criterion, question, reply, sources=(), expected=None):
    numbered = "\n".join(f"[{n}] {s['id']}\n{s['text']}" for n, s in enumerate(sources, 1))
    user = f"<question>{question}</question>\n<reply>{reply}</reply>\n<sources>\n{numbered}\n</sources>"
    if expected is not None:
        user += f"\n<expected>{expected}</expected>"
    with span(f"chat {MODEL}", **{"gen_ai.operation.name": "chat", "gen_ai.request.model": MODEL,
                                   "gen_ai.request.temperature": 0, "app.criterion": criterion}) as s:
        r = client.chat.completions.create(model=MODEL, temperature=0, response_format={"type": "json_object"},
                                           messages=[{"role": "system", "content": SYSTEM.format(
                                                         criterion=criterion, rubric=RUBRIC[criterion])},
                                                     {"role": "user", "content": user}])
        s.set_attribute("gen_ai.response.model", r.model)
        s.set_attribute("gen_ai.usage.input_tokens", r.usage.prompt_tokens)
        s.set_attribute("gen_ai.usage.output_tokens", r.usage.completion_tokens)
        text = r.choices[0].message.content
        try:
            verdict = json.loads(text)
            if verdict.get("verdict") not in ("pass", "fail"):
                raise ValueError
        except (ValueError, AttributeError):
            verdict = {"score": None, "verdict": "unreadable", "reason": text[:120]}
        s.set_attribute("app.verdict", verdict["verdict"])
    return {"criterion": criterion, **verdict}
```

**The model behind the prompt is judge-1, the lab's stand-in.** It does not read: it measures the
similarity of embeddings, by rules written at the top of `lab/labobs.py`, and answers in the shape the
prompt asks for. The prompt is the one a team would send a real model. Every number this lesson draws
from it (how many replies were graded, what that cost, how sure a sample can be) is a property of
sampling and of the bill, not of how clever the judge is.

The week's replies come from the spans: `traffic.py` rebuilds each one as a record with its question,
its reply, its sources (from the chunk ids, as in lesson 8) and the thumb, if there was one:

```python
"""week.py: the week's replies as records to grade: question, reply, sources, release, and the thumb if any."""
import json
from collections import defaultdict

text = {c["id"]: c["text"] for c in json.load(open("data/index.json"))["chunks"]}
thumbs = {f["trace"]: f["value"] for f in map(json.loads, open("feedback.jsonl")) if f["kind"] == "thumbs"}


def replies(path="spans.jsonl"):
    by = defaultdict(dict)
    for s in map(json.loads, open(path)):
        by[s["trace"]][s["name"]] = s
    for trace, spans in sorted(by.items(), key=lambda kv: kv[1]["ask"]["start"]):
        a = spans["ask"]["attributes"]
        if a["app.feature"] == "summary":
            continue
        yield {"trace": trace, "release": a["app.release"], "feature": a["app.feature"],
               "question": a["app.question"], "reply": a["app.reply"], "outcome": a["app.outcome"],
               "sources": [{"id": c, "text": text[c]} for c in spans["search"]["attributes"].get("app.search.chunks", [])],
               "thumb": thumbs.get(trace)}
```

One reply, two criteria:

```python
"""one.py: one reply of the week, graded on two criteria by the judge."""
import judge
import telemetry
import week

telemetry.setup("judge-spans.jsonl", service="judge")
r = next(r for r in week.replies() if r["question"] == "Who pays for the return postage?")
print(r["question"], "->", r["reply"])
for criterion in ("relevance", "faithfulness"):
    print(criterion, judge.grade(criterion, r["question"], r["reply"], r["sources"]))
```

```
ana@lab:~/obs$ python one.py
Above what order value is standard delivery free? -> Express delivery is not free at any order value. [1] standard three to five working days 4.90, free on orders over 40 [2] pickup point three to five working days 2.90, free on orders over 40 [2]
relevance {'criterion': 'relevance', 'score': 0.64, 'verdict': 'pass', 'reason': 'similarity of question and reply 0.64, threshold 0.4'}
faithfulness {'criterion': 'faithfulness', 'score': 1.0, 'verdict': 'pass', 'reason': '1 of 1 sentences supported'}
```

The reply is the one lesson 1 explained from its trace, and lesson 8 could not fault: the customer asked
about standard delivery and the reply starts with express. **judge-1 passes it on both criteria.** It is
relevant, with a similarity of 0.64 to the question, because it shares the question's words; and it is
faithful, because every sentence is in a source. Both verdicts are exactly what judge-1's rules say,
and both describe a blind spot a real judge has too, less crudely: a reply that echoes the question's
vocabulary reads as relevant. Lesson 10 measures how often judge-1 and people disagree, and this reply
is the kind they disagree about.
