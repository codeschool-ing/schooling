---
title: Cohere's chat models
version: 1
---

Cohere and Mistral share this lesson because each is smaller than the three before it and each is
worth knowing for something particular: Cohere for **search**, Mistral for **open weights from a
European company**. Neither page could be reached from the machine this course was recorded on, so
both are read from the sheet.

Cohere's chat models, as the sheet records them:

```
ana@desk:~/desk$ python sheet.py provider cohere_chat
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
c4ai-aya-expanse-32b                            128,000     4000      0.5      1.5  ......
command-a-03-2025                               256,000     8000      2.5       10  .F....
command-a-plus-05-2026                          128,000    64000        0        0  VFS.R.
command-r-08-2024                               128,000     4096     0.15      0.6  .F....
command-r-plus-08-2024                          128,000     4096      2.5       10  .F....
command-r7b-12-2024                             128,000     4096   0.0375     0.15  .F....
```

The **Command** line, in dated names: `command-a-03-2025` is March 2025's Command A, the largest
priced here at $2.50 and $10, and `command-r7b-12-2024` the smallest, at under four cents a million
input tokens. The newest entry, `command-a-plus-05-2026`, is priced at **0 and 0**.

A price of zero in this sheet does not mean free. Look at the same model at every host:

```
ana@desk:~/desk$ python sheet.py where command-a-plus
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
aihubmix/command-a-plus-05-2026                      aihubmix                        2.5       10
azure_ai/Cohere-command-a-plus-05-2026               azure_ai                        0.8      3.2
command-a-plus-05-2026                               cohere_chat                       0        0
openrouter/cohere/command-a-plus                     openrouter                      0.3      1.5
```

Four entries, four prices: $2.50 and $10 at one reseller, $0.80 and $3.20 on Azure, $0.30 and $1.50
on OpenRouter, and zero at Cohere itself. **The sheet disagrees with itself.** Some of that is real,
hosts do set their own prices for open-weight models, and some of it is a third party's copy lagging
the source. Lesson 4's `sheet.py pick` leaves zero-priced entries out for exactly this reason: a
zero is "unknown" as often as it is "free".

**The rule for a number like this is to go to the maker.** Cohere's pricing page is named as the
source on its rerank entries (next section); for a model ana might ship, that page, read on the day,
outranks any copy.

## Where Command fits ana's list

A Command A at $2.50 input sits between Claude Sonnet and GPT-5.4 on price, with a 256,000-token
window and function calling but, per the sheet, no `S`: structured output is not recorded. That
rules it out of extraction until checked, as DeepSeek was in lesson 4, and leaves it a candidate for
sorting and drafting like any other row.
