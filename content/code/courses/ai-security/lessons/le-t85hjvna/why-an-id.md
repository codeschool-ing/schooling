---
title: One key, thousands of people
version: 2
---

Tarefa's assistant calls its model provider with one API key, the key of the company. From the
provider's side, every request comes from Tarefa: the client asking about a refund, the freelancer
drafting a proposal and the one person trying to make the assistant write something it should not.
**A key identifies the customer, and says nothing about the person behind each request.**

That costs something in two places.

**At the provider.** Providers watch for abuse of their usage policies, and what they can act on is
what they can see. If one of Tarefa's users spends an afternoon trying to extract instructions for
something forbidden, the provider sees a stream of bad requests from Tarefa's key. The possible
responses are a warning to Tarefa, a restriction on the key, or a suspension of the key, and each of
those lands on every user Tarefa has. With nothing else to go on, the provider cannot tell one bad
user from a bad customer.

**At Tarefa.** When the provider's warning arrives, or when Tarefa's own monitoring sees something
odd, the first question is *who*. Lesson 11's logs answer it if every call recorded the account. The
same identifier also lets Tarefa limit, bill and investigate per user, which the next two sections
are about.

## The field that carries it

Several providers accept an identifier for the end user in each request, kept separate from the
prompt. As the APIs stood in 2026, Anthropic's Messages API takes it as `metadata.user_id`, and
OpenAI's takes it as `safety_identifier`, a field that replaced the older `user`. Both are described in the
providers' documentation as a way to help detect abuse. Anthropic's asks for an opaque identifier
and no name, e-mail address or phone number; OpenAI's suggests hashing the username or the e-mail
address. The next section shows why a plain hash of an e-mail address protects less than it seems
to.

Field names change between API versions, so the habit to keep is independent of them: **every model
call carries the identity of the person it is for, in a field meant for it, and in a form that
identifies nobody to the provider.** Here is the shape of a request with one, written as the JSON
body an application would send; this lesson sends nothing anywhere:

```json
{
  "model": "a-model-name",
  "max_tokens": 400,
  "metadata": {"user_id": "eu-fe47aa8e7cd5e1b6f8bc"},
  "messages": [{"role": "user", "content": "How do I change the e-mail on my account?"}]
}
```

`eu-fe47aa8e7cd5e1b6f8bc` is the identifier `guard enduser`, in the next section, produces for the
account `ac-7Q2M`, the client whose e-mail address you met in lesson 11. The next section is how it
is made.

## What the provider does with it

An identifier lets the provider tell Tarefa *which* user tripped its abuse detection, so that Tarefa
can deal with one account instead of having the key restricted. What each provider actually does
with the field, how long it keeps it and whether it acts on it automatically is set out in its terms
and documentation, and differs between providers. Read them for the provider you use, the same way
lesson 12 read the contract. The field costs a few bytes per request, and the day it matters is the
day an abuse report names your key.
