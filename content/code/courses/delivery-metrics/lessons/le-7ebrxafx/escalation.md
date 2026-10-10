---
title: Escalation, and the expert everyone calls
version: 1
---

An **escalation policy** says what happens when a page is not answered, or when the person who answered cannot solve it. It has two directions, and teams that mix them up end up with the wrong person awake.

## Up the chain when nobody answers

The first direction is mechanical, and the paging tool does it on its own:

| after | the page goes to |
|---|---|
| 0 minutes | the primary |
| 5 minutes unacknowledged | the secondary |
| 15 minutes unacknowledged | the tech lead |

The times are short because they add up: an incident that needs two missed pages before anybody looks at it has lost a quarter of an hour, which is about what the Billing team lost on 30 September waiting for a shop owner to call. Five minutes is long enough to find a phone and short enough that a deep sleeper is not the only safeguard.

## Across to whoever knows

The second direction is a judgement. The primary has acknowledged, looked, and found a problem in code they do not know well. They can **pass it to the person who does**, and every team has such a person. On the Billing team it is Rafa, who wrote most of the card code.

Passing a hard problem to the expert is the right call during an incident. Doing it every time, for months, has a cost nobody records, because the rota shows Rafa on call one week in five and the pager shows something else.

## What the pager shows

**Save the program below as `oncall.py`.** It writes a quarter of the Billing team's pages, thirteen weeks from 8 July, and counts who each page woke.

```schooling-example
{
  "language": "python",
  "file": "oncall.py",
  "parts": [
    {
      "code": "\"\"\"oncall.py: who the pager woke, over a quarter of the Billing team's rota.\"\"\"\nimport random\nfrom collections import Counter\nfrom datetime import datetime, timedelta\n\nROTA = [\"Duda\", \"Ines\", \"Rafa\", \"Teo\", \"Caio\"]        # one week each, in turn\nEXPERT = \"Rafa\"                                       # wrote most of the card code\nrng = random.Random(13)\n\n# Thirteen weeks from Wednesday 8 July, the handover day. Each day brings some pages at\n# random hours, more in the last days of the month; a page about the card provider is\n# passed to Rafa when Rafa is not the one on call, because nobody else knows that code.\npages = []\nfor week in range(13):\n    start = datetime(2026, 7, 8) + timedelta(weeks=week)\n    on_call = ROTA[week % len(ROTA)]\n    for day in range(7):\n        when = start + timedelta(days=day)\n        for _ in range(rng.choice([0, 0, 0, 1, 1, 2] if when.day < 25 else [1, 2, 3])):\n            at = when + timedelta(minutes=rng.randrange(24 * 60))\n            card = rng.random() < 0.4\n            pages.append((at, on_call, EXPERT if card and on_call != EXPERT else None))\n\n",
      "note": "**The rota and the pages, written by the program.** Five people take a week each, handing over on Wednesdays. Every day brings up to two pages at random hours, and up to three in the last week of the month, when the shops close their books. Four pages in ten are about the card provider, and those are passed to Rafa whenever somebody else holds the pager."
    },
    {
      "code": "woken, nights, passed = Counter(), Counter(), Counter()\nfor at, on_call, expert in pages:\n    night = at.hour >= 22 or at.hour < 7\n    for person in filter(None, (on_call, expert)):\n        woken[person] += 1\n        nights[person] += night\n    passed[expert] += expert is not None\nprint(f\"{len(pages)} pages in 13 weeks, {sum(1 for p in pages if p[0].hour >= 22 or p[0].hour < 7)} at night\")\nfor person in ROTA:\n    weeks = sum(1 for w in range(13) if ROTA[w % len(ROTA)] == person)\n    print(f\"  {person:5} {weeks} weeks on call  {woken[person]:3} pages  \"\n          f\"{nights[person]:2} at night  {passed[person]:2} passed on by others\")\n",
      "note": "**Who each page woke.** A page wakes the person on call, and also Rafa when it was passed on. The program counts every person's pages, those between 22:00 and 07:00, and how many reached them from somebody else's week."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 oncall.py
82 pages in 13 weeks, 25 at night
  Duda  3 weeks on call   17 pages   6 at night   0 passed on by others
  Ines  3 weeks on call   21 pages   7 at night   0 passed on by others
  Rafa  3 weeks on call   54 pages  14 at night  29 passed on by others
  Teo   2 weeks on call   13 pages   3 at night   0 passed on by others
  Caio  2 weeks on call    6 pages   3 at night   0 passed on by others
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 270\" role=\"img\" data-fig=\"l17-load\" aria-label=\"Horizontal bars, one per person on the Billing team's rota, showing how many pages woke them in thirteen weeks. Duda 17, Inês 21, Téo 13 and Caio 6, all from their own weeks. Rafa 54: 25 from his own weeks and 29 passed on from other people's.\"><text x=\"100.0\" y=\"68.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Duda</text><path d=\"M110.0 58.0 L248.8 58.0 L248.8 78.0 L110.0 78.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"256.8\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">17</text><text x=\"100.0\" y=\"100.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Inês</text><path d=\"M110.0 90.0 L281.5 90.0 L281.5 110.0 L110.0 110.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"289.5\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">21</text><text x=\"100.0\" y=\"132.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Rafa</text><path d=\"M110.0 122.0 L314.2 122.0 L314.2 142.0 L110.0 142.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M314.2 122.0 L551.0 122.0 L551.0 142.0 L314.2 142.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"559.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">54</text><text x=\"100.0\" y=\"164.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Téo</text><path d=\"M110.0 154.0 L216.2 154.0 L216.2 174.0 L110.0 174.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"224.2\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">13</text><text x=\"100.0\" y=\"196.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Caio</text><path d=\"M110.0 186.0 L159.0 186.0 L159.0 206.0 L110.0 206.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"167.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">6</text><text x=\"110.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"273.3\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><text x=\"436.7\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><text x=\"600.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M110.0 50.0 L110.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M110.0 250.0 L124.0 250.0 L124.0 260.0 L110.0 260.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"130.0\" y=\"255.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in their own week on call</text><path d=\"M340.0 250.0 L354.0 250.0 L354.0 260.0 L340.0 260.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"360.0\" y=\"255.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">passed on from somebody else's week</text><text x=\"110.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pages that woke each person, 8 July to 6 October</text></svg>", "caption": "The rota shares the weeks evenly. The pager does not share the pages."}
```

