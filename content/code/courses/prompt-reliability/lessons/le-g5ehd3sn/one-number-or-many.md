---
title: One number or many
version: 1
---

With four kinds of metric on the table the temptation is to combine them: so much for format, so much
for accuracy, a little for tone, one score to compare versions by. **A single weighted score lets
one metric hide another**, and the two prompts below show how.

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/all.jsonl --out runs/v3-all.jsonl
70 calls, prompt 1d9c6ec4, written to runs/v3-all.jsonl
ana@lab:~/triage$ pl check runs/v3-all.jsonl
check      pass  fail
json         70     0
fields       70     0
labels       70     0
category     56    14
urgency      47    23
all          47    23
ana@lab:~/triage$ pl confusion runs/v3-all.jsonl
expected    billing delivery  returns  account    other    (bad)   recall
billing          14        0        1        1        0        0   0.88
delivery          2       12        0        0        0        0   0.86
returns           1        1       13        0        1        0   0.81
account           3        1        0       10        0        0   0.71
other             3        0        0        0        7        0   0.70
precision      0.61     0.86     0.93     0.91     0.88

accuracy 56/70 = 0.80
```

`v3-examples.txt` and `v6-escaped.txt` have the same category accuracy on the same seventy messages:
56 of 70, 0.80. Underneath, they are different prompts. Every `v3` reply parses, against 68 of 70 for
`v6`. But `v3` sorted 23 messages as billing and only 14 of them were, a billing precision of 0.61
against `v6`'s 0.87. Its first example is a billing message, and in the stand-in every example pulls
the messages that resemble it towards its label, the effect lesson 1 met in `t37`, here spread over
seventy messages.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four metrics for two prompts on all 70 messages. Replies that parse: 1.00 with three examples, 0.97 with tags and escaping. Category accuracy: 0.80 for both. Billing precision: 0.61 against 0.87. Account recall: 0.71 against 0.64.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">two prompts on the same 70 messages</text><text x=\"178\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">replies that parse</text><rect x=\"190\" y=\"50\" width=\"420.0\" height=\"14\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"624.0\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.00</text><rect x=\"190\" y=\"68\" width=\"408.0\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"624.0\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.97</text><text x=\"178\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">category accuracy</text><rect x=\"190\" y=\"104\" width=\"336.0\" height=\"14\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"624.0\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.80</text><rect x=\"190\" y=\"122\" width=\"336.0\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"624.0\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.80</text><text x=\"178\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">billing precision</text><rect x=\"190\" y=\"158\" width=\"255.7\" height=\"14\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"624.0\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.61</text><rect x=\"190\" y=\"176\" width=\"364.0\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"624.0\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.87</text><text x=\"178\" y=\"230\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">account recall</text><rect x=\"190\" y=\"212\" width=\"300.0\" height=\"14\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"624.0\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.71</text><rect x=\"190\" y=\"230\" width=\"270.0\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"624.0\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.64</text><path d=\"M190 44 L190 262\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"190\" y=\"272\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"208\" y=\"278\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">three examples  (v3)</text><rect x=\"390\" y=\"272\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"408\" y=\"278\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tags and escaping  (v6)</text></svg>", "caption": "The same accuracy, and two different prompts underneath it. Each one wins somewhere, and only the metrics side by side say where."}
```

Any score that weights format would pick `v3`. The billing team, receiving nine tickets a run that
belong to someone else, would pick `v6`. **Neither choice is wrong; hiding it inside one number is.**

## Side by side, with gates

Report the metrics next to each other, the same ones every time:

- format, as a rate of its own;
- accuracy, and recall and precision for the labels somebody depends on;
- the expensive cells by name, such as high urgency sorted normal;
- tone rule failures, and the safety counts in both directions.

Where one metric must not get worse, make it a **gate** rather than a weight: a release that sorts
one more urgent message as normal is refused, whatever happened to accuracy. A gate is a threshold
on one metric, so it cannot be bought back by a gain somewhere else. Lesson 14 keeps these numbers
beside each version of the prompt, so that a change is judged against all of them at once.
