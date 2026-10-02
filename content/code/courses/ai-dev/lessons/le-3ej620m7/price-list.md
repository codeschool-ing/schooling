---
title: Reading a price list
version: 1
---

Model APIs are priced **per million tokens**, written `MTok`, with a different price for each
direction. Input is what you send, output is what the model writes, and **output costs several
times more than input**, because generating a token is a pass through the whole model and reading
a prompt is done in bulk. Most lists add a third and a fourth column for cached input, which
lesson 2 section 07 explains.

This is the sheet the course uses, printed by `prices.py` beside the course's files. It reads two
sources, and the difference between them matters:

- **Anthropic's own pricing page**, read on the day the script ran. A page is not versioned, so
  the date is part of every number.
- **LiteLLM's price list at a pinned commit**, for OpenAI and Google. LiteLLM is an open-source
  project that keeps prices and limits for every provider in one file. It is a third party's copy:
  OpenAI's and Google's own pages could not be reached from the machine this course was recorded
  on. The script prints Anthropic's models from both sources, so you can see the copy agree with
  the original where both exist.

It ran on the recording machine, not in the lab, since it reads the network:

```
$ python3 prices.py
anthropic: https://platform.claude.com/docs/en/about-claude/pricing, read 2026-10-02
  model                  input  output  cache write 5m  cache read
  Claude Opus 5.5           $4     $20              $5       $0.20
  Claude Sonnet 5.5         $2     $10           $2.50       $0.20
  Claude Haiku 4.5          $1      $5           $1.25       $0.10
anthropic: LiteLLM at commit b9e71e990aed
  model                            input  output  cache read    window  max out
  claude-opus-5-5                     $4     $20        $0.2   1000000   128000
  claude-sonnet-5-5                   $2     $10        $0.2   1000000   128000
  claude-haiku-4-5                    $1      $5        $0.1    200000    64000
openai: LiteLLM at commit b9e71e990aed
  model                            input  output  cache read    window  max out
  gpt-5.5                             $5     $30        $0.5   1050000   128000
  gpt-5.4                           $2.5     $15       $0.25   1050000   128000
  gpt-5.4-mini                     $0.75    $4.5      $0.075    272000   128000
  gpt-5.4-nano                      $0.2   $1.25       $0.02    272000   128000
google: LiteLLM at commit b9e71e990aed
  model                            input  output  cache read    window  max out
  gemini/gemini-pro-latest            $2     $12        $0.2   1048576    65536
  gemini/gemini-3.5-flash           $1.5      $9       $0.15   1048576    65536
  gemini/gemini-3.5-flash-lite      $0.3    $2.5       $0.03   1048576    65536
```

**These numbers are from 2 October 2026 and they will be wrong by the time you read this.** Prices
in this market have fallen and been restructured several times a year. What does not age is how
to read the sheet:

- **The unit is dollars per million tokens.** Claude Sonnet 5.5 at `$2` input and `$10` output
  means a request with 2,000 tokens in and 500 out costs 2,000 × 2 / 1,000,000 plus 500 × 10 /
  1,000,000: $0.004 plus $0.005, nine tenths of a cent.
- **Output is five or six times input here**: 5× on all three Claude models, 6× on most of
  OpenAI's, 6× on Gemini's Pro. A feature that writes long answers costs a different order of
  money from one that reads long documents and answers yes or no.
- **The spread inside one provider is larger than between providers.** `gpt-5.4-nano` is 25 times
  cheaper per input token than `gpt-5.5`; Haiku 4.5 is a quarter of the price of Opus 5.5. Lesson
  10 is about choosing, and the short version is that the cheapest model that passes your own
  tests is the right one.
- **`window` and `max out`** are the limits of lesson 2 section 02, in the same row as the price,
  because they decide what fits in one request.

## When prices change

Treat the price table in your code the way `prices.py` treats it: **one place, with a date and a
source next to it**. Lesson 2 section 05 writes the cost function that reads it, and a test that
fails when somebody adds a model without a price is cheap insurance against a dashboard that
quietly reports a new model as free.
