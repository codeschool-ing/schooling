---
title: The line-up
version: 1
---

Google's own pages could not be reached from the machine this course was recorded on, so this
lesson reads the family entirely from the sheet. Every Gemini entry there names Google's pricing
page as its source:

```
ana@desk:~/desk$ sheet show gemini/gemini-3.5-flash | grep -E "^(source|rpm|tpm)"
rpm                                        2000
source                                     https://ai.google.dev/gemini-api/docs/pricing
tpm                                        800000
```

That `source` line is the sheet saying where it copied the numbers from. The `rpm` and `tpm` beside
it are requests and tokens per minute, the rate limits of whichever account tier the sheet's keepers
recorded; lesson 21 is about limits like these, and a new account's are usually lower.

The current line, as the sheet has it:

```
ana@desk:~/desk$ sheet compare gemini/gemini-3.5-flash-lite gemini/gemini-3.5-flash gemini/gemini-3.1-pro-preview gemini/gemini-flash-latest gemini/gemini-pro-latest
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
gemini/gemini-3.5-flash-lite                  1,048,576    65536      0.3      2.5  VFSCRP
gemini/gemini-3.5-flash                       1,048,576    65536      1.5        9  VFSCRP
gemini/gemini-3.1-pro-preview                 1,048,576    65536        2       12  VFSCRP
gemini/gemini-flash-latest                    1,048,576    65536     0.75     3.75  VFSCRP
gemini/gemini-pro-latest                      1,048,576    65536        2       12  VFSCRP
```

**Three tiers again**, named for speed: Flash-Lite, the cheapest, Flash, and Pro. Every
one of them has a window of 1,048,576 tokens, a million in binary, and writes up to 65,536. The
window is the same at every price, which is the first thing that sets this family apart from the
previous lesson's, where the cheapest model had a fifth of the window.

## Version numbers that do not line up

Two features of the names will catch anybody choosing from a list:

- **The tiers do not share a version.** At this commit Flash and Flash-Lite are at 3.5 while Pro is
  at 3.1, and still a `preview`. "The newest Gemini" is three different numbers.
- **The `-latest` names are aliases**, lesson 2 section 06's moving kind, and they do not point
  where the numbers suggest. `gemini-flash-latest` is priced at $0.75 and $3.75, the price of a
  different Flash entry from `gemini-3.5-flash` at $1.50 and $9. An alias called "latest" is
  whatever Google currently serves under that name, and the price tells you it is not the 3.5 entry
  above it.

For ana that means one rule from lesson 2 applied strictly: **evaluate and pin the numbered
identifier**, `gemini/gemini-3.5-flash-lite`, never `flash-lite-latest`. Her drafting priced at
$8.02 a month cached on Flash-Lite in lesson 4, under half of Haiku's $18.72, and its score on her
cases is the only thing that can say whether that is a bargain.
