---
title: A judge, in code
version: 2
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

**The judge is `llama3.2:3b`, the model that wrote the replies.** That is the judge a team has when
it has one model, and it is the weakest arrangement there is: a model grading itself shares its own
blind spots, and a small model reads a rubric less carefully than a large one. The lesson uses it
anyway, for two reasons. It runs on your machine, so every number below is one you can reproduce. And
the questions this lesson asks, how many replies to grade, how sure the result is and what it costs,
are about sampling and the bill, and they have the same answers with a better judge. Lesson 10 measures
how often this judge agrees with people.

The week's replies come from the spans: `week.py` rebuilds each one as a record with its question,
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
r = next(r for r in week.replies() if "the customer pays" in r["reply"])   # the reply lesson 8 found
print(r["question"], "->", r["reply"])
for criterion in ("relevance", "faithfulness"):
    print(criterion, judge.grade(criterion, r["question"], r["reply"], r["sources"]))
```

CAPTURE:one

PROSE:one