**Rafa was on call for three weeks, like Duda and Inês, and was paged more than the two of them together**: 54 times, 29 of them in other people's weeks. The rota says the load is shared five ways. The pager says one person carries nearly half of it, and nothing on the rota would ever show that.

The program shows a second, quieter unfairness. Caio was paged 6 times and Inês 21, and neither had anything to do with it: two of Inês's three weeks, and all three of Rafa's, included the end of the month, when the shops close their books and the pages come in threes; none of Caio's did. A rota of five weeks against a month of a little over four drifts slowly, so the month-end falls on the same people for several months running before it moves on. Section 06 comes back to both.

## Why the expert pattern hurts everyone

- **The expert never rests.** Off-call weeks are when people recover. An expert who is reachable every week is on call every week, unpaid for four of them.
- **Nobody else learns.** Every problem passed to Rafa is a problem Caio, Duda, Inês and Téo did not have to solve, and so cannot solve the next time.
- **The team has a single point of failure.** The night Rafa is on a plane, or ill, or has left the company, the card code has no one.

## Spreading what one person knows

The fix is not to forbid passing problems on, which would only make incidents longer. It is to make passing them on less necessary:

- **a runbook for every alert that pages**, written by the expert, saying what the alert means and what to try first; lesson 18 makes this a rule;
- **shadow shifts**, where a newcomer carries the pager beside somebody experienced before carrying it alone;
- **the expert answers in a call, not by taking over**, so the person on call types the commands and learns them;
- **the next postmortem asks "who did we have to wake, and why"**, so the knowledge that was missing becomes an action item like any other.
