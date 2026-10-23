---
title: A date in the compile, and an update decided
version: 1
---

`uv pip compile` without a date answers a question about the moment it runs: what do these ranges
resolve to on PyPI right now? Run it next week and the answer may differ, because somebody published
something. **`--exclude-newer 2026-10-16` changes the question to one with a fixed answer**: what did
these ranges resolve to using only files uploaded before that date? The date is written into the
header of the lock, so anybody can rerun the same command and get the same file.

### The same ranges at two dates

A bare `flask`, with no range at all, resolved as of two dates:

```
ana@vm:~/linkbox$ for d in 2024-06-01 2026-10-16; do echo "$d: $(echo flask | uv pip compile - --exclude-newer $d --no-header 2>/dev/null | grep -E "^(flask|werkzeug)==" | tr "\n" " ")"; done
2024-06-01: flask==3.0.3 werkzeug==3.0.3 
2026-10-16: flask==3.1.3 werkzeug==3.1.9 
ana@vm:~/linkbox$ uv pip compile requirements.in --exclude-newer 2026-08-01 --no-header 2>&1 | tail -n 1
hint: `gunicorn` was filtered by `exclude-newer` to only include packages uploaded before 2026-08-02T03:00:00Z. The latest version satisfying the requirement is v26.2.0, published at 2026-08-24T15:05:57.67Z. Consider using `exclude-newer-package` to override the cutoff for this package.
```

The first line is what a compile in mid-2024 would have produced, the second what this lesson's
compile produces. And linkbox's own ranges as of the start of August fail outright, because no
gunicorn 26.2 existed yet. The last line of uv's error, its hint, says so and names the upload that
would have satisfied the range. **A date makes a
resolution reproducible, and it also makes it explicit**: moving the date is a change to a file,
reviewed like any other, and the diff of the lock shows exactly what moving it did.

### The date as a cooling-off period

The date does a second job, and for security it is the more important one. Malicious releases are
usually found and removed within days: the incidents lesson 12 placed on the supply chain, from
event-stream to the packages published from stolen maintainer accounts, were each live for hours or
days before somebody noticed. **A compile that refuses anything uploaded in the last few days never
picks up a release in that window**, whatever its version number says.

So the date in this lesson's command is a week before the recording, on purpose. The rule a team can
adopt is simple to state: the date moves forward when somebody chooses to update, and it never moves
closer to today than a fixed number of days. uv can also take the cooling-off from a setting rather
than the command line, and lesson 18 configures the same idea, a minimum release age, for the bots
that propose updates.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 175\" role=\"img\" data-fig=\"sp-l15-cooloff\" aria-label=\"A timeline. A bad release is published, found and removed within days. A compile with an exclude-newer date a week before today sees only what was uploaded before that date, so a release in the window is never picked up. Moving the date forward is a deliberate change to the lock.\"><defs><marker id=\"sp-l15-cooloff-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l15-cooloff-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20 122 L700 122\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l15-cooloff-ah-paper-dim)\"></path><rect x=\"20\" y=\"70\" width=\"430\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"235\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what the compile can see</text><rect x=\"450\" y=\"70\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"640\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">not seen yet</text><line x1=\"450\" y1=\"40\" x2=\"450\" y2=\"66\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"450\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">--exclude-newer</text><line x1=\"690\" y1=\"40\" x2=\"690\" y2=\"66\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"690\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">today</text><text x=\"570\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a week</text><path d=\"M520 140 L520 112\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l15-cooloff-ah-amber)\"></path><text x=\"515\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">a bad release published</text><text x=\"525\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">→ found and removed</text></svg>", "caption": "The compile looks only at what was uploaded before the date, so a release has to survive a week of other people's scrutiny before it can reach the lock."}
```

The cost is real and worth saying: a fix published yesterday for an advisory published yesterday is
also held back. That is the case for an exception, made by a person, for one package; the lesson 7
gate already has a place for decisions like that, with an owner and a date.

### Updating gunicorn from 22 to 26

The compile moved gunicorn from 22.0.0 to 26.2.0 because `requirements.in` asks for `>=26.2,<27`.
That range is a decision, and it deserves the questions an update always gets:

1. **What changed?** Four major versions, 23 to 26. Each major's notes are in gunicorn's changelog
   at gunicorn.org/news, linked from PyPI, and the questions to bring to them are narrow: does any
   removed setting appear in how linkbox starts gunicorn, and does any default it relies on change?
   linkbox passes one setting, `--bind`, in the Dockerfile's entry point. The changelog was not
   reproduced here; reading it is the step, and it is yours to take for the version you meet.
2. **What does it bring in or take out?** Nothing in, `packaging` out, as the previous section
   showed.
3. **Do the tests pass?** They did, against the new lock, in the previous section.
4. **Does the service still start the way it runs in production?** That is the image built in the
   next section and run by the pipeline, and lesson 4's nightly staging scan runs it as a server.

**An update across four majors is not risky because the number is large; it is risky when nobody
read what changed.** Read, tested and run, it is the ordinary move, and staying on 22 would only
have made the next jump longer.
