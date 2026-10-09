---
title: Three prompts that agree too much
version: 2
---

The obvious ensemble is three prompts you already have. `v3-examples`, `v4-only-json` and
`v6-escaped` were each written to fix something, and they are worded differently. A vote needs a
program to count it, and this one is short. It reads each reply's category, counts it right only
when the reply parses and matches the person's label, and takes the majority per case. A reply that
does not parse casts no ballot. Save it as `vote.py`:

```python
"""vote: the category each run gave each case, and what a majority of them
says. Several run files vote as one voter each; one run file with samples
votes with its samples."""
import collections
import sys

from pl import parse, read_jsonl


def answers(path):
    """case -> the categories its replies gave, None for a reply that does not parse."""
    found = collections.defaultdict(list)
    for r in read_jsonl(path):
        found[r["case"]].append((parse(r["text"]) or {}).get("category"))
    return found


paths = sys.argv[1:]
runs = [answers(p) for p in paths]
expect = {c["id"]: c["expect"]["category"] for c in read_jsonl(read_jsonl(paths[0])[0]["cases"])}
if len(runs) == 1:
    ballots = runs[0]
    voters = ["sample %d" % n for n in range(len(next(iter(ballots.values()))))]
    columns = [{k: v[n] for k, v in ballots.items()} for n in range(len(voters))]
else:
    voters = paths
    columns = [{k: v[0] for k, v in run.items()} for run in runs]
    ballots = {k: [col[k] for col in columns] for k in expect}

for name, col in zip(voters, columns):
    print("%-24s %3d/%d right" % (name, sum(col[k] == expect[k] for k in expect), len(expect)))
majority = unanimous = ties = 0
for k in expect:
    counts = collections.Counter(b for b in ballots[k] if b is not None).most_common()
    if len(counts) > 1 and counts[0][1] == counts[1][1]:
        ties += 1
    elif counts and counts[0][0] == expect[k]:
        majority += 1
    unanimous += len(set(ballots[k])) == 1
print("%-24s %3d/%d right" % ("majority of %d" % len(columns), majority, len(expect)))
print("unanimous on %d cases, a tie on %d" % (unanimous, ties))
```

Run the three prompts over all seventy cases and vote:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/all.jsonl --out runs/v3.jsonl
70 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/v3.jsonl
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/all.jsonl --out runs/v4.jsonl
70 calls, prompt 651820d7, llama3.2:3b, written to runs/v4.jsonl
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl
70 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/v6.jsonl
ana@lab:~/triage$ python3 vote.py runs/v3.jsonl runs/v4.jsonl runs/v6.jsonl
runs/v3.jsonl             54/70 right
runs/v4.jsonl             45/70 right
runs/v6.jsonl             45/70 right
majority of 3             49/70 right
unanimous on 47 cases, a tie on 3
```

The three score 54, 45 and 45. The majority scores **49, five fewer than `v3-examples` on its
own**. Three tries at the question did worse than the best one of them.

The arithmetic of the last section explains part of that, before any measuring. With voters right
54, 45 and 45 times in seventy, and independent of each other, a majority would be right about 0.77
of the time, near 54. **A vote of one strong voter and two weaker ones is at best as good as the
strong one**, because the two weaker ones outvote it every time they agree. Here they agreed more
often than chance would have them.

## Where the votes went

Count, for each case, how many of the three got it wrong:

```
ana@lab:~/triage$ for r in v3 v4 v6; do pl check runs/$r.jsonl --failures | awk '$2 == "json" || $2 == "category" {print $1}'; done | sort | uniq -c | sort -rn
      3 t26
      3 t25
      3 t22
      3 h27
      3 h23
      3 h21
      3 h11
      3 h07
      3 h06
      3 h05
      3 h03
      3 h01
      2 t38
      2 t31
      2 t19
      2 t06
      2 h30
      2 h28
      2 h22
      2 h19
      2 h17
      2 h12
      1 t39
      1 t37
      1 t36
      1 t33
      1 t10
      1 t01
      1 h26
      1 h24
      1 h16
      1 h08
