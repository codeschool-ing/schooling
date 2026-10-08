---
title: Choosing for the task
version: 2
---

Triage has one right answer per message. The same message should get the same category every time,
because a person or a program acts on it. **For a task with one right answer, sampling can only
move answers around, and it moves the close calls.** Here is `v6-escaped.txt`, the prompt from
lesson 4, run five times over the forty messages, first at temperature 0:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/dev.jsonl --samples 5 --out runs/t0.jsonl
200 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/t0.jsonl
ana@lab:~/triage$ pl check runs/t0.jsonl
check      pass  fail
json        195     5
fields      195     5
labels      195     5
category    150    50
urgency     100   100
all         100   100
```

`--samples 5` calls the model five times per message, each with a different seed: 200 calls. At
temperature 0 the seed has nothing to choose, so the five calls are identical and every count is five
times a single run's: 30 categories right becomes 150. Now the same thing at temperature 1:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/dev.jsonl --samples 5 --set temperature=1 --out runs/t1.jsonl
200 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/t1.jsonl
ana@lab:~/triage$ pl check runs/t1.jsonl
check      pass  fail
json        198     2
fields      198     2
labels      198     2
category    152    48
urgency      85   115
all          85   115
ana@lab:~/triage$ pl check runs/t1.jsonl --failures | grep -e '^t22' -e '^t01'
t01    category  returns, expected billing
t01#1  category  returns, expected billing
t01#2  category  returns, expected billing
t01#3  category  returns, expected billing
t01#4  category  returns, expected billing
t22    category  other, expected billing
t22#1  category  other, expected billing
t22#2  category  other, expected billing
t22#3  category  other, expected billing
t22#4  category  other, expected billing
```

The categories did not suffer: 152 right against 150, and three more replies parsed. **The urgency
fell from 100 to 85.** For this model, at this prompt, the category is mostly a confident choice and
the urgency is the close call, and sampling found the close calls. `t01` and `t22`, wrong at
temperature 0, are wrong in all five samples at temperature 1 as well. The first section of this
lesson measured `t22` at 62.1% `other` and 22.5% `billing`, so five draws with no billing in them is
not a surprise, and **sampling does not rescue an answer the model is fairly sure of**. It only
spends the margins.

A lower temperature is not the same as zero:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/dev.jsonl --samples 5 --set temperature=0.2 --out runs/t02.jsonl
200 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/t02.jsonl
ana@lab:~/triage$ pl check runs/t02.jsonl
check      pass  fail
json        195     5
fields      195     5
labels      195     5
category    149    51
urgency      96   104
all          96   104
```

At 0.2 the category lost 1 of 150 and the urgency 4 of 100. A message whose top two candidates are
nearly tied keeps flipping at almost any temperature above zero, because a small temperature
stretches a small gap into a gap that is still small.

## When variety is the point

The other kind of task wants a different answer each time: five subject lines to choose from, a
reply to a customer that should not read like the last fifty, a list of ideas. Lesson 4's
`reply.txt` writes replies. Here it is three times over each message of `cases/three.jsonl`, also
from lesson 4, at temperature 0, with one line of Python that counts how many different texts came
back:

```
ana@lab:~/triage$ pl run prompts/reply.txt cases/three.jsonl --samples 3 --out runs/same.jsonl --var shop=Folio --var language=English
9 calls, prompt 13304d8d, llama3.2:3b, written to runs/same.jsonl
ana@lab:~/triage$ python3 -c 'import json, sys; rows = [json.loads(l) for l in open(sys.argv[1])]; print(len(rows), "replies,", len({r["text"] for r in rows}), "different")' runs/same.jsonl
9 replies, 6 different
```

Nine replies and six different texts, at temperature 0. Hold on to that; the last section of this
lesson comes back to it. A prompt that wants variety can carry its own temperature, in the header
`pl` reads above a line of `---`. Save this as `prompts/reply-varied.txt`:

```
temperature: 0.8
---
You write replies for {{shop}}, an online bookshop. Write in {{language}}.

Reply to the customer below in at most 80 words. Say what happens next and
when. Do not promise a refund or a date the shop has not agreed.

