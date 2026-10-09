---
title: A prompt with holes in it
version: 2
---

Every prompt in this course has been a template without anybody calling it one. `{{message}}` at
the bottom of `v2-json.txt` is a hole, and `pl run` fills it forty times, once for each line of the
test set. **The prompt you write is never the prompt the model reads**: the model reads what the
template becomes once its holes are filled.

This prompt writes the reply a customer receives, and it has three holes, because Folio wants the
same instructions for more than one shop and more than one language. Save it as
`prompts/reply.txt`:

```
You write replies for {{shop}}, an online bookshop. Write in {{language}}.

Reply to the customer below in at most 80 words. Say what happens next and
when. Do not promise a refund or a date the shop has not agreed.

<message>
{{message|xml}}
</message>
```

`{{shop}}` and `{{language}}` are settings, the same for a whole run, passed with `--var`.
`{{message|xml}}` comes from the test case, and the `|xml` after its name is a filter, which the
fourth section of this lesson, *A value is data*, is about. `pl render` fills a template and prints
the result without calling any model, which makes it the cheapest way to see what the model will
actually be sent:

```
ana@lab:~/triage$ pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio; echo "exit status $?"
pl: no value for {{language}}
exit status 1
ana@lab:~/triage$ pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio --var language=English
You write replies for Folio, an online bookshop. Write in English.

Reply to the customer below in at most 80 words. Say what happens next and
when. Do not promise a refund or a date the shop has not agreed.

<message>
I was charged twice for order 4471. Please refund the second payment.
</message>
```

The first command left out the language. `pl render` printed no prompt at all, named the hole it
could not fill, and exited with status 1, which a script can test. **A template with a hole nobody
filled is refused, not sent.** The second command filled all three, and the result is a prompt a
person could read and check line by line.

## One template, two languages

The reply prompt is not a sorting prompt, so `pl check` has nothing to say about it, but `pl run`
and `pl show` work on any prompt. Three messages, in English and in Portuguese, with nothing changed
but one value:

```
ana@lab:~/triage$ head -n 3 cases/dev.jsonl > cases/three.jsonl
ana@lab:~/triage$ pl run prompts/reply.txt cases/three.jsonl --out runs/reply-en.jsonl --var shop=Folio --var language=English
3 calls, prompt 13304d8d, llama3.2:3b, written to runs/reply-en.jsonl
ana@lab:~/triage$ pl run prompts/reply.txt cases/three.jsonl --out runs/reply-pt.jsonl --var shop=Folio --var language=Portuguese
3 calls, prompt 13304d8d, llama3.2:3b, written to runs/reply-pt.jsonl
ana@lab:~/triage$ pl show runs/reply-en.jsonl t01
│ "Dear customer,
│
│ We apologize for the inconvenience and are investigating the issue with your order. We will process a refund for the second payment as soon as possible. You can expect to receive an email with the refund details once the process is complete. If you have any further concerns, please don't hesitate to contact us.
│
│ Best regards, Folio Customer Service"
stop: stop, tokens in 96, out 73, 9.0 s
ana@lab:~/triage$ pl show runs/reply-pt.jsonl t01
│ Olá!
│
│ Lamento saber que você foi cobrado duas vezes pelo seu pedido 4471. Estamos trabalhando para resolver o problema e devolver o valor excessivo. Você receberá uma atualização sobre o status do seu pedido assim que estivermos em contato com a nossa equipe de pagamento. Se tiver alguma dúvida, por favor não hesite em entrar em contato conosco.
│
│ Atenciosamente,
│ Equipe do Folio
stop: stop, tokens in 96, out 96, 10.7 s
```

The same file, the same message, and a reply in each language. Read them as well as count them:
both promise a refund, *"We will process a refund for the second payment"* and *"devolver o valor
excessivo"*, and the prompt says *Do not promise a refund or a date the shop has not agreed*. **A
template keeps the instructions in one place; it does not make the model follow them.** Lesson 12 is
about checking what a reply says, and a reply that promises money is the first thing to check for.

## Why a template rather than a copy

The alternative is a file per shop and per language, and it is how prompts usually start: copy the
English one, change a word, save it under a new name. Two copies of one set of instructions are
two places to fix the next problem, and the second fix is the one that gets forgotten. **With a
template, an instruction lives in one file**, and what differs between uses is a short list of
values you can see. When the support team decides the reply limit is 60 words rather than 80, or
writes the refund rule more firmly, there is one line to change.
