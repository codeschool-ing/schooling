---
title: What a log line carries
version: 1
---

Lesson 17 left a promise: to come back to what a log line has to carry to be useful. This is A09,
and it is the category where a tester's question is the simplest one in the plan. **When something
happens that matters to security, could somebody reading the log tomorrow say what happened?** If
the answer needs the person who was there, the log failed.

## Four things in, one thing never

A security event is a sign-in, a failed sign-in, a refusal, a lockout, a change of role, an error
nobody planned for. A line recording one carries four things:

- **When**, to the millisecond, with the time zone or in UTC, so that lines from two machines can be
  put in order.
- **Who**: the account that asked, or the name somebody tried to sign in as. Not their password,
  and not more personal data than the line needs.
- **What**: the action and the thing it was aimed at, `GET /staff/bookings`, not "a request".
- **The outcome**: allowed, refused, failed, and why, in words a person can search for.

And it **never carries a secret**: no password, tried or real, no session token, no cookie, no API
key, no full card number. A log is copied to more places and kept longer than the database, and it
is read by more people. A secret written into it has leaked, in the sense of lesson 18, the moment
the line is written.

## account.py's lines, read against the list

The three probes of "The rows a test can hold" went to the same service: a wrong password for
`ana`, a sign-in as a name with a line break and a marker in it, and `ana` asking for the staff
list. These are the last three lines of the service's terminal after them:

```
2026-10-15 21:39:57,369 WARNING failed sign-in for 'ana'
2026-10-15 21:39:57,437 WARNING failed sign-in for 'nft\nWARNING nft-probe'
2026-10-15 21:39:57,464 WARNING refused GET /staff/bookings to account 1: staff only
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l19-logline\" aria-label=\"One line from account.py's log, cut into its parts: 2026-10-15 21:39:57,464 is when, WARNING is the severity, refused is the outcome, GET /staff/bookings is what was asked, account 1 is who asked, and staff only is why it was refused. Below, the things a line never carries: a password, a session token, a cookie, an API key.\"><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">a line somebody can read tomorrow</text><rect x=\"84.0\" y=\"52.0\" width=\"553.2\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"96.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026-10-15 21:39:57,464</text><path d=\"M97.0 94.0 L239.9 94.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M168.4 94.0 L168.4 102.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"168.4\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">when</text><text x=\"247.2\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WARNING</text><path d=\"M248.2 94.0 L290.3 94.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M269.2 94.0 L269.2 118.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"269.2\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">severity</text><text x=\"297.6\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">refused</text><path d=\"M298.6 94.0 L340.7 94.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M319.7 94.0 L319.7 102.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"319.7\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">outcome</text><text x=\"348.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET /staff/bookings</text><path d=\"M349.0 94.0 L466.7 94.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M407.9 94.0 L407.9 118.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"407.9\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">what</text><text x=\"474.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">to</text><text x=\"492.9\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">account 1</text><path d=\"M493.9 94.0 L548.6 94.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M521.2 94.0 L521.2 102.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"521.2\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">who</text><text x=\"549.6\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:</text><text x=\"562.2\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">staff only</text><path d=\"M563.2 94.0 L624.2 94.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M593.7 94.0 L593.7 118.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"593.7\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">why</text><rect x=\"150.0\" y=\"170.0\" width=\"420.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">never in a line</text><text x=\"360.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a password · a session token · a cookie · an API key</text></svg>", "caption": "When, who, what and the outcome, and no secret: the refusal line already has all of it."}
```

The refusal is the good line to learn from. **When**: `2026-10-15 21:39:57,464`. **Who**:
`account 1`, the id rather than the name, which is enough for whoever can look the account up and
nothing for whoever cannot. **What**: `GET /staff/bookings`. **Outcome and reason**: `refused`,
`staff only`. The two failed sign-ins carry the name that was tried and no password, which is what
`test_a_failed_sign_in_is_logged_without_the_password` now holds.

The second line is the probe. The name sent was `nft`, a line break and `WARNING nft-probe`. Had the
service written it as it arrived, the log would show a second line starting with `WARNING`, one
that the service never wrote and that somebody reading the log would believe. **The service writes
names with `%r`**, so the break comes out as the two characters `\n`, inside quotes, on the line it
belongs to. A test now holds that too, because a log that anybody can add lines to is a log nobody
can use as evidence.

Reading the same lines against the list turns up two gaps, and a tester's job is to say so:

- **The time has no zone.** `21:39:57` is local time on this machine, and the line does not say
  which zone that is. On one machine it is fine; across a fleet, or after a change to daylight
  saving, the order of events becomes a guess. A small fix, in the logging format.
- **A success leaves no line at all.** `ana` registered and signed in at the start of "The rows a test can hold",
  and neither appears. A failed sign-in is evidence of somebody guessing; **a successful sign-in is
  the only trace of somebody using a password they should not have**, and here there is none. That
  is finding F19-3, and its severity is medium because it is the line an investigation would need
  first.

## Logged is not the same as noticed

The second half of A09's name is *alerting*. Five failed sign-ins and a lockout, written neatly in a
file that nobody reads until a customer complains, defended nobody. **A log line is a record; an
alert is what makes somebody act on it**, and the useful ones for this service are rates, not single
lines: refusals per minute far above normal, lockouts across many names at once. Lesson 22 sends the
box office's logs and numbers to a place where they can be watched, and lesson 24 writes the alerts
and decides who they wake up.

The plan's row for it says *a review today*, honestly. The test for an alert is lesson 24's, where
the rule exists to be tested.
