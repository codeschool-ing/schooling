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

@@CAPTURE dates@@

The first line is what a compile in mid-2024 would have produced, the second what this lesson's
compile produces. And linkbox's own ranges as of the start of August fail outright, because no
gunicorn 26.2 existed yet: the resolver says which requirement could not be met. **A date makes a
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

@@FIGURE cooloff@@

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
