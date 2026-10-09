---
title: The o series, and where reasoning went
version: 1
---

For a while OpenAI sold reasoning as a separate line: the **o series**, models tuned to work
through a problem before answering (lesson 1 section 07's third kind). The sheet still prices them:

```
ana@desk:~/desk$ python sheet.py compare o1 o3 o3-mini o4-mini
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
o1                                              200,000   100000       15       60  VFSCRP
o3                                              200,000   100000        2        8  VFSCRP
o3-mini                                         200,000   100000      1.1      4.4  .FSCR.
o4-mini                                         200,000   100000      1.1      4.4  VFSCRP
```

And it dates most of them:

```
ana@desk:~/desk$ python sheet.py retiring --provider openai | grep -E "  o[0-9]"
2026-10-23  o1                                                 openai
2026-10-23  o1-2024-12-17                                      openai
2026-10-23  o3-mini                                            openai
2026-10-23  o3-mini-2025-01-31                                 openai
2026-10-23  o4-mini                                            openai
2026-10-23  o4-mini-2025-04-16                                 openai
2026-12-11  o3-2025-04-16                                      openai
```

**o1, o3-mini and o4-mini are listed for retirement on October 23, 2026**, eighteen days after the
day this was recorded; the dated o3 snapshot follows in December. A line of models introduced as a
category of its own is ending as a set of entries in a deprecation list.

## Where it went

Into the GPT models themselves. Every GPT-5 and GPT-6 entry in section 02 carries an `R`, and the
reasoning is now a **setting on the request** rather than a choice of model. OpenAI's SDK, which is
generated from OpenAI's own API specification, lists the values that setting can take:

```
ana@desk:~/desk$ python -c "import typing, openai.types.shared.reasoning_effort as r; print(typing.get_args(r.ReasoningEffort)[0])"
typing.Literal['none', 'minimal', 'low', 'medium', 'high', 'xhigh', 'max']
```

Seven levels, from `none` to `max`. The sheet records which a model accepts and which it uses when
the request says nothing:

```
ana@desk:~/desk$ python sheet.py show gpt-5.4-mini | grep -E "reasoning"
default_reasoning_effort                   none
supports_minimal_reasoning_effort          False
supports_none_reasoning_effort             True
supports_reasoning                         True
supports_xhigh_reasoning_effort            True
```

```
ana@desk:~/desk$ python sheet.py show gpt-5.5 | grep -E "reasoning"
supports_minimal_reasoning_effort          False
supports_none_reasoning_effort             True
supports_reasoning                         True
supports_xhigh_reasoning_effort            True
```

`gpt-5.4-mini` defaults to **no reasoning at all**, and accepts `none`, not `minimal`, and up to
`xhigh`. The sheet records no default for `gpt-5.5`, which is itself information: it is one more
thing to check on the provider's page before relying on it.

## Why this matters for choosing

- **Reasoning is billed as output.** The model's working is tokens it writes, and they are charged
  at the output price whether or not you see them. Lesson 4 section 05 found output to be 5% to 25%
  of ana's drafting bill; a model reasoning at `high` before every draft would change that share,
  and the latency of lesson 4 section 06 with it.
- **The setting is part of the candidate.** `gpt-5.4-mini` at `none` and at `high` are two rows in
  lesson 5's evaluation, as lesson 6 said of Claude's effort. Record it in every run.
- **For ana's tasks, start at the bottom.** Sorting five labels and copying an order number need no
  working out; the default `none` is the place to begin, and a higher level earns its place only by
  fixing cases the cases show it fixes.
