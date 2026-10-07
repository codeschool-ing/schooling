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
customers' names and addresses, `"deny"` is the setting to start from. The stand-in marks
`standin-east` as a provider that keeps data:

```
ana@desk:~/desk$ python lab/or_sort.py '{"provider": {"data_collection": "deny"}}'
other  model=standin/large provider=standin-west cost=$0.000168
```

```
ana@desk:~/desk$ python lab/or_sort.py '{"models": ["standin/small"], "provider": {"data_collection": "deny"}}'
503: No allowed providers are available for the selected model. standin/small at standin-east: stores data
```

The first request skipped `standin-east` and was served by `standin-west`. The second asked for a
model whose only provider keeps data, and **the request failed rather than send the e-mail there**,
which is the behaviour to want: a privacy setting that quietly falls back to the provider it was
meant to exclude would be no setting at all.

The same documentation lists stricter controls beside it: `zdr`, to use only endpoints with zero
data retention, `only` and `ignore`, to name providers, and `quantizations`, to refuse a host
serving the model at a lower precision than the one evaluated. Each is a line in the request, and
each turns a question from lessons 2 and 10 into something a program enforces instead of a
person remembering.
