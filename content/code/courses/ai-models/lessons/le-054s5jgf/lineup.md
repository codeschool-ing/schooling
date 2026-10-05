---
title: The line-up
version: 1
---

OpenAI's pages could not be reached from the machine this course was recorded on, so, as with
Gemini, the family is read from the sheet. A selection of its current chat entries:

```
ana@desk:~/desk$ sheet compare gpt-5.4-nano gpt-5.4-mini gpt-5.4 gpt-5.5 gpt-6-luna gpt-6-sol gpt-6-astra
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
gpt-5.4-nano                                    272,000   128000      0.2     1.25  VFSCRP
gpt-5.4-mini                                    272,000   128000     0.75      4.5  VFSCRP
gpt-5.4                                       1,050,000   128000      2.5       15  VFSCRP
gpt-5.5                                       1,050,000   128000        5       30  VFSCRP
gpt-6-luna                                      922,000   128000      0.1      0.5  VFSCRP
gpt-6-sol                                       922,000   128000        2       10  VFSCRP
gpt-6-astra                                     922,000   128000       10       50  VFSCRP
```

Two naming schemes sit side by side.

**GPT-5, by version and size.** A version number (5.4, 5.5) and, below the full model, a **mini**
and a **nano**. Within version 5.4 the steps are steep: nano costs $0.20 a million input tokens,
mini $0.75, the full model $2.50, more than twelve times nano. The window steps too: 272,000 tokens
for mini and nano, about a million for the full models. 5.5 has no mini or nano in this selection,
which is common: the small sizes of a family often lag a version behind the large one, as Gemini's
Pro did in the other direction.

**GPT-6, by name.** `gpt-6-luna`, `gpt-6-sol` and `gpt-6-astra` are the sheet's entries for a newer
generation sized by name rather than suffix: luna the cheapest at $0.10 and $0.50, sol in the
middle, astra the dearest at $10 and $50. They have the same 922,000-token window at every size.
This course could not read OpenAI's own description of them, so it says only what the sheet
records: three sizes, their prices and their window.

## Reading it for ana

Lesson 4 priced her drafting on `gpt-5.4-mini` at $15.84 a month cached. Two things this table adds:

- **There are two cheaper rows**: `gpt-5.4-nano`, at about a quarter of mini's price, and
  `gpt-6-luna` at less than nano's. Both are candidates for the easy sorting task, and the only way
  to know whether they are good enough is lesson 5's forty cases.
- **The tiers are not comparable across generations by name.** A 6-luna is not "a better nano"
  until the cases say so, and a newer generation is a new set of candidates, not an upgrade.
