---
title: Three prompts that agree too much
version: 1
---

The obvious ensemble is three prompts you already have. `v3-examples`, `v4-only-json` and
`v6-escaped` were each written to fix something, they are worded differently, and each is right
about 80% of the time on the full set:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/all.jsonl --out runs/v3.jsonl
70 calls, prompt 1d9c6ec4, written to runs/v3.jsonl
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/all.jsonl --out runs/v4.jsonl
70 calls, prompt 651820d7, written to runs/v4.jsonl
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl
70 calls, prompt fbc4c9b1, written to runs/v6.jsonl
ana@lab:~/triage$ pl vote runs/v3.jsonl runs/v4.jsonl runs/v6.jsonl
runs/v3.jsonl              56/70 right
runs/v4.jsonl              53/70 right
runs/v6.jsonl              56/70 right
majority of 3              58/70 right
unanimous on 54 cases, a tie on 0
```

`pl vote` reads each reply's category, counts it right only when the reply parses and matches the
person's label, and takes the majority per case. Two of the prompts score 56 of 70, exactly 80%, and
the third 53. The majority scores **58, two more than the best single prompt**. If the three were
independent, the arithmetic of the last section says a majority of 80% voters would be right on
about 0.896 × 70, nearly 63.

So the three are not independent. The way to see how far from it they are is to count, for each
case, how many of the three got it wrong:

```
ana@lab:~/triage$ for r in v3 v4 v6; do pl check runs/$r.jsonl --failures | awk '$2 == "json" || $2 == "category" {print $1}'; done | sort | uniq -c
      3 h01
      3 h04
      1 h06
      1 h07
      3 h11
      3 h13
      3 h14
      3 h15
      3 h16
      3 h19
      3 h20
      1 h22
      3 h26
      3 h27
      2 h28
      1 h30
      1 t08
      1 t19
      1 t22
      1 t26
      1 t37
      1 t39
```

The loop prints every case that failed `json` or `category` under each prompt, and `uniq -c`
counts how many prompts each one failed under. Ten cases were wrong under one prompt only, and
the vote fixed every one of them: the other two outvoted it. That includes replies that did not
parse, which cast no ballot at all. One case, `h28`, was wrong under two prompts, and the vote
followed them. **Eleven cases were wrong under all three**, and there a vote can do nothing.

Independent voters at 80% would put all three wrong on the same case about 0.008 of the time, half
a case in seventy. These three did it eleven times.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Seventy cases by how many of three prompts got each one wrong. If three voters right 80 percent of the time were independent: 35.8 cases with none wrong, 26.9 with one, 6.7 with two, 0.6 with all three. The three prompts measured: 48 with none wrong, 10 with one, 1 with two, 11 with all three.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">70 cases, by how many of the three got each one wrong</text><text x=\"200\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">none</text><rect x=\"163\" y=\"120.97599999999997\" width=\"34\" height=\"129.02400000000003\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"180.0\" y=\"111.97599999999997\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">35.8</text><rect x=\"203\" y=\"77.19999999999999\" width=\"34\" height=\"172.8\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"220.0\" y=\"68.19999999999999\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">48</text><text x=\"335\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one</text><rect x=\"298\" y=\"153.232\" width=\"34\" height=\"96.768\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"315.0\" y=\"144.232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">26.9</text><rect x=\"338\" y=\"214.0\" width=\"34\" height=\"36.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"355.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"470\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">two</text><rect x=\"433\" y=\"225.808\" width=\"34\" height=\"24.192\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"450.0\" y=\"216.808\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6.7</text><rect x=\"473\" y=\"246.4\" width=\"34\" height=\"3.6\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"490.0\" y=\"237.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"605\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">all three</text><rect x=\"568\" y=\"247.984\" width=\"34\" height=\"2.0160000000000005\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"585.0\" y=\"238.984\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.6</text><rect x=\"608\" y=\"210.4\" width=\"34\" height=\"39.6\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"625.0\" y=\"201.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11</text><path d=\"M110 250 L660 250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"200\" y=\"288\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"218\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">if independent</text><rect x=\"420\" y=\"288\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"438\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">these three</text></svg>", "caption": "Independent voters spread their mistakes across cases, where a majority can outvote them. These three prompts piled theirs onto the same eleven cases, where no vote can help."}
```

## Why they agree

In the stand-in the reason is visible: all three prompts are read by the same keyword table. A
message the stand-in misreads, it misreads under every wording, because the wording changes what
surrounds the message and not how the message is scored. All eleven are holdout cases, the harder
messages, which is where a shared blind spot would be.

Real models are not a keyword table, but the shape carries over as a practitioner's observation.
**Prompts sent to the same model tend to share its mistakes**, because what the model does not
know, it does not know under any wording. Diversity has to come from somewhere real, such as a
different model, different evidence in the prompt, or a different way of reaching the answer. Three
rewordings of one prompt are close to one voter counted three times.
