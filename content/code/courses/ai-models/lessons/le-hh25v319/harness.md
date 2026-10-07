---
title: The harness
version: 1
---

The harness is the program that sends every case to every model, scores each reply, and keeps a
record of all of it. `evalkit.py` is a little over a hundred lines, and every part of it is a
decision worth seeing:

```schooling-example
{
  "language": "python",
  "file": "evalkit.py",
  "parts": [
    {
      "code": "\"\"\"evalkit: run a task's cases through several models, and score what came back.\"\"\"\nimport json\nimport math\nimport re\nimport sys\nimport time\n\nimport openai\n\nclient = openai.OpenAI()  # the address and the key come from desk.env\n\n\n",
      "note": "One client for every candidate. `desk.env` points it at Ollama; with a key, the same client reaches any provider that answers in this shape, which lesson 20 counts."
    },
    {
      "code": "def score_triage(answer, case):\n    strict = answer == case[\"label\"]\n    loose = answer.strip().lower().rstrip(\".\") == case[\"label\"]\n    return strict, loose\n\n\n",
      "note": "**Strict** is character for character. **Loose** forgives the untidiness section 04 showed: spaces, capitals, a full stop."
    },
    {
      "code": "def score_extract(answer, case):\n    try:\n        strict = json.loads(answer).get(\"order\") == case[\"order\"]\n    except (json.JSONDecodeError, AttributeError):\n        strict = False\n    found = re.search(r\"\\{.*\\}\", answer, re.S)\n    try:\n        loose = bool(found) and json.loads(found.group(0)).get(\"order\") == case[\"order\"]\n    except json.JSONDecodeError:\n        loose = False\n    return strict, loose\n\n\n",
      "note": "**Strict** is what `json.loads` accepts, whole. **Loose** fishes the first `{...}` out of the reply. Both then compare the order number with the case's."
    },
    {
      "code": "def run(task, models, out, temperature=0.0):\n    system = open(f\"prompts/{task}.txt\").read()\n    cases = [json.loads(line) for line in open(\"cases/triage.jsonl\")]\n    score = score_triage if task == \"triage\" else score_extract\n    with open(out, \"w\") as f:\n        for model in models:\n            for case in cases:\n                start = time.perf_counter()\n                r = client.chat.completions.create(\n                    model=model, max_tokens=50, temperature=temperature,\n                    messages=[{\"role\": \"system\", \"content\": system}, {\"role\": \"user\", \"content\": case[\"text\"]}])\n                answer = r.choices[0].message.content\n                strict, loose = score(answer, case)\n                f.write(json.dumps({\"task\": task, \"model\": r.model, \"case\": case[\"id\"], \"answer\": answer, \"strict\": strict,\n                                    \"loose\": loose, \"seconds\": round(time.perf_counter() - start, 3),\n                                    \"in\": r.usage.prompt_tokens, \"out\": r.usage.completion_tokens}) + \"\\n\")\n\n\n",
      "note": "Every case, every model, the same messages and settings. The raw answer is written with both scores, the time and the tokens, so scoring can change later without paying for the requests again."
    },
    {
      "code": "def wilson(k, n, z=1.96):\n    \"\"\"The 95% interval around k right out of n, by Wilson's formula.\"\"\"\n    p = k / n\n    centre = (p + z * z / (2 * n)) / (1 + z * z / n)\n    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / (1 + z * z / n)\n    return centre - half, centre + half\n\n\n",
      "note": "**Wilson's interval** for k right out of n. With forty cases it is wide, which is the point of printing it."
    },
    {
      "code": "def report(path):\n    rows = [json.loads(line) for line in open(path)]\n    print(f\"{'model':12} {'strict':>7} {'loose':>7} {'loose, 95%':>14} {'p50 s':>6} {'out tok':>8}\")\n    for model in dict.fromkeys(r[\"model\"] for r in rows):\n        mine = [r for r in rows if r[\"model\"] == model]\n        n, strict, loose = len(mine), sum(r[\"strict\"] for r in mine), sum(r[\"loose\"] for r in mine)\n        lo, hi = wilson(loose, n)\n        p50 = sorted(r[\"seconds\"] for r in mine)[n // 2]\n        out = sum(r[\"out\"] for r in mine) / n\n        print(f\"{model:12} {strict:>4}/{n} {loose:>4}/{n} {lo:>7.0%} to {hi:>4.0%} {p50:>6.2f} {out:>8.1f}\")\n\n\n",
      "note": "One line per model: both scores, the interval around the loose one, the median time, and how many tokens it wrote on average."
    },
    {
      "code": "def compare(path, a, b):\n    \"\"\"Cases where exactly one of the two models was right, and how likely that split is by chance.\"\"\"\n    rows = [json.loads(line) for line in open(path)]\n    right = {(r[\"model\"], r[\"case\"]): r[\"loose\"] for r in rows}\n    cases = [r[\"case\"] for r in rows if r[\"model\"] == a]\n    only_a = [c for c in cases if right[(a, c)] and not right[(b, c)]]\n    only_b = [c for c in cases if right[(b, c)] and not right[(a, c)]]\n    n, k = len(only_a) + len(only_b), min(len(only_a), len(only_b))\n    p = min(1.0, 2 * sum(math.comb(n, i) for i in range(k + 1)) / 2 ** n) if n else 1.0\n    print(f\"only {a} right: {len(only_a)} {only_a}\")\n    print(f\"only {b} right: {len(only_b)} {only_b}\")\n    print(f\"chance of a split at least this uneven if they were equally good: {p:.3f}\")\n\n\n",
      "note": "Only the cases where exactly one model was right say anything about the difference. If the two were equally good each would be a coin toss, and the last line is the chance of a split at least this uneven."
    },
    {
      "code": "def errors(path):\n    rows = [json.loads(line) for line in open(path)]\n    cases = {c[\"id\"]: c for c in map(json.loads, open(\"cases/triage.jsonl\"))}\n    for r in rows:\n        if not r[\"strict\"]:\n            want = cases[r[\"case\"]][\"label\" if r[\"task\"] == \"triage\" else \"order\"]\n            mark = \"loose ok\" if r[\"loose\"] else \"wrong\"\n            print(f\"{r['model']:12} {r['case']} {mark:8}  expected {want!s:15} got {r['answer']!r}\")\n\n\ndef gate(base, new, model, allowed=1):\n    \"\"\"Fail, with exit status 1, if model's new run is worse than its baseline by more than allowed cases.\"\"\"\n    def score(path):\n        return sum(json.loads(line)[\"loose\"] for line in open(path) if json.loads(line)[\"model\"] == model)\n    before, after = score(base), score(new)\n    verdict = \"pass\" if after >= before - int(allowed) else \"FAIL\"\n    print(f\"{model}: {before} before, {after} now, {int(allowed)} allowed: {verdict}\")\n    sys.exit(0 if verdict == \"pass\" else 1)\n\n\n",
      "note": "`errors` lists every reply that was not strictly right, with what was expected. `gate` turns a comparison with the baseline into an exit status a script can act on."
    },
    {
      "code": "if __name__ == \"__main__\":\n    cmd, *args = sys.argv[1:]\n    if cmd == \"run\":\n        task, out, temperature, models = args[0], args[1], float(args[2]), args[3:]\n        run(task, models, out, temperature)\n    else:\n        {\"report\": report, \"compare\": compare, \"errors\": errors, \"gate\": gate}[cmd](*args)\n",
      "note": "The command line: `run`, `report`, `compare`, `errors` and `gate`."
    }
  ]
}
```

