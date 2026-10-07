---
title: What to know before using it
version: 1
---

Two rows of Anthropic's table, and two lines of the sheet, say most of what is particular to this
family.

```
ana@desk:~/desk$ python lab/card.py all Thinking "Default effort" "Context window" "Max output"
# https://platform.claude.com/docs/en/about-claude/models/overview, read 2026-10-05
Claude Fable 5.1
  Thinking                    Adaptive (always on)
  Default effort              high
  Context window              1M tokens
  Max output                  128K tokens
Claude Opus 5.5
  Thinking                    Adaptive (always on)
  Default effort              medium
  Context window              1M tokens
  Max output                  128K tokens
Claude Sonnet 5.5
  Thinking                    Adaptive
  Default effort              high
  Context window              1M tokens
  Max output                  128K tokens
Claude Haiku 4.5
  Thinking                    Extended
  Default effort              Not supported
  Context window              200K tokens
  Max output                  64K tokens
```

## Thinking and effort

**Thinking** is the reasoning of lesson 1 section 07: the model writes out working before it
answers. The table distinguishes three kinds. On Fable and Opus it is *adaptive* and *always on*:
the model decides how much to think, and always does some. On Sonnet the table says adaptive and
not always on. Haiku has the older *extended* thinking, which the request turns on and gives a
budget.

**Effort** is a second setting on the newer models: how hard the model works on a reply, from low
to max. The defaults differ, `high` on Fable and Sonnet and `medium` on
Opus, and Haiku does not support it. For choosing, the
consequence is that **a model's cost and latency depend on a setting**, and an evaluation has to
record the effort it ran at, as section 08 of lesson 5 recorded the temperature.

## Caching has a price structure

Lesson 4 priced ana's drafting with a cache. The sheet says what that cache costs on Haiku 4.5:

```
ana@desk:~/desk$ sheet show claude-haiku-4-5 | grep -E "^(input_cost_per_token|cache|prompt_cache|output_cost_per_token)"
cache_creation_input_token_cost            1.25e-06
cache_creation_input_token_cost_above_1hr  2e-06
cache_creation_input_token_cost_batches    6.25e-07
cache_read_input_token_cost                1e-07
cache_read_input_token_cost_batches        5e-08
input_cost_per_token                       1e-06
input_cost_per_token_batches               5e-07
output_cost_per_token                      5e-06
output_cost_per_token_batches              2.5e-06
prompt_cache_min_tokens                    4096
```

Read per million tokens: input is **$1**, writing the cache costs **$1.25** (a quarter more),
keeping it written for an hour instead of five minutes costs **$2** to write, and reading it back
costs **$0.10**, a tenth. So a cached prefix pays for its write after one reuse and costs a tenth of
the price on every reuse after that. The **minimum** is the trap: on Haiku 4.5 a prefix shorter than
4,096 tokens is not cached at all. On Sonnet 5.5:

```
ana@desk:~/desk$ sheet show claude-sonnet-5-5 | grep -E "^prompt_cache_min"
prompt_cache_min_tokens                    512
```

512. Ana's 5,000-token policy clears both. A team caching a 2,000-token system prompt would find
Sonnet caching it and Haiku silently charging full price, and the bill, not an error, would say so.

## The rest, briefly

- **Batch** halves every price above (the `_batches` lines), for work that can wait hours.
- **Vision and tool use** are supported by every model in the table, in the page's own words, and
  the sheet's `VFSCRP` adds structured output, caching, reasoning and PDF input for all four.
- Anthropic's API is reached in lesson 17, where the request shape, the version header, the
  retries and the cache's usage fields are shown.
