---
title: A marker that says the system prompt left
version: 1
---

A system prompt holds instructions that clients are not meant to read: how the assistant should handle
refunds, which topics to send to a person, sometimes internal names. Lesson 5 is about how a prompt
gets out. This section is about noticing when it has, with a **canary**: a marker that means nothing,
is written into the system prompt and nowhere else, and therefore should never appear in a reply.

```
ana@lab:~/guard$ cat data/system-prompt.txt
You are Tarefa's support assistant. Answer questions about jobs, payments and
accounts from the help centre. Never ask for card numbers or passwords.
Internal marker: CANARY-7F3A-TAREFA. This marker is not for clients.
```

`CANARY-7F3A-TAREFA` is the marker. The filter chain looks for it in every reply, and `r3` above was
blocked by it with an alert, because a reply that contains the marker has repeated the system prompt
word for word. The alert matters more than the block: it tells somebody that the prompt is reaching
replies, which is worth an investigation even if every leaking reply is stopped.

Now the same replies with the canary layer switched off:

```
ana@lab:~/guard$ guard filter data/pipeline-outputs.jsonl --skip canary
layers: personal-data -> moderation -> links
r1  pass  
r2  BLOCK personal data: cpf
r3  pass  
r4  BLOCK moderation: harassment 0.82
r5  BLOCK link to a host not on the allowlist: https://pay-tarefa.example/confirm
r6  pass  
```

`r3` passes, which shows what the layer was adding. Look as well at `r6`, which passed in both runs. It
describes the instructions in its own words, and **the marker is not there**, so no canary can see it.
A canary detects a verbatim leak and nothing else.

Three practical notes:

- **One marker per prompt version**, so that an alert says which version leaked and since when.
- **Never put a secret in a system prompt** and rely on the canary to protect it. The canary reports a
  leak; it does not prevent one. Keys and credentials stay with the tools, as lesson 20 said.
- **Write the system prompt as if it will be read.** It probably will be, by somebody. A prompt that
  would embarrass the company if published is a prompt to rewrite, whatever filters stand behind it.
