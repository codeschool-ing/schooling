---
title: Measuring it, honestly
version: 1
---

Both prompts, over all seventy cases, the forty of the development set and the thirty harder ones
held out:

```
ana@lab:~/triage$ wc -l cases/all.jsonl
70 cases/all.jsonl
ana@lab:~/triage$ pl run prompts/v8-rules.txt cases/all.jsonl --out runs/rules.jsonl
70 calls, prompt 65da61bb, written to runs/rules.jsonl
ana@lab:~/triage$ pl run prompts/v8-guide.txt cases/all.jsonl --out runs/guide.jsonl
70 calls, prompt d0591569, written to runs/guide.jsonl
ana@lab:~/triage$ pl check runs/rules.jsonl
check      pass  fail
json         65     5
fields       65     5
labels       65     5
category     54    16
urgency      45    25
all          45    25
ana@lab:~/triage$ pl check runs/guide.jsonl
check      pass  fail
json         64     6
fields       64     6
labels       64     6
category     53    17
urgency      43    27
all          43    27
ana@lab:~/triage$ pl compare runs/rules.jsonl runs/guide.jsonl
runs/rules.jsonl         passes 45/70
runs/guide.jsonl         passes 43/70
fixed 3, broken 5, still passing 40, still failing 22
broken: t05 t06 t21 t32 t36
sign test on the 8 that changed: p = 0.727
ana@lab:~/triage$ pl compare runs/rules.jsonl runs/guide.jsonl --answers
70 cases, same answer 70, different answer 0
```

The rules pass 45 and the guide 43. Eight messages changed, three one way and five the other, and
the sign test says a split like that turns up about three times in four by chance (p = 0.727). The
categories are identical on all seventy. **By every number here, the two prompts are the same
prompt**, and the two-message gap is the wrapping habits, reshuffled onto different replies as lesson 2
showed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Seventy messages, one square each, compared between the prompt with thirteen rules and the prompt that explains its categories. 40 pass under both and 22 fail under both, and those 62 say nothing about which prompt is better. 3 pass only under the explained prompt and 5 only under the rules. Only those 8 are evidence, and they split 3 to 5.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">70 messages, rules against guide</text><rect x=\"20\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"46\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"72\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"98\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"124\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"150\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"176\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"202\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"228\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"254\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"280\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"306\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"332\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"358\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"20\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"46\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"72\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"98\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"124\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"150\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"176\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"202\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"228\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"254\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"280\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"306\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"332\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"358\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"20\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"46\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"72\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"98\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"124\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"150\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"176\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"202\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"228\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"254\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"280\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"306\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"332\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"358\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"46\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"72\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"98\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"124\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"150\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"176\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"202\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"228\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"254\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"280\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"306\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"332\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"358\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"46\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"72\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"98\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"124\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"150\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"176\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"202\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"228\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"254\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"280\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"306\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"332\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"358\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"408\" y=\"46\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"428\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pass under both</text><rect x=\"408\" y=\"74\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fail under both</text><rect x=\"408\" y=\"102\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"428\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pass only with the guide</text><rect x=\"408\" y=\"130\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"428\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pass only with the rules</text><text x=\"408\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">evidence: 8 of 70</text></svg>", "caption": "Sixty-two messages came out the same under both prompts and carry no evidence either way. The eight that changed split three to five, which a fair coin does about three times in four."}
```

## Why the stand-in cannot tell them apart

That result says more about the stand-in than about explanations. **The stand-in does not read
meaning.** It sorts by keywords, judges urgency from a short list of phrases, and takes from a prompt
only a handful of words it scans for, such as the label lists, JSON, or an instruction to be brief
or thorough. A reason is not among them. Neither, for that matter, are these rules:

```
ana@lab:~/triage$ pl show runs/rules.jsonl t22
│ {
│   "category": "billing",
│   "urgency": "low",
│   "summary": "Asks: can I pay with a gift card and a credit card on the same order?"
│ }
stop: end, tokens in 208, out 42
```

`t22` came back low under the rules, which is right, and it is not because the stand-in weighed line
12 against line 13. It answers low to messages that open with *Can I*, from a list of openings it treats as
questions that can wait. The holdout has the messages
the guide's urgency sentence was written for, and the stand-in misses them under both prompts:

```
ana@lab:~/triage$ grep h03 cases/all.jsonl
{"id": "h03", "message": "My account shows an order I never placed and my card has been charged for it.", "expect": {"category": "billing", "urgency": "high"}}
ana@lab:~/triage$ pl check runs/guide.jsonl --failures | grep -e h03 -e h22
h03    urgency   normal, expected high
h22    urgency   normal, expected high
```

Charged for an order never placed is a customer out of pocket, which the guide says is high. The
stand-in has no phrase for it, so it said normal, under the guide as under the rules.

## What the measurement is for

On a real model, this comparison is the experiment that answers the question: the same seventy
cases, both prompts, compared message by message, with `h03` and `h22` among the messages to read
first. **This course has no number for how it comes out**, and nobody has one for your model and
your messages until they run it. A claim that explanations beat rules by some percentage, made
without the run, is a claim about somebody else's model and somebody else's test set.

What the lab can show is the discipline. A change you believe in measured as noise here, and the
right report of that is *no difference detected on seventy cases*, not *the guide is better* and not
*the guide does not work*. Lesson 11 is about building a test set big enough, and pointed enough, to
detect the differences you care about.