<message>
{{message|xml}}
</message>
```

It is `reply.txt` with two lines on top. The same nine calls:

```
ana@lab:~/triage$ pl run prompts/reply-varied.txt cases/three.jsonl --samples 3 --out runs/varied.jsonl --var shop=Folio --var language=English
9 calls, prompt c92bce25, llama3.2:3b, written to runs/varied.jsonl
ana@lab:~/triage$ python3 -c 'import json, sys; rows = [json.loads(l) for l in open(sys.argv[1])]; print(len(rows), "replies,", len({r["text"] for r in rows}), "different")' runs/varied.jsonl
9 replies, 9 different
ana@lab:~/triage$ pl show runs/varied.jsonl t01
│ Dear customer,
│
│ Thank you for reaching out to us about the issue with your order 4471. We are investigating this matter immediately. Our team will review the transaction and take necessary actions to rectify the situation. You can expect a further update on this issue by the end of the business day tomorrow. Please contact us again if you have any additional concerns.
│
│ Best regards,
│ Folio Customer Service
stop: stop, tokens in 96, out 80, 9.3 s
ana@lab:~/triage$ pl show runs/varied.jsonl t01 --sample 1
│ "Thank you for reaching out to us about the double charge for your order 4471. Our team is investigating this issue and will contact you as soon as possible to resolve the problem. You will receive an email with the next steps to rectify the situation. We apologize for the inconvenience caused and appreciate your patience."
stop: stop, tokens in 96, out 65, 7.3 s
```

Nine of nine are different, and they differ from the first line: one is a letter with a greeting
and a signature, the other a single paragraph in quotation marks. Whether either is a good reply is
another question, and lesson 12 measures tone. What the header did is make every call worth paying
for.

**Decide per task, and keep classification and extraction at 0.** Putting the temperature in the
prompt file keeps the decision next to the text it was made for, so the triage prompt and the reply
prompt can live in one directory without anybody remembering which needs which.

Lesson 19 samples on purpose, several times per message, and votes. That puts the randomness to work,
and it costs a call per sample.

## Zero is not a guarantee

Temperature 0 made the five triage samples above identical. It did not do that for the replies:
nine replies, six different texts. Here are the three for `t01`:

```
ana@lab:~/triage$ pl show runs/same.jsonl t01
│ "Dear customer,
│
│ We apologize for the inconvenience and are investigating the issue with your order 4471. We will process a refund for the second payment as soon as possible. You can expect to receive an update on the status of your refund within the next 3-5 working days. If you have any further concerns, please don't hesitate to contact us.
│
│ Best regards, Folio Customer Service"
stop: stop, tokens in 96, out 82, 10.9 s
ana@lab:~/triage$ pl show runs/same.jsonl t01 --sample 1
│ "Dear customer,
│
│ We apologize for the inconvenience and are investigating the issue with your order 4471. We will process a refund for the second payment as soon as possible. You will receive an email with the refund details once the process is complete. We appreciate your patience and understanding in this matter.
│
│ Best regards, Folio Customer Service"
stop: stop, tokens in 96, out 69, 7.9 s
ana@lab:~/triage$ pl show runs/same.jsonl t01 --sample 2
│ "Dear customer,
│
│ We apologize for the inconvenience and are investigating the issue with your order 4471. We will process a refund for the second payment as soon as possible. You will receive an email with the refund details once the process is complete. We appreciate your patience and understanding in this matter.
│
│ Best regards, Folio Customer Service"
stop: stop, tokens in 96, out 69, 8.3 s
```

Samples 1 and 2 agree. Sample 0 agrees with them for thirty words and then writes *You can expect*
where they write *You will receive*, and from there it is a different reply. The seed cannot be the
reason, because samples 1 and 2 had different seeds and agree. The same happened for `t02` and
`t03`: in each, sample 0 differs and samples 1 and 2 agree. The likeliest cause is Ollama's cache.
The first call for each message computed the whole message; the next two found most of it already
computed and reused it. The arithmetic took a different path, the last digits of two nearly equal
scores came out the other way round, and greedy decoding followed the new winner to the end of the
reply. A short JSON object gives a near tie fewer places to happen than sixty words of prose, which
is why the triage samples agreed. All three replies also promise a refund, which the prompt forbids;
lesson 4 found the same, and temperature has nothing to do with it.

Different machines add a second cause. Lesson 1 ran `v2-json.txt` and printed 22 passes; lessons 2
and 3 ran the same file over the same forty messages, with the same model and the same settings,
and printed 21. Here it is once more, on the machine that captured this section:

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, llama3.2:3b, written to runs/v2.jsonl
ana@lab:~/triage$ pl check runs/v2.jsonl --failures
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     31     9
urgency      22    18
all          22    18

t02    urgency   high, expected normal
t06    category  account, expected billing
t07    urgency   high, expected normal
t09    urgency   high, expected normal
t16    urgency   high, expected normal
t18    urgency   high, expected normal
t19    category  delivery, expected account
t22    category  other, expected billing
t24    urgency   low, expected normal
t25    category  other, expected account
t26    category  account, expected billing
t31    category  returns, expected billing
t32    urgency   high, expected normal
t33    urgency   low, expected normal
t36    category  account, expected billing
t37    urgency   high, expected normal
t38    json      not a JSON object
t39    category  delivery, expected account
```

Twenty-two, and the eighteen failures are the ones lesson 1 listed, message for message. So two
machines agree, and on the machine that captured lessons 2 and 3 one more reply failed. The
prompt, the model, the seed and the temperature were the same on all of them.

**Temperature 0 means the top candidate every time, and the top candidate is computed.** The scores
come out of millions of floating-point additions, and a cache, a different processor, a different
build of Ollama or a different number of threads adds them in a different order. When two candidates
are nearly tied, a difference in the last digits is enough to swap them. Hosted models add one more
cause: your request is batched with other people's, and the batch changes the arithmetic.
Anthropic's documentation for `temperature` says that even at 0.0 the results will not be fully
deterministic.

That is one more reason to measure over a test set and compare message by message, instead of
trusting one run of one message, and to **run the baseline again on the machine where you test the
change**. A comparison between a run from last month and a run from today measures the machine as
well as the prompt.