```

The loop prints every case that failed `json` or `category` under each prompt, and `uniq -c`
counts how many prompts each one failed under. Ten cases were wrong under one prompt only, and the
vote fixed every one of them. Ten were wrong under two. **Twelve were wrong under all three**, and
there no vote can do anything.

Voters this accurate, if they were independent, would all be wrong on the same case about 2 times
in seventy. These three did it twelve times:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Seventy cases by how many of three prompts got each one wrong. If the three, right 54, 45 and 45 times in 70, were independent: 22.3 cases with none wrong, 31.4 with one, 14.2 with two, 2.0 with all three. The three prompts measured: 38 with none wrong, 10 with one, 10 with two, 12 with all three.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">70 cases, by how many of the three got each one wrong</text><text x=\"200\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">none</text><rect x=\"163\" y=\"169.7\" width=\"34\" height=\"80.3\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"180.0\" y=\"160.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">22.3</text><rect x=\"203\" y=\"113.2\" width=\"34\" height=\"136.8\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"220.0\" y=\"104.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">38</text><text x=\"335\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one</text><rect x=\"298\" y=\"137.0\" width=\"34\" height=\"113.0\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"315.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">31.4</text><rect x=\"338\" y=\"214.0\" width=\"34\" height=\"36.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"355.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"470\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">two</text><rect x=\"433\" y=\"198.9\" width=\"34\" height=\"51.1\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"450.0\" y=\"189.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14.2</text><rect x=\"473\" y=\"214.0\" width=\"34\" height=\"36.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"490.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"605\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">all three</text><rect x=\"568\" y=\"242.8\" width=\"34\" height=\"7.2\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"585.0\" y=\"233.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.0</text><rect x=\"608\" y=\"206.8\" width=\"34\" height=\"43.2\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"625.0\" y=\"197.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><path d=\"M110 250 L660 250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"200\" y=\"288\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"218\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">if independent</text><rect x=\"420\" y=\"288\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"438\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">these three</text></svg>", "caption": "Independent voters would spread their mistakes across cases, where a majority can outvote them. These three prompts piled theirs onto the same twelve cases, where no vote can help."}
```

The cases wrong under two prompts are where the vote lost to `v3-examples`. Write each prompt's
failures to a file, then ask `comm` for the cases `v4-only-json` and `v6-escaped` both got wrong
and `v3-examples` got right, and for the reverse:

```
ana@lab:~/triage$ for r in v3 v4 v6; do pl check runs/$r.jsonl --failures | awk '$2 == "json" || $2 == "category" {print $1}' | sort > runs/$r.wrong; done
ana@lab:~/triage$ comm -12 runs/v4.wrong runs/v6.wrong | comm -23 - runs/v3.wrong | paste -sd " "
h12 h17 h22 h28 h30 t06 t19 t31 t38
ana@lab:~/triage$ comm -23 runs/v3.wrong <(sort -m runs/v4.wrong runs/v6.wrong) | paste -sd " "
h08 h16 t33
```

Nine cases went one way and three the other. Of the nine, five were outvoted. Three were ties,
because the two weaker prompts did not agree on the wrong answer, or one of them did not parse, and
`vote.py` counts a tie as wrong. And `t38` survived: neither weaker prompt's reply parsed, so the
only ballot was `v3-examples`'s, and it was right. The three cases going the other way, `h08`,
`h16` and `t33`, are where the vote did its job. Five lost to outvoting, three to ties, three won
back: 54 − 8 + 3 = 49.

## Why they agree

All three prompts are read by the same model. **Prompts sent to the same model tend to share its
mistakes**, because what the model gets wrong about a message, it gets wrong under most wordings.
Nine of the twelve are holdout cases, the harder messages, which is where a shared blind spot
would show.

That is a practitioner's observation, and the twelve here are one measurement of it, not a proof.
What it means in practice: diversity has to come from somewhere real, such as a different model,
different evidence in the prompt, or a different way of reaching the answer. Three rewordings of
one prompt are closer to one voter counted three times than to three voters.
