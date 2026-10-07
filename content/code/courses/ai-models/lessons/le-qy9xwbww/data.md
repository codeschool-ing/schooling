---
title: Who keeps the e-mail
version: 1
---

Lesson 2 section 07 asked where the e-mail goes. Through OpenRouter it goes to OpenRouter and then
to whichever provider the routing picked, and providers differ in what they keep. The `provider`
object has a field for that, and its default deserves to be read slowly:

```
# OpenRouterTeam/docs@3e840a21 guides/routing/provider-selection.mdx
1192: - `allow`: (default) allow providers which store user data non-transiently and may train
      on it
1193: - `deny`: use only providers which do not collect user data
1195: Some model providers may log prompts, so we display them with a **Data Policy** tag on
      model pages. This is not a definitive source of third party data policies, but
      represents our best knowledge.
```

**By default, a provider that stores what it is sent and may train on it is allowed.** The tag
OpenRouter shows is, by its own description, not definitive. For Lantern Books, whose e-mails carry
customers' names and addresses, `"deny"` is the setting to start from, and it is one more field in
the request:

```
ana@desk:~/desk$ export OPENROUTER_BASE_URL=http://127.0.0.1:8500/v1 MODEL=llama3.2:3b
ana@desk:~/desk$ python or_sort.py '{"provider": {"data_collection": "deny"}}'
other model=llama3.2:3b provider=None
ana@desk:~/desk$ python relay.py show --body | grep -A2 '"provider"'
  "provider": {
    "data_collection": "deny"
  }
```

What the field changes happens on OpenRouter's side: a provider that keeps data is skipped, and if
every provider of the model keeps data, there is nobody left to send to. That is the behaviour to
want: a privacy setting that quietly fell back to the provider it was meant to exclude would be no
setting at all. And it is the setting a server that does not know it ignores most quietly of all,
as Ollama did with `provider` in section 03, so **a privacy field is checked against the service it
is sent to**, never assumed from the request.

The same documentation lists stricter controls beside it: `zdr`, to use only endpoints with zero
data retention, `only` and `ignore`, to name providers, and `quantizations`, to refuse a host
serving the model at a lower precision than the one evaluated. Each is a line in the request, and
each turns a question from lessons 2 and 10 into something a program enforces instead of a
person remembering.