Two choices in it are worth naming.

**It talks to every model through one API.** All three candidates are called through the OpenAI
SDK's Chat Completions, with the same messages, the same `max_tokens` and the same temperature.
OpenAI's own documentation now prefers a newer name for the cap, `max_completion_tokens`, and Ollama
ignores that one without a word; `max_tokens` is the one both read. Lesson 20
shows how far that reaches: many providers accept this shape. When a candidate needs its own SDK,
the harness grows a second way of making the request, and everything after it stays the same.

**It records before it judges.** Each line of `runs/*.jsonl` holds the raw answer, both scores, the
time and the tokens. Scoring can be changed later and re-applied to the same answers without paying
for the requests again, and an argument about a case can be settled by reading what the model
actually wrote.

## Running it

```
ana@desk:~/desk$ time python evalkit.py run triage runs/triage.jsonl 0 llama3.2:3b qwen2.5:3b llama3.2:1b

real	1m47.419s
user	0m0.914s
sys	0m0.054s
```

A hundred and twenty requests, forty per model, one after another, in under two minutes: a little
under a second each, on a processor with no graphics card. What it wrote:

```
ana@desk:~/desk$ wc -l runs/triage.jsonl; head -2 runs/triage.jsonl
120 runs/triage.jsonl
{"task": "triage", "model": "llama3.2:3b", "case": "c01", "answer": "order-status", "strict": true, "loose": true, "seconds": 1.19, "in": 91, "out": 3}
{"task": "triage", "model": "llama3.2:3b", "case": "c02", "answer": "refund", "strict": true, "loose": true, "seconds": 0.889, "in": 93, "out": 2}
```

One line per reply, and everything sections 06 to 10 report comes from reading these lines back.
