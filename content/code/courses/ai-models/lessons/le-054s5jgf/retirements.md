---
title: A provider retiring in bulk
version: 1
---

The o series is not retiring alone. The same date in the sheet takes most of the GPT-4 line with it:

```
ana@desk:~/desk$ python sheet.py retiring --provider openai | grep -E "  gpt-4"
2026-10-23  gpt-4                                              openai
2026-10-23  gpt-4-0613                                         openai
2026-10-23  gpt-4-1106-preview                                 openai
2026-10-23  gpt-4-turbo                                        openai
2026-10-23  gpt-4-turbo-2024-04-09                             openai
2026-10-23  gpt-4.1-nano                                       openai
2026-10-23  gpt-4.1-nano-2025-04-14                            openai
2026-10-23  gpt-4o-2024-05-13                                  openai
2027-01-20  gpt-4o-audio-preview-2024-12-17                    openai
2027-01-20  gpt-4o-audio-preview-2025-06-03                    openai
2027-01-20  gpt-4o-mini-audio-preview-2024-12-17               openai
```

Eight entries on **October 23, 2026**: GPT-4 itself, GPT-4 Turbo, a GPT-4o snapshot and
**gpt-4.1-nano**, which is not old as these things go, beside the six o-series entries of section
03. A provider clearing its catalogue does so in batches, on one date, and every product that named
any of those models gets the same week to react.

Three habits, from lessons 2 and 5, that turn this from an incident into a task:

1. **Know which identifiers your code names.** One line in configuration per task (lesson 6 section
   04), so the list of what depends on a retiring model is a search, not an investigation.
2. **Read the retiring list on a schedule.** `sheet.py retiring` is the third party's copy; the
   provider's own deprecations page and the e-mails it sends are the source. Monthly is enough when
   retirements are announced months ahead.
3. **Keep the evaluation runnable.** A replacement chosen by running lesson 5's cases against two or
   three successors is a day's work; chosen under the retirement date without them, it is a guess
   that ships.

Notice also what is **not** on the list. `gpt-4.1` and `gpt-4.1-mini` are in the sheet with no date,
while their nano sibling has one. Retirement goes model by model, not
family by family, which is why the identifier in the code is the thing to check, not the family's
name.
