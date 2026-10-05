---
title: Where Gemini is sold
version: 1
---

The same search as lesson 2 section 05, for Flash 3.5:

```
ana@desk:~/desk$ sheet where gemini-3.5-flash
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
aihubmix/gemini-3.5-flash-lite                       aihubmix                        0.3 2.499999
deepinfra/google/gemini-3.5-flash                    deepinfra                       1.5        9
gemini/gemini-3.5-flash                              gemini                          1.5        9
gemini/gemini-3.5-flash-lite                         gemini                          0.3      2.5
openrouter/google/gemini-3.5-flash                   openrouter                      1.5        9
openrouter/google/gemini-3.5-flash-lite              openrouter                      0.3      2.5
openrouter/google/gemini-3.5-flash-lite:batch        openrouter                     0.15     1.25
openrouter/google/gemini-3.5-flash:batch             openrouter                     0.75      4.5
perplexity/google/gemini-3.5-flash                   perplexity                      1.5        9
perplexity/google/gemini-3.5-flash-lite              perplexity                      0.3      2.5
vertex_ai/gemini-3.5-flash                           vertex_ai                       1.5        9
gemini-3.5-flash                                     vertex_ai-language-models       1.5        9
gemini-3.5-flash-lite                                vertex_ai-language-models       0.3      2.5
vertex_ai/gemini-3.5-flash-lite                      vertex_ai-language-models       0.3      2.5
```

Three groups, read from the `provider` column.

**Google, twice.** `gemini` is the Gemini API, reached with an API key from Google AI Studio.
`vertex_ai` and `vertex_ai-language-models` are Vertex AI, Google Cloud's platform, reached with a
cloud project's credentials. **The prices are identical** at this commit. The difference is the one
lesson 6 section 04 drew for Claude on the clouds: an account, a contract, regions and access rules
in Google Cloud, against a key and a simpler sign-up in AI Studio. Lesson 18 calls the Gemini API
and notes where Vertex differs.

**Resellers at the same price.** OpenRouter, DeepInfra and Perplexity list Flash 3.5 at Google's
own $1.50 and $9. A closed model resold has no room to undercut its maker, as lesson 2 found for
Claude.

**And one that halves it**: `openrouter/google/gemini-3.5-flash:batch` at $0.75 and $4.50. That is
not a cheaper copy. It is Google's batch tier, reached through a router, at the batch price of
section 03.

`aihubmix`'s Flash-Lite at `2.499999` is a reminder of what the sheet is: a third party typing other
people's prices. **A price that is almost but not quite the maker's is a typo or a rounding, not a
discount**, and the maker's page is where to check.
