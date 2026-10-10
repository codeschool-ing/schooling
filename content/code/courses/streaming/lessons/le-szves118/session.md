---
title: Session windows
version: 1
---

**A session window has no fixed length: it lasts as long as events keep coming, and closes after a
gap of inactivity.** It is the window for questions about bursts of activity whose length nobody
knows in advance: a customer's visit to the website, a till's busy spell, a delivery van's round.

The rule is a gap. With a gap of five minutes, an event less than five minutes after the last one
of a session joins it and extends it; an event five minutes or more after starts a new session.
Session 1 of the ten sales begins at 09:00:40, and sales 2 to 5 each arrive within two minutes of
the one before. Then there is a pause: 09:06:20 to 09:12:30 is six minutes and ten seconds, more
than the gap.

```
ubuntu@stream:~/work$ python windows.py session 5
```

The program printed one session where the paragraph above predicted two, and the line in
parentheses says why. **A late event can join two sessions into one.** In arrival order, sales 1
to 5 made one session ending at 09:06:20; sale 6 at 09:12:30 was more than five minutes after it,
so it started a second, which sale 7 extended. Then sale 8 arrived: it happened at 09:08:50, two
and a half minutes after the first session's last sale and under four minutes before the second
one's first. It is near both, so it belongs to both, and the two become one session from 09:00:40
to 09:14:10 with nine sales. Sale 10, seven minutes later, is alone.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two timelines of five-minute sessions. Above, after sale 7 has arrived: one session from 09:00:40 to 09:06:20 with five sales, and another from 09:12:30 to 09:13:05 with two, more than five minutes apart. Below, after sale 8, which happened at 09:08:50, has arrived: it is within five minutes of both, and the two sessions become one from 09:00:40 to 09:13:05.\" data-fig=\"l10-session-merge\"><text x=\"10\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">after sale 7 arrives</text><text x=\"690\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">two sessions</text><circle cx=\"170.4\" cy=\"60\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"197.0\" cy=\"60\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"228.0\" cy=\"60\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"247.1\" cy=\"60\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"270.8\" cy=\"60\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"380.0\" cy=\"60\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"390.3\" cy=\"60\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><rect x=\"164.4\" y=\"48\" width=\"112.4\" height=\"24\" rx=\"6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"374.0\" y=\"48\" width=\"22.30000000000001\" height=\"24\" rx=\"6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"325.4\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gap 6 min 10 s</text><text x=\"10\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">after sale 8 arrives</text><text x=\"690\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one session</text><circle cx=\"170.4\" cy=\"150\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"197.0\" cy=\"150\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"228.0\" cy=\"150\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"247.1\" cy=\"150\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"270.8\" cy=\"150\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"380.0\" cy=\"150\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"390.3\" cy=\"150\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"315.0\" cy=\"150\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></circle><rect x=\"164.4\" y=\"138\" width=\"231.9\" height=\"24\" rx=\"6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sale 8, 09:08:50</text><line x1=\"70\" y1=\"210\" x2=\"690\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"70.0\" y1=\"207\" x2=\"70.0\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"70.0\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">08:55</text><line x1=\"158.6\" y1=\"207\" x2=\"158.6\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"158.6\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:00</text><line x1=\"247.1\" y1=\"207\" x2=\"247.1\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"247.1\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:05</text><line x1=\"335.7\" y1=\"207\" x2=\"335.7\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"335.7\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:10</text><line x1=\"424.3\" y1=\"207\" x2=\"424.3\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"424.3\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:15</text><line x1=\"512.9\" y1=\"207\" x2=\"512.9\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"512.9\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:20</text><line x1=\"601.4\" y1=\"207\" x2=\"601.4\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"601.4\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:25</text><line x1=\"690.0\" y1=\"207\" x2=\"690.0\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"690.0\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:30</text></svg>", "caption": "A late event can join two sessions into one. Their edges are made by the events, so an event that arrives late can move them."}
```

That merge is the defining difficulty of sessions in a stream. A tumbling window's edges are
known before any event arrives; a session's edges are made by the events, and an event that was
late can move them. An engine that had already reported "session 2: 09:12:30 to 09:13:05, two
sales" has to withdraw it and report a merged session instead. Flink and Kafka Streams both do
exactly that: each event starts as a session of its own, and overlapping sessions are merged as
they are found.

## What the printed edges mean

The program prints a session from its first sale to its last, so a session of one sale is
`09:21:00-09:21:00`. The window itself lasts longer: nothing can be added to it once a gap has
passed after its last event, so the 09:21:00 session cannot close before 09:26:00. Flink makes
that explicit and gives each session the window from its first event to its last event **plus**
the gap; Kafka Streams reports first and last. Either way, **a session's end is only known once
the gap has gone by with nothing in it**, which on a stream means once something has arrived that
shows that much time has passed. That is lesson 11's question again.

The gap is the whole design. Shorten it to three minutes and the program finds three sessions:

```
ubuntu@stream:~/work$ python windows.py session 3
```

The first session now stops at 09:08:50, because sale 8 bridges a pause of 2 minutes 30 seconds
and not the next one of 3 minutes 40 seconds, and 09:12:30 to 09:14:10 stands on its own. A gap
that is too short splits one visit into many; one that is too long joins strangers. For a website
the usual starting point is thirty minutes, an old convention from web analytics, and for tills
it should come from how long a shop actually goes quiet between customers, measured.
