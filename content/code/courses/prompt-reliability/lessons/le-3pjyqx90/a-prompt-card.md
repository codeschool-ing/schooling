---
title: A prompt card
version: 2
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
dev     all          24    16
holdout all          15    15
attacks all           3     7
pasted  all           2     4
ana@lab:~/triage$ pl check runs/dev.jsonl --failures
check      pass  fail
json         38     2
fields       38     2
labels       38     2
category     35     5
urgency      24    16
all          24    16

t02    urgency   high, expected normal
t04    urgency   normal, expected high
t07    urgency   low, expected normal
t09    urgency   high, expected normal
t12    urgency   normal, expected high
t23    urgency   normal, expected high
t24    urgency   high, expected normal
t25    category  other, expected account
t26    category  account, expected billing
t28    urgency   normal, expected low
t32    urgency   high, expected normal
t33    category  delivery, expected returns
t36    urgency   low, expected high
t37    json      not a JSON object
t38    json      not a JSON object
t39    urgency   low, expected normal
ana@lab:~/triage$ python3 stats.py runs/dev.jsonl
runs/dev.jsonl, 40 calls
  tokens in    mean  306.1   total  12246
  tokens out   mean   29.1   total   1162   max 36
  seconds      p50   4.0   p95   4.6   total  161.3
```

The loop runs the prompt over each test set and keeps the last line of each check: passes, then
failures. The failures on dev are the known failure modes, one message at a time. `stats.py`, from
lesson 2, gives the tokens and the seconds a call; lesson 16 turns tokens into money.

## The card

| | `prompts/triage.txt` |
|---|---|
| purpose | Sort each message to Folio's support inbox into a category, an urgency and a one-sentence summary, as JSON for the routing program |
| not for | Replying to customers, or messages in any language but English: no test set has them |
| owner | Ana Lima |
| version | id `c1916fcd`, commit `85dfa4e` |
| model and parameters | `llama3.2:3b` (`a80c4f17acd5`) on Ollama 0.40.0, temperature 0, seed 1, `num_predict` 400: the harness's defaults, none of them written in the file yet, which lesson 14 says to fix |
| scores | dev 24/40, holdout 15/30, attacks 3/10, pasted 2/6 |
| known failures | urgency, in both directions: eleven of the sixteen dev failures, ten of them one step off; two replies cut at an apostrophe (F-0001); `t25`, `t26` and `t33` in the wrong category |
| cost | 306.1 input and 29.1 output tokens a call; 4.0 s median and 4.6 s at p95 on four processor cores |
| decisions and failures | 0001 examples stay JSON; F-0001 apostrophes |

**The most important line is the attacks score.** Twenty-four of forty reads as a prompt with work
left; three of ten on messages written to steer it says that anything acting on its labels needs a
person, or the least privilege of lesson 10, behind it. A card that printed only the dev number
would be true and would mislead everybody who read it. The *not for* line does the same job in
words: it states the edges of what was tested, so nobody discovers them in production.
