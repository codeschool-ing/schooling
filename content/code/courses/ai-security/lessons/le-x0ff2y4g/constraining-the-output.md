---
title: Two boundaries the model cannot cross
version: 1
---

The previous section asked the model to behave. This one changes **what the model is able to
produce, and what its output is able to reach**. Neither depends on the model deciding anything.

## Constrain what can come out

Lesson 9 checked a reply against a schema after the model had written it. A server that supports
structured output can do more: it **enforces the schema while the model writes**, choosing at each
step only among the tokens that keep the reply valid. Ollama does this for a JSON Schema sent as
`response_format`, and so do most paid providers. With `--schema`, the only replies the model can
produce are `{"category": "refund"}` and its three siblings:

```
ana@lab:~/guard$ guard classify data/tickets.jsonl --schema --show
t1   refund    ok
t2   delivery  ok
t3   account   ok
t4   refund    ok
t5   delivery  ok
t6   account   ok
t7   refund    ok
t8   delivery  WRONG  other
     reply: {"category": "other"}
t9   account   ok
t10  other     ok
t11  other     ok
t12  refund    ok
layout plain with schema: 11 right, 0 rejected to a person, 1 wrong and accepted
```

**Eleven right, and nothing to refuse.** No poem, no capital letters, no `URGENT`, no ticket copied
back, because none of those can be written in a space of four replies. The requests in the tickets
did not stop being requests; they lost the means to show up in the output.

`t8` is still wrong, and the schema cannot help with it. The ticket asked not to be classified and
the model picked `other`, a valid value. **A constrained output can be wrong inside the allowed set**,
and that is the residual risk to design for. Here it is bounded: a category moves a ticket to a queue
that people read, so the worst case is a ticket a person moves to the right queue, a few minutes
late. Measuring how often that happens, with many more than twelve tickets, is what lesson 23
automates.

The rule generalises beyond categories. **Every field the code acts on should be the narrowest type
that does the job**: a choice from a closed list, a number with a range, the id of something that
exists. Free text is the widest type there is, and it belongs only where a person reads it.

## Separate what reads from what acts

The second boundary is about where the output goes. The classifier reads text written by clients,
so the classifier holds **no tools**: the only thing it can do is name one of four queues. The code
that acts on the ticket, opening a refund or writing to the freelancer, reads that one word and never
the client's text.

That split has a name, the **dual LLM pattern**, described by Simon Willison in 2023. A quarantined
model reads untrusted material and returns closed values, and a privileged part of the application,
which may be another model with tools or plain code, acts on those values without seeing the
material. Applied to Tarefa:

| part | reads the client's text? | can call tools? | what it hands on |
|---|---|---|---|
| classifier | yes | no | one of four categories |
| support agent of lesson 10 | only what the code passes it | yes, behind the gate | proposals the gate decides on |
| the gate | no | decides, never proposes | ALLOW, HOLD or DENY |

The support agent of lesson 10 is the hard case, because it has to read the client's message to be
of any use, and it can propose calls. That is why the gate exists, and why its scope comes from the
session rather than from anything the model wrote. **The more an LLM reads, the less it should be
able to do**, and where it has to do both, a gate the model cannot talk to decides.

None of the three layers in this lesson is complete alone. A sentence about material is free and
sometimes helps. A schema removes a whole class of reply. The split keeps the text that cannot be
trusted away from the parts that can act. The same two boundaries answer the flow lesson 13 left
open, the files clients upload: whatever reads an attachment holds no tools and hands on only closed
values.
