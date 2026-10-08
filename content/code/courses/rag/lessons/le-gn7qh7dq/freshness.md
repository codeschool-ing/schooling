---
title: Freshness
version: 2
---

Marginalia's returns policy changed on 2 February 2026, from fourteen days to thirty and from paid to
free return postage. For a support assistant, the question is how long after the policy changed the
assistant started giving the new answer.

## With retrieval: re-embed what changed

In a RAG system the new policy is a new document. Cutting it into sections and embedding them is the
whole of the change, and `reindex_cost.py` counts and times it, rounding the time up to the second
because it changes a little from run to run:

```schooling-example
{
  "language": "python",
  "file": "reindex_cost.py",
  "parts": [
    {
      "code": "import glob\nimport math\nimport re\nimport time\n\nimport tiktoken\nfrom vectors import embed\n\nenc = tiktoken.get_encoding(\"cl100k_base\")\n\n\ndef cut(path):\n    return re.split(r\"\\n(?=## )\", open(path).read())[1:]",
      "note": "The same cut at `## ` headings as `sections.py`."
    },
    {
      "code": "one = cut(\"data/docs/returns-policy.md\")\nevery = [part for path in sorted(glob.glob(\"data/docs/*.md\")) for part in cut(path)]\nfor label, parts in ((\"the returns policy\", one), (\"every document\", every)):\n    start = time.perf_counter()\n    embed(parts)\n    seconds = time.perf_counter() - start\n    tokens = sum(len(enc.encode(p)) for p in parts)\n    print(f\"{label:20} {len(parts):3} sections  {tokens:5} tokens  under {math.ceil(seconds)} s\")",
      "note": "Embeds the one policy that changed, then the whole corpus, and prints how many sections, how many tokens a provider would bill and how long it took, rounded up to the second."
    }
  ]
}
```

```
ana@vm:~/rag$ python reindex_cost.py
the returns policy     9 sections    973 tokens  under 1 s
every document        92 sections   7855 tokens  under 3 s
```

**Under a second for the policy that changed, under three for the entire corpus**, on four processor
cores with a small model, and 973 tokens against 7,855, which is what a hosted provider would bill. A hosted embedding model would add network time and a few
cents; neither changes the order of magnitude. The new answer is live from the next question, and the
old one is gone the moment the old chunks leave the index, which is the subject of the section on
deleting.

The time is so short that the bottleneck is never the embedding. It is noticing that a document
changed. Lesson 5 records a hash of each chunk's text, so that a nightly job re-embeds exactly the
chunks whose text is different and nothing else.

## With fine-tuning: retrain

A fine-tuned model knows the old policy until a new model is trained without it. That means four steps.
Build a dataset that teaches the new facts, with enough examples to overwrite the old ones, which the
model learnt with the same strength. Run the training, which takes from minutes to hours on a
provider's service. Evaluate the new model against the old one so that nothing else broke. And
switch production to the new model's name.

None of those steps is hard, and all of them are a release. A team that would re-index a document the
afternoon it changed will batch fine-tuning runs weekly or monthly, and in between the model answers
with confidence from a policy that no longer applies. **The staleness of a fine-tuned model is
measured in release cycles, and that of a retrieval system in minutes.**

## The questions where freshness is everything

Some answers change faster than any release cycle: prices, delivery times during a carrier strike,
stock, the status of an outage. The warehouse runbook in this corpus asks support to put a delays
banner in the help centre when a carrier is down. A retrieval assistant reads that banner from the
next question; a fine-tuned one never learns it existed. For answers like these, even a nightly
re-index can be too slow, and lesson 2 sent the fastest-changing of them, an order's status, to a
live API call instead of any document.
