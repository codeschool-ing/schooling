---
title: A list of models is a promise about two models
version: 1
---

Routing chooses among providers of one model. The `models` field goes further and chooses among
**models**:

```
# OpenRouterTeam/docs@3e840a21 guides/routing/model-fallbacks.mdx
  21: The `models` parameter lets you automatically try other models if the primary model's
      providers are down, rate-limited, or refuse to reply due to content moderation.
```

With `standin-east` down again, ana asks for `standin/small` first and `standin/large` second.
`standin/small` has only that one provider:

```
ana@desk:~/desk$ python lab/or_sort.py '{"models": ["standin/small", "standin/large"]}'
other  model=standin/large provider=standin-west cost=$0.000168
```

```
ana@desk:~/desk$ wire --count 1
POST /openrouter/api/v1/chat/completions -> 200 openrouter standin-large routed={'model': 'standin/large', 'provider': 'standin-west', 'tried': ['standin/small at standin-east: 503', 'standin/large at standin-east: 503']}
```

The answer came back, the request succeeded, and **it was answered by the second model**. The
lab's log shows the two attempts that failed before it; ana's program sees only `model=standin/large`
in the response, and only because it prints it.

That is useful and it is a trap, for the reason lesson 5 is built on. A fallback list is a
statement that **every model on it is good enough** for the task. If only the first was evaluated,
the outage that sends traffic to the second is also the moment the desk starts sorting e-mail with
a model nobody measured, at a different price, and nothing fails. Two rules follow:

- **Evaluate every model you list**, with the same cases and the same harness, before it goes in
  the list.
- **Count which model answered**, from the response, so that a month in which a third of the mail
  went to the fallback shows up in a report rather than in complaints.
