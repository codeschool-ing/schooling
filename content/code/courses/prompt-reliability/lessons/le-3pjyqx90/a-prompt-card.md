---
title: A prompt card
version: 1
---

The decision records and the failure log are for somebody changing the prompt. The third note is
for somebody using it: a team that wants to point it at another inbox, the person on call when the
routing goes wrong, a manager asking what it costs. **They need one page, and they need it to say
how good the prompt is in numbers, including the numbers that are not flattering.**

The idea has a published precedent. *Model Cards for Model Reporting* (Mitchell and others, 2019)
proposed a short document to travel with every trained model: what it is for, what it should not be
used for, how it was evaluated and on what data, and its known limitations. A prompt is not a
trained model, but it is a component other people will build on without reading its insides, which
is exactly the situation a model card was written for.

## The numbers on the card

Every number on a card comes from a command, run on the version the card describes:

```
ana@lab:~/triage$ for s in dev holdout attacks pasted; do pl run prompts/triage.txt cases/$s.jsonl --out runs/$s.jsonl > /dev/null; printf "%-8s" $s; pl check runs/$s.jsonl | tail -n 1; done
dev     all          36     4
holdout all          11    19
attacks all           6     4
pasted  all           4     2
ana@lab:~/triage$ pl check runs/dev.jsonl --failures | tail -n 4
t14    urgency   normal, expected low
t24    urgency   low, expected normal
t28    urgency   normal, expected low
t37    category  billing, expected delivery
ana@lab:~/triage$ pl cost runs/dev.jsonl
tokens          count   per call
input           11859      296.5
cache_read          0        0.0
cache_write         0        0.0
output           1497       37.4

cost of these 40 calls: 5.8032 cents
cost of a million calls like them: 145,080 cents
```

The loop runs the prompt over each test set and keeps the last line of each check: passes, then
failures. The failures on dev are the known failure modes, one message at a time. `pl cost` turns
the tokens into money using the course's `prices.json`; lesson 16 explains how, and for the card
only the per-call figures and the last line matter.

## The card

| | `prompts/triage.txt` |
|---|---|
| purpose | Sort each message to Folio's support inbox into a category, an urgency and a one-sentence summary, as JSON for the routing program |
| not for | Replying to customers, or messages in any language but English: no test set has them |
| owner | Ana Lima |
| version | id `c1916fcd`, commit `03e1151` |
| model and parameters | the lab's stand-in at temperature 0 and `max_tokens` 400, the harness's defaults; neither is written in the file yet, which lesson 14 says to fix |
| scores | dev 36/40, holdout 11/30, attacks 6/10, pasted 4/6 |
| known failures | urgency on the line between low and normal (`t14`, `t24`, `t28`); a late order pulled to billing by the first example (`t37`); much weaker on the harder holdout messages |
| cost | 296.5 input and 37.4 output tokens a call; 145,080 cents a million calls at `prices.json` |
| decisions and failures | 0001 examples are JSON; F-0001 the plain-line examples |

**The most important line is the holdout score.** Thirty-six of forty on dev reads as a finished
prompt, and eleven of thirty on harder messages says it is not. A card that printed only the dev
number would be true and would mislead everybody who read it. The *not for* line does the same
job in words: it states the edges of what was tested, so nobody discovers them in production.

## Keeping it true

A card is a claim about one version. When the prompt changes and the card does not, it describes a
prompt that no longer exists, and nothing about it looks stale. Two habits prevent that.

- **Produce the numbers with the same commands the gate runs**, and update the card in the same
  change that alters the prompt. The gate already computed them; copying them is a minute's work.
- **Put the version on the card**, the prompt id and the commit. A reader comparing it with
  `pl run`'s output can tell at once whether the card is about the file in front of them.
