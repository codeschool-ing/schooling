---
title: Comments that teach
version: 1
---

**A comment that teaches says what the reviewer noticed, why it matters, and how sure they are, and it
leaves the author room to answer.** A comment that only commands ("rename this", "use a dict") fixes the
line and teaches the author to wait for the next command.

## A real review, line by line

In July Diego reviewed his first pull request outside checkout, from Rafael, who had joined logistics
three weeks earlier. The change offered drivers their next delivery windows. Lívia read Diego's draft
comments with him before he posted them, as part of lesson 10's plan. These are the comments he posted,
next to the code they were about:

```schooling-example
{"language": "python", "file": "slots.py", "parts": [{"code": "from datetime import datetime, timedelta\n\nCLOSING_HOUR = 22\n", "note": "issue (blocking): CLOSING_HOUR is defined and never used, so nothing stops the function offering a window after the depot closes. Called at 21:10 it returns 22:00, 23:00 and 00:00. Could the loop stop at closing time?"}, {"code": "\n\ndef next_slots(now, count=3):\n    first = now.replace(minute=0, second=0, microsecond=0) + timedelta(hours=1)\n", "note": "question: does the depot close at 22:00 on Saturdays too? I don't know logistics' hours. If they differ by day, one constant won't be enough."}, {"code": "    slots = []\n    for i in range(count):\n        slots.append(first + timedelta(hours=i))\n    return slots\n", "note": "praise: the loop is easy to follow, and the name says what it returns. nitpick (non-blocking): this could be a list comprehension; fine either way."}]}
```

Called at 21:10, the function returns 22:00, 23:00 and 00:00 the next day. The depot closes at 22:00,
so two of the three windows it offers do not exist. The constant that would have prevented it is
right there, unused. Diego's comment on it is the one that matters, and the others are there because
review is mostly teaching.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Diego&#x27;s blocking comment split into four parts. The label, issue blocking: how much it matters. What was noticed, CLOSING_HOUR is never used: one specific thing. Why it matters, at 21:10 it offers 22:00, 23:00 and 00:00: the effect, concretely. The opening, could the loop stop: room to answer.\"><defs><marker id=\"commentana-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"6\" y=\"30\" width=\"128\" height=\"54\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"12\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">issue (blocking):</text><text x=\"10\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">label</text><text x=\"10\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">how much it matters</text><rect x=\"140\" y=\"30\" width=\"196\" height=\"54\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"146\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CLOSING_HOUR is never used</text><text x=\"144\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">what was noticed</text><text x=\"144\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one specific thing</text><rect x=\"342\" y=\"30\" width=\"208\" height=\"54\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"348\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">21:10 → 22:00, 23:00, 00:00</text><text x=\"346\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">why it matters</text><text x=\"346\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the effect, concretely</text><rect x=\"556\" y=\"30\" width=\"150\" height=\"54\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"562\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">could the loop stop…?</text><text x=\"560\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the opening</text><text x=\"560\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">room to answer</text><text x=\"14\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a comment that only commands keeps the second box and drops the other three</text></svg>", "caption": "The anatomy of a comment that teaches, using Diego's comment from the example above."}
```

## Say how much it matters

The most useful habit in that review is the label at the start of each comment. **Conventional
Comments**, a small published convention, suggests starting every comment with a word that says what
kind of comment it is:

| label | means |
|---|---|
| **praise** | something done well, said specifically |
| **issue** | a problem that must be fixed before merging |
| **question** | the reviewer does not understand, and is asking, not hinting |
| **suggestion** | a better way, which the author may decline |
| **nitpick** | trivial; take it or leave it |
| **thought** | an idea for later, not for this change |

With the labels, Rafael knew at a glance that one comment blocked the merge and the rest did not.
Without them, a new engineer reads five comments from a reviewer as five demands, and the one that
matters is lost among the four that do not.

## Ask, when you are asking

A question in a review is often a command in disguise: "Did you consider using a dict here?" means
"use a dict". **If you mean it as a suggestion, write it as one; ask a question only when you do not
know the answer.** Diego's question about Saturdays was real: he did not know whether the depot's
hours changed at weekends, and Rafael did. The answer, "they do, there's a table for it", became a
second issue that neither of them had seen at first.

## Praise specifically

"LGTM" teaches nothing. "The loop is easy to follow and the name says what it returns" tells Rafael
what to keep doing. **Specific praise is calibration**: it tells the author which of their choices
were deliberate good ones, so they repeat them on purpose.
