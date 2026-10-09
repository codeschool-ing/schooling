---
title: Who decides when it changes
version: 1
---

The model ana chooses in lesson 5 will be measured against her forty cases on one day, under one
name. The question this section asks is **what happens to that measurement next year**, and the
answer is different for each kind.

## A closed model is retired on the provider's schedule

Providers publish dates after which a model identifier stops answering. The sheet carries them where
it knows them, as `deprecation_date`, and `python sheet.py retiring` lists every entry that has one:

```
ana@desk:~/desk$ python sheet.py retiring --provider anthropic
# LiteLLM model sheet at 21881c57, 4472 entries
3 entries carry a deprecation date
2026-06-09  claude-mythos-preview                              anthropic
2026-11-30  claude-sonnet-4-5                                  anthropic
2026-11-30  claude-sonnet-4-5-20250929                         anthropic
```

Two dates, and today, as this course is recorded, one of them is already past. **Claude Sonnet
4.5** answers until the end of November 2026; a product that still names it then gets an error
instead of a reply. DeepSeek's two API names had a date too:

```
ana@desk:~/desk$ python sheet.py retiring --provider deepseek
# LiteLLM model sheet at 21881c57, 4472 entries
4 entries carry a deprecation date
2026-07-24  deepseek-chat                                      deepseek
2026-07-24  deepseek-reasoner                                  deepseek
2026-07-24  deepseek/deepseek-chat                             deepseek
2026-07-24  deepseek/deepseek-reasoner                         deepseek
```

And OpenAI's list is long enough to need `head`:

```
ana@desk:~/desk$ python sheet.py retiring --provider openai | head -6
# LiteLLM model sheet at 21881c57, 4472 entries
44 entries carry a deprecation date
2026-07-23  computer-use-preview                               openai
2026-07-23  gpt-5-chat                                         openai
2026-07-23  gpt-5-chat-latest                                  openai
2026-07-23  gpt-5.1-chat-latest                                openai
```

Forty-four entries for one provider. Some are dated snapshots replaced by newer ones; some, such as
`gpt-5-chat-latest`, are **aliases**: names that point at whatever the provider currently serves
under them, which is a second way a model can change under you without a retirement at all.

The pattern is the same everywhere:

- **A dated identifier** (`claude-sonnet-4-5-20250929`) names one fixed model. It does not change,
  and one day it stops.
- **An alias** (`claude-sonnet-4-5`, `...-latest`) names a family member. It keeps answering, and
  what answers can change on a date you were not told about.

So pin a dated identifier in production when one exists, record which one in the project, and put
the retirement date in a calendar with the evaluation of lesson 5 attached to it. Lesson 8
section 04 returns to this with a provider retiring models in bulk.

## An open model changes when you change it

A file of weights on your disk is never retired. It answers the same way in ten years, which is
exactly what the evaluation you ran on it assumed. What can be withdrawn is **a host**: the
entries in section 05 come and go, and a host serving an older model may stop. The weights are
still yours; you take them elsewhere.

That is the strongest practical argument for open weights in this lesson. **Control is mostly
control of time**: deciding when the model changes, and re-running your cases before it does
rather than after.
