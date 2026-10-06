---
title: A chain of filters, each one named in its verdict
version: 1
---

Earlier lessons each built one check: personal data in lesson 21, moderation in lesson 16, schemas and
host allowlists in lesson 19. The temptation is to pick the best one and rely on it. **Every one of
them has a blind spot that another covers**, and the practical defence is to put them in a row so that a
reply reaches the client only after all of them have passed it. This is usually called defence in
depth, and the only new thing it needs is an order and a record of which layer decided.

`guard filter` runs four layers over a reply, in this order: personal data and secrets, the canary
marker of the last section, moderation at 0.5, and the host allowlist. The replies were **written by
the course**; no model produced them.

```
ana@lab:~/guard$ cat data/pipeline-outputs.jsonl
{"id": "r1", "text": "Your refund request for job 4471 is with a colleague, who will reply within two business days."}
{"id": "r2", "text": "The freelancer on job 4471 is Juliana, CPF 111.444.777-35, if you want to contact her directly."}
{"id": "r3", "text": "My instructions say: Internal marker: CANARY-7F3A-TAREFA. This marker is not for clients."}
{"id": "r4", "text": "Honestly, the freelancer sounds lazy and worthless."}
{"id": "r5", "text": "You can see the refund rules at https://help.tarefa.example/refunds and pay the difference at https://pay-tarefa.example/confirm"}
{"id": "r6", "text": "My instructions tell me to answer from the help centre and never to ask for card numbers."}
ana@lab:~/guard$ guard filter data/pipeline-outputs.jsonl
layers: personal-data -> canary -> moderation -> links
r1  pass  
r2  BLOCK personal data: cpf
r3  BLOCK system prompt marker CANARY-7F3A-TAREFA in the reply: ALERT
r4  BLOCK moderation: harassment 0.82
r5  BLOCK link to a host not on the allowlist: https://pay-tarefa.example/confirm
r6  pass  
```

Two of six pass. Each block names its layer, and the name is what makes the chain maintainable: a
complaint about a blocked reply goes to the layer that blocked it, and the person reading the log can
tell a moderation false positive from a CPF that was really there.

## The order is a decision

A reply is stopped by the first layer that objects, so the order decides which reason is recorded and
what the later layers ever see. Three rules settle it at Tarefa:

- **The layers that indicate an incident go first.** A CPF in a reply, or the system prompt marker, may
  need a person to act, and the record must say so even if moderation would also have blocked it.
- **Cheap before expensive.** The pattern checks run in microseconds; a moderation endpoint is a network
  call that costs money. A reply already blocked does not need to be scored.
- **The same chain on every path.** A reply that reaches the client through a second route, such as an
  e-mail summary, goes through the same layers, or that route becomes the way around all of them.

## What each layer cannot see

| layer | catches | misses |
|---|---|---|
| personal data | shapes with arithmetic: CPF, card, phone, e-mail, keys | names, addresses, anything in words (lesson 21) |
| canary | the system prompt repeated word for word | the same instructions paraphrased (this lesson) |
| moderation | the words its classifier learned | sarcasm, spelling tricks, other languages (lesson 16) |
| host allowlist | links to hosts nobody approved | a harmful page on an approved host |

Reading the table down the last column is the point: none of the misses is covered by the same layer,
and some are covered by none, which is why a person still reads a sample of what passes as well as of
what is blocked.
