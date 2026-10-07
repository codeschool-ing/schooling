---
title: Context is a threshold, then a cost
version: 1
---

A model's **context window** is the most tokens a request may hold: the prompt and, at most
providers, the reply as well. It is the one criterion where the sheet's numbers can be used
directly, and they have grown so much that the question has changed from "does it fit" to "what
does it cost to fill".

How many priced chat entries reach each size:

```
ana@desk:~/desk$ sheet pick --min-window 1000000 | sed -n 2p
761 entries pass
```

```
ana@desk:~/desk$ sheet pick --min-window 200000 | sed -n 2p
1666 entries pass
```

```
ana@desk:~/desk$ sheet pick --min-window 32000 | sed -n 2p
2722 entries pass
```

Of 2,990 priced chat entries, 2,722 take 32,000 tokens, 1,666 take 200,000, and 761 take a
million or more. Ana's longest request, the policy plus a long e-mail thread, is under 10,000
tokens. **Every model she could reasonably shortlist fits it many times over**, which makes the
window a threshold she passes by a mile and nothing more.

## What a large window does not buy

A window is a limit, not a promise of good use. Three things to know before filling one:

- **You pay for every token you send**, each time you send it. A 200,000-token prompt at $1 a
  million costs 20 cents before the model writes a word, on every request. Caching (section 05)
  softens it for a repeated prefix; nothing softens it for a different document each time.
- **Long prompts are slower to start.** The whole prompt is read before the first token, and the
  first-token time of section 06 grows with it.
- **Models use the middle of a long context less reliably than its ends**, a pattern seen across
  many models and the reason retrieval (lesson 1 section 11) still exists in an age of
  million-token windows: sending the relevant page beats sending the whole book.

## The other ceiling

The window has a sibling that is easier to miss: **the most a model will write in one reply**. For
five of section 05's candidates, side by side:

```
ana@desk:~/desk$ sheet compare claude-haiku-4-5 gemini/gemini-3.5-flash-lite gpt-5.4-mini mistral/mistral-small-latest deepseek/deepseek-v3.2
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
claude-haiku-4-5                                200,000    64000        1        5  VFSCRP
gemini/gemini-3.5-flash-lite                  1,048,576    65536      0.3      2.5  VFSCRP
gpt-5.4-mini                                    272,000   128000     0.75      4.5  VFSCRP
mistral/mistral-small-latest                    262,144   262144     0.15      0.6  VFS.R.
deepseek/deepseek-v3.2                          163,840   163840     0.28      0.4  .F.CR.
```

The `max out` column runs from 64,000 to 262,144 tokens, more than any of her replies will ever
need. It matters for tasks that write long documents in one go, and it is worth knowing that some
providers count the reply inside the window and some do not.

The last column is the features the sheet records for each, and it already has something to say.
**DeepSeek V3.2 has no `S`**: the sheet does not record support for structured output. For ana's
extraction task that is a threshold, and section 08 deals with it.
