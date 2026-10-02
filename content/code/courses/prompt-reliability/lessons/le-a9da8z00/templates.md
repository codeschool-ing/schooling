---
title: A prompt with holes in it
version: 1
---

Every prompt in this course has been a template without anybody calling it one. `{{message}}` at
the bottom of `v2-json.txt` is a hole, and `pl run` fills it forty times, once for each line of the
test set. **The prompt you write is never the prompt the model reads**: the model reads what the
template becomes once its holes are filled.

The reply prompt has three holes, because Folio wants the same instructions for more than one
shop and more than one language:

```
ana@lab:~/triage$ cat prompts/reply.txt
You write replies for {{shop}}, an online bookshop. Write in {{language}}.

Reply to the customer below in at most 80 words. Say what happens next and
when. Do not promise a refund or a date the shop has not agreed.

<message>
{{message|xml}}
</message>
```

`{{shop}}` and `{{language}}` are settings, the same for a whole run. `{{message|xml}}` comes from
the test case, and the `|xml` after its name is a filter, which the third section of this lesson
is about. `pl render` fills a template and prints the result without calling any model, which makes
it the cheapest way to see what the model will actually be sent. The reply prompt is only for
rendering in this lab, because the stand-in sorts messages and does not write replies.

```
ana@lab:~/triage$ pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio; echo "exit status $?"
pl: no value for {{language}}
exit status 2
ana@lab:~/triage$ pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio --var language=English
You write replies for Folio, an online bookshop. Write in English.

Reply to the customer below in at most 80 words. Say what happens next and
when. Do not promise a refund or a date the shop has not agreed.

<message>
I was charged twice for order 4471. Please refund the second payment.
</message>
```

The first command left out the language. `pl render` printed no prompt at all, named the hole it
could not fill, and exited with status 2, which a script can test. **A template with a hole nobody
filled is refused, not sent.** The second command filled all three, and the result is a prompt a
person could read and check line by line.

## Why a template rather than a copy

The alternative is a file per shop and per language, and it is how prompts usually start: copy the
English one, change a word, save it under a new name. Two copies of one set of instructions are
two places to fix the next problem, and the second fix is the one that gets forgotten. **With a
template, an instruction lives in one file**, and what differs between uses is a short list of
values you can see. When the support team decides the reply limit is 60 words rather than 80,
there is one line to change.
