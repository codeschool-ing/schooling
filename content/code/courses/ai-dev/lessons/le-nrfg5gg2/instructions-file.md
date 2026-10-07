---
title: An instruction file for the project
version: 1
---

Every request starts from nothing (lesson 1 section 10), so an assistant does not know your
project's rules unless something puts them in the context every time. **An instruction file is a
file in the repository that the assistant reads into every request**, and it is the cheapest way
to stop correcting the same mistake twice.

The tools disagree about its name. In 2026 the common ones are `AGENTS.md`, read by several
assistants from different vendors, `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md`
for GitHub Copilot, and a `rules` directory for Cursor. They are all Markdown, and they all work the
same way. `assist` reads `AGENTS.md`.

## A short one

ana's project already has `CONVENTIONS.md`, written for people. She does not copy it into the
instruction file; she points at it and repeats only the rules an assistant breaks most:

```
# Notes for coding assistants

Read CONVENTIONS.md before changing anything. The rules that matter most:

- Money is integer cents. Never introduce a float, not even in a test.
- Run `python -m pytest` after every change, and say if it fails.
- Never edit a test to make it pass. If a test looks wrong, say so instead.
- Standard library only. Ask before adding a dependency.
```

The same completion request as before now carries it, first:

```
ana@dev:~/shop$ assist complete shop/cart.py:34 --open shop/coupons.py tests/test_cart.py 2>&1 >/dev/null
context sent (765 of 3000 tokens):
     87  AGENTS.md
    411  shop/cart.py (cursor at line 34)
     91  shop/coupons.py
    176  tests/test_cart.py
---
```

**87 tokens, on every request**, which is the price of the file and the reason to keep it short.
Lesson 2 section 03 counted `CONVENTIONS.md` at 374 tokens as a system prompt; sending the whole of
it with every keystroke-triggered completion would be most of the request. A pointer and four
rules is the trade.

## What belongs in it

- **What a newcomer would get wrong on day one**: the money is in cents, the tests run with this
  command, the formatter is this one. Not what any competent developer would do anyway.
- **The commands**: how to run the tests, the linter, the build. Assistants that run commands
  (lesson 3 section 08) use them directly.
- **The boundaries**: "never edit a test to make it pass", "ask before adding a dependency". A
  rule that is a refusal is the kind a model follows best when it is stated plainly.
- **Not secrets, and not anything that changes daily.** It is committed, it is read by everyone's
  tools, and a stale instruction is worse than none.

## What it does not do

**An instruction file is a request, not a guarantee.** The model reads it as part of the prompt,
and a prompt is something the model continues from, not a rule it is bound by. It improves the odds
and does not enforce anything. What enforces "money is in cents" in this project is a test, and
what enforces "the tests pass" is CI. Write the rule in the file so the suggestions get it right
more often, and keep the check that catches the times they do not.
