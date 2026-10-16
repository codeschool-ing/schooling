---
title: A rotation, and the handoff between shifts
version: 1
---

Lesson 10 ended with a page reaching a topic. Somebody has to be at the other end of it, at three in the
morning as much as at three in the afternoon, and **on-call is the arrangement that says who**: one
person at a time answers the pages for a service, for a fixed shift, and then hands over to the next.
Nobody is on call for ever, and nobody is on call alone.

## Primary and secondary

A rotation names two people for each shift. The **primary** answers every page. The **secondary** is paged
when the primary does not answer, which happens to everybody sooner or later: a phone in another room, a
tunnel, a shower. A week is the common shift for a small team, starting on a weekday morning so the
handoff happens with everybody awake. A rule that costs nothing makes the secondary useful: **this week's
secondary is last week's primary**, who still remembers what was strange.

A rotation is a list and a date, so it is a small program:

```python
# rotation.py: who is primary and who is secondary, week by week
import datetime as dt

people = ["Ana", "Bruno", "Carla", "Davi"]
first = dt.date(2026, 10, 19)  # a Monday; every shift starts at 10:00

for week in range(8):
    start = first + dt.timedelta(weeks=week)
    primary = people[week % len(people)]
    secondary = people[(week - 1) % len(people)]  # last week's primary
    print(f"{start:%a %d %b}  primary {primary:<6} secondary {secondary}")
```

```
ana@laptop:~/aws/oncall$ python3 rotation.py
Mon 19 Oct  primary Ana    secondary Davi
Mon 26 Oct  primary Bruno  secondary Ana
Mon 02 Nov  primary Carla  secondary Bruno
Mon 09 Nov  primary Davi   secondary Carla
Mon 16 Nov  primary Ana    secondary Davi
Mon 23 Nov  primary Bruno  secondary Ana
Mon 30 Nov  primary Carla  secondary Bruno
Mon 07 Dec  primary Davi   secondary Carla
```

Four people, so each is primary one week in four and secondary the week after. Fewer than four and the
weeks come round too often to rest between them; Google's SRE book argues for at least eight people per
site for a service that pages at night, or six in each of two sites that hand over across time zones.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A grid of four people, Ana, Bruno, Carla and Davi, over eight weeks from 19 October to 7 December. Each week one person is primary and the person who was primary the week before is secondary, so the primary cells step down the grid diagonally and the secondary cells follow one week behind. Each person is primary one week in four.\"><defs><marker id=\"rot-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"123.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">19 Oct</text><text x=\"201.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">26 Oct</text><text x=\"279.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 Nov</text><text x=\"357.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">9 Nov</text><text x=\"435.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">16 Nov</text><text x=\"513.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">23 Nov</text><text x=\"591.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">30 Nov</text><text x=\"669.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">7 Dec</text><text x=\"20\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Ana</text><rect x=\"87\" y=\"54\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"123.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primary</text><rect x=\"165\" y=\"54\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"201.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secondary</text><rect x=\"399\" y=\"54\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"435.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primary</text><rect x=\"477\" y=\"54\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"513.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secondary</text><text x=\"20\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Bruno</text><rect x=\"165\" y=\"92\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"201.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primary</text><rect x=\"243\" y=\"92\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"279.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secondary</text><rect x=\"477\" y=\"92\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"513.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primary</text><rect x=\"555\" y=\"92\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"591.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secondary</text><text x=\"20\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Carla</text><rect x=\"243\" y=\"130\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"279.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primary</text><rect x=\"321\" y=\"130\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"357.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secondary</text><rect x=\"555\" y=\"130\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"591.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primary</text><rect x=\"633\" y=\"130\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"669.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secondary</text><text x=\"20\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Davi</text><rect x=\"87\" y=\"168\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"123.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secondary</text><rect x=\"321\" y=\"168\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"357.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primary</text><rect x=\"399\" y=\"168\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"435.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secondary</text><rect x=\"633\" y=\"168\" width=\"72\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"669.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primary</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Each week the primary of the week before becomes the secondary.</text></svg>", "caption": "Four people, so one week in four as primary and one as secondary, and two weeks off."}
```

## What a shift may cost

A rotation is humane or not by numbers that can be measured:

- **pages per shift**. The SRE book's figure is at most two incidents in a twelve-hour shift, because an
  incident and its follow-up take most of a day; more than that and the follow-up never happens;
- **pages at night**, counted apart, since a page at 03:00 costs the next day as well;
- **time off after a bad night**, written into the team's rules rather than left to each person's
  courage to ask.

The section on fatigue measures the first two from a month of pages.

## The handoff

**A shift ends with a note**, written by the outgoing primary and read by the incoming one, in the place
the team keeps them. It holds what the next person needs and cannot see on a dashboard:

> **Handoff, Mon 26 Oct, Ana to Bruno.** Two pages: `api-errors` on Wed (bad deploy, rolled back, review
> on Thu) and `db-cpu` on Sat (nothing to do, ticket to retune it). Open: the certificate on
> `checkout.example.com` renews on Fri, watch for it. Nothing was changed by hand.

The last line matters most. A change made by hand during a shift, and not recorded, is the cause of the
next person's incident.
