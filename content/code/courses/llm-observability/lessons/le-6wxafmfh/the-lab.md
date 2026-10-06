---
title: The lab, and what in it is real
version: 1
---

Every transcript in this course was recorded on one Linux machine, and the course carries the
script that builds it: `lab.sh`, beside `course.json`. It is the machine `rag` built, which is the
machine `embeddings-vectors` built, with one more room each time. `sudo bash lab.sh up` on Ubuntu
24.04 builds both of those first and then adds what observing a model in production needs. `sudo
bash lab.sh reset` puts the working directory back as it was before this lesson, and every lesson's
`captures.sh` starts with it.

The person at the keyboard is still ana, a developer at Marginalia, the online bookshop that does
not exist. At the end of `rag` she had a pipeline that answers customers' questions from the shop's
thirteen documents. In this course **it is in production**: customers type into it, the support team
uses it to summarise conversations, and nobody can say how well it is doing. That last part is what
the course is about.

## What is in the working directory

```
ana@lab:~/obs$ ls
assistant.py
auto.py
data
one_call.py
prices.json
redact.py
releases.json
telemetry.py
tree.py
ana@lab:~/obs$ wc -l data/traffic.jsonl data/eval.jsonl
  1127 data/traffic.jsonl
    30 data/eval.jsonl
  1157 total
```

`assistant.py` is the help assistant, and the rest of this lesson takes it apart. `telemetry.py`,
`redact.py` and `tree.py` are the small programs it leans on, and each is shown where it is first
used. `data/docs` holds rag's documents, unchanged, and `data/eval.jsonl` its thirty test questions,
which come back from lesson 8 onwards.

`data/traffic.jsonl` is **a week of requests**, 1,127 of them, from Monday 28 September to Sunday
4 October 2026: who asked, in which session, through which feature, and the words. It was generated
by `lab/traffic.py` from phrasings the course wrote, so it is a stand-in for a support queue, not a
measurement of one. Lesson 3 replays it through the assistant, and from then on the course has a
week of production to look at.

## The model, and why it is not one

```
ana@lab:~/obs$ curl -s http://127.0.0.1:8600/; echo
{"labobs": "ok", "models": ["extract-1", "extract-2", "judge-1"]}
```

**No language model was reachable from the machine this course was recorded on**, and an API key is
a bill a course cannot hand out. So the assistant talks to `labobs`, on port 8600, which speaks
OpenAI's Chat Completions API closely enough that the real `openai` SDK talks to it unmodified. It
serves three models, and none of them is a language model:

- **extract-1** is the model `rag` used throughout: it copies whole sentences out of the sources it
  is given, the ones whose embeddings are closest to the question, and cites them. Its rules are
  written at the top of `rag`'s `lab/labgen.py`.
- **extract-2** is the same with three numbers changed, standing in for a new version of a model.
  Lesson 14 is about changing to it.
- **judge-1** grades a reply by the similarity of its sentences to the sources, the question or an
  expected answer. Lessons 9 to 12 use it.

What `labobs` adds to `rag`'s provider is **time**. A provider takes a moment before the first token
and then a little longer for each one after it, and a request sometimes waits much longer than
usual. `labobs` waits by rules written at the top of `lab/labobs.py`: 180 ms plus a little for every
input token before the first token, 25 ms for each token after that, a random factor drawn per
request, and a rare cold start of four extra seconds. They are the course's numbers, not any
provider's, and lesson 4 looks at what they produce.

So every reply quoted in this course is extract-1's, every verdict judge-1's, and every timing
labobs'. What is real is everything around them: OpenTelemetry's SDK, the spans, the database, the
tracing tools in lessons 6 and 7, the evaluation frameworks in lesson 12, and every number those
compute.

## Releases

```
ana@lab:~/obs$ cat releases.json
{
  "2026.09.4": {"from": "2026-09-01T00:00:00", "model": "extract-1", "k": 3, "floor": 0.5},
  "2026.10.1": {"from": "2026-10-02T10:00:00", "model": "extract-1", "k": 3, "floor": 0.62}
}
```

The assistant reads its settings from `releases.json`: which model, how many chunks to retrieve (`k`)
and the similarity below which a chunk is not shown to the model (`floor`, which `rag` lesson 6
chose). Each release says from when it applies. On 2 October somebody raised the floor from 0.5 to
0.62, and it is still the release in force. Keep that in mind; lesson 5 finds out what it did.

## One question

```
ana@lab:~/obs$ python assistant.py "How long is a gift card valid?"
A gift card is valid for two years from the day it was bought. [1] Gift cards are valid for two years from purchase and cannot be exchanged for cash. [2]
trace 8caa5cd5a78cdc79d1b3e420a1e2399f
```

An answer, two citations and a trace id. The answer is right, and nothing on the screen says how
long it took, which documents it read, or what it cost. The next sections put that on record.
