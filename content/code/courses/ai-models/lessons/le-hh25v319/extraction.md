---
title: A second task, a different winner
version: 1
---

Lesson 4 section 04 said one model can pass one task and fail another, and that is why each task is
evaluated on its own. The extraction task, on the same forty e-mails, with `prompts/extract.txt`:

```
ana@desk:~/desk$ python evalkit.py run extract runs/extract.jsonl 0 llama3.2:3b qwen2.5:3b llama3.2:1b
```

```
ana@desk:~/desk$ python evalkit.py report runs/extract.jsonl
model         strict   loose     loose, 95%  p50 s  out tok
llama3.2:3b    36/40   36/40     77% to  96%   1.49      9.4
qwen2.5:3b     25/40   25/40     47% to  76%   1.19      8.1
llama3.2:1b     8/40   12/40     18% to  45%   0.79     11.7
```

**The ranking turned over.** llama3.2:3b, second at sorting, finds the order number 36 times in
40, and every reply it wrote was valid JSON. qwen2.5:3b, the best
sorter, gets 25. llama3.2:1b writes valid JSON with the right number 8 times, and 12 if the program
fishes it out of the surrounding text. The failures say why:

```
ana@desk:~/desk$ python evalkit.py errors runs/extract.jsonl | grep -v "^llama3.2:1b"
llama3.2:3b  c07 wrong     expected LB-20399        got '{"order": "null"}'
llama3.2:3b  c09 wrong     expected None            got '{"order": "SMH-IL-12345"}'
llama3.2:3b  c24 wrong     expected None            got '{"order": "LB-12345"}'
llama3.2:3b  c32 wrong     expected LB-20478        got '{"order": "LB-20478-1204"}'
qwen2.5:3b   c01 wrong     expected LB-20417        got '{"order": null}'
qwen2.5:3b   c03 wrong     expected LB-20452        got '{"order": null}'
qwen2.5:3b   c07 wrong     expected LB-20399        got '{"order": null}'
qwen2.5:3b   c11 wrong     expected LB-20329        got '{"order": null}'
qwen2.5:3b   c13 wrong     expected LB-20470        got '{"order": null}'
qwen2.5:3b   c17 wrong     expected LB-20301        got '{"order": null}'
qwen2.5:3b   c18 wrong     expected LB-20493        got '{"order": null}'
qwen2.5:3b   c21 wrong     expected LB-20440        got '{"order": null}'
qwen2.5:3b   c22 wrong     expected LB-20481        got '{"order": null}'
qwen2.5:3b   c26 wrong     expected LB-20431        got '{"order": null}'
qwen2.5:3b   c27 wrong     expected LB-20497        got '{"order": null}'
qwen2.5:3b   c30 wrong     expected LB-20412        got '{"order": null}'
qwen2.5:3b   c31 wrong     expected LB-20366        got '{"order": null}'
qwen2.5:3b   c32 wrong     expected LB-20478        got '{"order": "LB-20478-1204"}'
qwen2.5:3b   c40 wrong     expected LB-20474        got '{"order": null}'
```

**qwen2.5:3b says there is no order when there is one**, fourteen times: `null` for an e-mail that
names `LB-20417` in brackets, `LB-20452` in the middle of a sentence, `LB-20474` in plain view. That
is a model being cautious in the wrong direction. Each of those replies is valid JSON and parses
cleanly, and a program that trusts it tells fourteen customers it cannot find their order.

**llama3.2:3b invents.** c24 and c09 name no order, and the right answer is `null`. For c24 it
answered `LB-12345`, which is the example in `prompts/extract.txt`: the shape the prompt gave it,
copied as the content. For c09, a question about the illustrated edition of *Small Hours*, it made
up `SMH-IL-12345`. **Cases whose right answer is "there is none" are where invention shows**, and
section 03 kept fifteen of them for this reason. `SMH-IL-12345` is no order number the shop could
have, and a lookup fails on it. `LB-12345` is in the shop's own format, so a program that looks it
up sees an order number, and the day the shop reaches order 12345 it finds somebody else's.

**Both turned `LB-20478` into `LB-20478-1204`** for c32, which asks to add apartment 1204 to that
order: the model joined two numbers from the same sentence. And llama3.2:3b's `"null"` for c07, in
quotes, is a string where JSON has a value for nothing, for an e-mail that does name its order.

The 1b's replies are a different kind of wrong:

```
ana@desk:~/desk$ python evalkit.py errors runs/extract.jsonl | grep "^llama3.2:1b" | head -6
llama3.2:1b  c01 wrong     expected LB-20417        got '{"status": "preparing"}'
llama3.2:1b  c02 wrong     expected LB-20388        got '{"order": "null"}'
llama3.2:1b  c03 loose ok  expected LB-20452        got 'null\n{"order": "LB-20452"}'
llama3.2:1b  c05 loose ok  expected None            got 'Here\'s a JSON answer:\n\n{"visit": "Yes, you can visit the Museu de Arte Moderna (MAM) in Curitiba."}'
llama3.2:1b  c06 wrong     expected LB-20501        got '{"order": null}'
llama3.2:1b  c07 wrong     expected LB-20399        got '{"status": "REFUNDING"}'
```

Keys the prompt never asked for, `status` and `visit`, and a `null` before the JSON. It does not
hold the format, which is the first thing extraction needs.

## Per task, then

| | sorting, loose | extraction, strict | wrong order numbers written |
|---|---|---|---|
| llama3.2:3b | 19 | 36 | 3: two invented, one altered |
| qwen2.5:3b | 30 | 25 | 1 altered, and 14 orders missed |
| llama3.2:1b | 5 | 8 | holds neither format |

The question for each row is no longer "which is best" but **"which mistakes can the shop live
with, for which task"**. A missed order sends a reply that asks the customer for the number again.
An invented one looks the order up and finds nothing, or finds somebody else's. Section 10 decides.
