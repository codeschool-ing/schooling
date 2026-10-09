---
title: The model holds no credential, ever
version: 1
---

One of the four findings is particular to LLM applications:

```
ana@lab:~/guard$ cat data/repo/prompts/support.txt
You are Tarefa's support assistant. Answer from the help centre.
When a refund is approved, call the payments API with the key
sk-lab-payments-00000000000000000000 and the job number.
```

The payments key is in the system prompt, because somebody wanted the model to call the payments API
and gave it what it would need. **Everything in a prompt is text the model can repeat.** Lesson 5
watched for a canary in replies because a system prompt can reach a reply; a key in the same place
reaches a reply the same way. It also reaches every copy of every prompt: the call log of lesson 11,
the provider's own logs under the terms lesson 12 read, and any trace a developer prints while
debugging.

The fix is not a better sentence in the prompt asking the model to keep the key to itself. Lessons 14
and 15 showed what a sentence like that is worth. **The fix is that the model never holds a
credential at all.** Lesson 10 already drew the shape: the model proposes a call, the gate decides,
and the tool runs with credentials of its own that the model never sees, in the prompt, in a tool
result or in an error message. The prompt says "you may propose `issue_refund`"; the key lives with
the code that runs `issue_refund`.

## Where each finding goes

| finding | where the credential belongs |
|---|---|
| `app/payments.py`, written in the code | a secret store, read by the refund tool at start-up, as `config.py` reads the provider key from the environment |
| `prompts/support.txt`, in the prompt | nowhere near the model: the tool holds it, the prompt only names the tool |
| `deploy/.env`, a password in a file beside the code | the deployment's secret store, never in the repository; a `.env` is for a developer's own machine and stays out of version control |
| `logs/2026-10-01.log`, a key in a logged header | not logged at all; the logger drops authorisation headers before writing, and lesson 11's redaction catches what slips through |

The last row is worth a second look. The request header that carries the provider key is exactly the
thing a debug log prints when somebody logs "the whole request". **Logging is a place credentials go
to be read by everybody who can read logs**, and that is a larger and less careful group than the
people who can read the secret store.

## What a leaked key costs

A finding that reached the repository is not fixed by deleting the line. The key is in the history,
in every clone and every copy of the build logs, so the only fix is to **rotate it**: issue a new key,
deploy it, and revoke the old one, so that the copies open nothing. That is why rotation has to be
cheap enough to do on a bad afternoon, and the next section is about keeping it that way.
