---
title: The timeline: what people knew, not only what happened
version: 1
---

**A postmortem timeline records, for each moment, what happened, what the people involved could see,
and what they decided.** A timeline of events alone ("19:05 job started; 19:09 errors") is a log. The
decisions and what they rested on are what turn it into something a team can learn from.

## Built from three sources

Diego, the scribe on the night, had kept notes in the incident channel. Lívia combined them with the
system's own logs and with short conversations with the four people involved, each asked the same
questions: *what were you looking at, what did you think was happening, and what did you decide?*

| time | what happened | what they could see, and decided |
|---|---|---|
| 19:05 | Paulo starts the zone backfill | the runbook says to run it when zones change; zones changed at 16:00; nothing mentions peak hours |
| 19:09 | database connections reach the limit; checkout starts failing | nobody is looking at connections; no alert on them |
| 19:16 | alert: checkout error rate above 5% for 5 minutes | Bruna, on call, is paged; the alert names checkout, not the database |
| 19:19 | Bruna declares an incident and opens #inc-0306 | she suspects a bad checkout deploy, the usual cause; there was none that day |
| 19:31 | Lucas sees connections at the limit, and the backfill among the clients | he asks in the channel who started it |
| 19:36 | Paulo, who had gone home, sees the channel and replies | he stops the job as soon as he is asked |
| 19:38 | the backfill is stopped | |
| 19:41 | connections fall; checkout recovers | |

## What the third column shows

Read down the right-hand column and the incident looks different:

- **Paulo's decision at 19:05 was correct by everything he could see.** The runbook was the problem.
- **For seven minutes nothing measured the cause.** The alert that fired measured the symptom, and it
  pointed the commander at checkout, where nothing was wrong.
- **Twelve minutes went to a hypothesis that was reasonable and wrong**: a bad deploy, because that is
  what usually breaks checkout.
- **Once the right person asked the right question, the fix took seven minutes.** The slow part was
  getting to the question.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A bar from 19:05 to 19:41 split into five parts: the job runs from 19:05 to 19:09; nothing measures the cause from 19:09 to 19:16; the responders look at checkout from 19:16 to 19:31; they ask who started the job from 19:31 to 19:38; the job is stopped and checkout recovers by 19:41.\"><defs><marker id=\"gapsbars-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"120.0\" y=\"40\" width=\"61.33333333333334\" height=\"40\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"183.33333333333334\" y=\"40\" width=\"108.83333333333329\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"294.16666666666663\" y=\"40\" width=\"235.5000000000001\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"531.6666666666667\" y=\"40\" width=\"108.83333333333326\" height=\"40\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"642.5\" y=\"40\" width=\"45.5\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"151.66666666666669\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">job runs</text><text x=\"120.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:05</text><text x=\"238.75\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nothing measures it</text><text x=\"183.33333333333334\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:09</text><text x=\"412.9166666666667\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">looking at checkout</text><text x=\"294.16666666666663\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:16</text><text x=\"587.0833333333334\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">asking who</text><text x=\"531.6666666666667\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:31</text><text x=\"666.25\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">stop</text><text x=\"642.5\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:38</text><text x=\"690.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:41</text><text x=\"20\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">6 March</text><text x=\"183.33333333333334\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">7 minutes with no signal on the cause</text><text x=\"294.16666666666663\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">15 minutes looking at checkout, where nothing was wrong</text><text x=\"690.0\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">10 minutes from the right question to recovery</text></svg>", "caption": "Where the 32 minutes went. The fix itself was the shortest part; most of the time went to not seeing the cause and then looking in the usual place."}
```

## Writing it without blame

The words in the timeline matter as much as the facts. "Paulo ran the job during peak" carries a
judgement in *during peak*: it was peak, and nobody had told him that mattered. "Paulo starts the zone
backfill; the runbook does not mention peak hours" states both facts and leaves the reader to see where
the problem is. **Describe what people did and what they could see; leave the evaluation to the
analysis, where it is about the system.**

Hindsight makes everything look obvious. Read every timeline once with the question: *at
that minute, without knowing how it ended, would I have known better?* Where the honest answer is no,
the lesson is about the system.
