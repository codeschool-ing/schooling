---
title: A log answers questions, and each question has a lifetime
version: 1
---

The usual starting point is to log every call in full and keep it, because disk is cheap and
nobody can debug an answer that was thrown away. The first half of that is right. The second half
treats a log as a technical artefact, and **a log of prompts is a store of whatever your users
typed**, which includes things they should never have typed and you never asked for.

This lesson's lab is `~/guard`, built by `bash lab.sh reset` from the course directory. It holds the
call log of the assistant at Tarefa, an invented Brazilian marketplace where clients hire
freelancers. Every record in it, prompts and replies alike, was written by the course; no model
produced them. Here is one, from the last day in the log:

```
ana@lab:~/guard$ head -1 logs/raw/2026-09-29.jsonl
{"ts": "2026-09-29T10:22:39-03:00", "request": "rq-0021", "account": "ac-7Q2M", "surface": "chat", "model": "assistant-v3", "prompt": "My new e-mail is marcos.t@example.org and the CPF on file 714.602.380-01 is right", "output": "Thanks. The e-mail change needs confirming from the new address; your CPF is unchanged.", "in_tokens": 433, "out_tokens": 41, "ms": 970}
```

The client was asked for neither the e-mail address nor the CPF. They offered both, because a chat
box invites it, and the log kept both because it keeps everything.

## Start from the questions

A log earns its cost by answering questions. Four come up at nearly every team running a model in
production, and they need different parts of the record:

| question | what it needs | for how long |
|---|---|---|
| why did the assistant say *that* to this client? | the prompt and the output word for word, the model, the request id | until the complaint could arrive: days or weeks |
| is somebody abusing the assistant? | the account, the time, enough text to recognise the pattern | the length of an investigation |
| are answers getting worse? | many examples of prompts and outputs, but not who wrote them | months, so that two versions can be compared |
| what does this cost, and is it slowing down? | counts: calls, tokens, milliseconds | years, for trends and budgets |

**The text is what makes a record dangerous, and it is needed by the questions with the shortest
lives.** The cost question needs no text at all. The quality question needs text but not identity.
Only debugging and abuse need both, and both are about recent events.

That is the whole argument for **tiers**: the same call written into separate stores, each holding
what one kind of question needs and each with its own limit. The lab has three:

```
ana@lab:~/guard$ ls logs
metrics
raw
redacted
ana@lab:~/guard$ head -1 logs/metrics/2026-09-29.jsonl
{"day": "2026-09-29", "surface": "chat", "calls": 2, "in_tokens": 845, "out_tokens": 89, "ms_max": 1090}
ana@lab:~/guard$ cat retention.json
{
 "raw": {"days": 30, "what": "what the assistant was asked and said, word for word"},
 "redacted": {"days": 180, "what": "the same text with personal data and secrets replaced"},
 "metrics": {"days": 730, "what": "counts per day and surface: calls, tokens, slowest call"}
}
```

The metrics line answers the cost question for 29 September and contains nothing about anybody.
It can be kept for two years, shown on a dashboard and sent to a monitoring vendor with no further
thought. The raw line cannot be treated that way.

## What the record should carry that this one does not

Look at the raw record again with the debugging question in mind. It names the model, but not the
version of the instructions the assistant was running. **A reply cannot be explained without the
system prompt that produced it**, and the system prompt changes more often than the model does.
Logging its full text on every call repeats the same few thousand tokens millions of times; logging
a version identifier, with the prompts themselves kept in version control, costs a few bytes.

The same reasoning applies to anything that is identical across calls: the tool definitions, the
retrieval settings, the temperature. Log a reference to the configuration and keep the
configuration once.

## What no tier may keep

Some things are not a question of how long. A card's security code is the clearest case: the PCI
DSS, the standard the card networks impose on anybody who handles card data, forbids storing it
after the payment has been authorised, in any form, encrypted or not. A client who types it into a
support chat has handed it to the log, and no retention limit makes keeping it acceptable. The
same goes for credentials: an API key pasted into a chat must be revoked by its owner, and a log
that keeps it is keeping a working key.

The assistant at Tarefa answers a pasted key the right way, and the log shows why that answer is
needed. `guard redact`, the next section's subject, prints a record with what it recognises
replaced:

```
ana@lab:~/guard$ guard redact logs/raw/2026-06-02.jsonl
rq-0008  prompt  The integration keeps failing. Here's my key so you can test: [SECRET]
         output  Please revoke that key now: anything pasted here is stored in our logs. Then create a new one under Settings, then API.
```

The raw tier still holds the key itself, for thirty days. Redaction protects the copies that live
longer; it does not undo the paste, which is why the reply asks for the key to be revoked rather
than promising to forget it.

**Every tier is personal data while it can be tied to a person.** Under Brazil's LGPD, which lesson
22 applies to model calls, the redacted tier still names an account, and an account is a person. A
client who asks for their data to be deleted is asking about the logs too. The tiers make that
request cheaper to honour; they do not take the logs out of its reach.
