---
title: A week of the routine
version: 1
---

"Shared responsibility for security" is the sentence every DevSecOps talk contains, and it says
nothing until it is a set of habits somebody could watch. This section follows one small team for a
week, with the pipeline this course builds, and names each habit as it appears. Lessons 2 to 20
take them one at a time.

### Monday: a change, and a build that breaks

A developer adds a filter to linkbox's search and writes the SQL by joining the user's text into
the query. Before pushing, they run the pipeline's fast stages on their laptop, the same script the
server runs, and the static analysis stage stops at the line, naming the rule and the reason. They
change the query to take a parameter, add a test with a quote in the search text, and push. The
whole loop took ten minutes and nobody else was involved.

**Habit: the same checks run on the laptop and on the server.** Lesson 2 builds that, and lesson 3
writes the static analysis it ran.

### Tuesday: a finding nobody can fix

The composition analysis stage reports an advisory in a library the service uses. There is no
fixed version yet. Breaking every build until the maintainers publish one would stop all work for
a problem nobody on the team can solve, so the pipeline reports it as a warning and the build
passes. The team's security champion, a developer who spends a few hours a week on this, reads the
advisory: it needs a feature linkbox does not use. They record that, with a date to look again.

**Habit: a check breaks the build only for something the person who broke it can fix.** Lesson 7 is
the whole argument, and the course's other lessons lean on it.

### Wednesday: a secret in a commit

Somebody pastes a token into a test file to try something and commits it. The commit never leaves
their laptop: a hook scans what is staged and refuses it. Had it been pushed, the first stage on
the server would have refused it again, and the response would have started with **revoking the
token, not with deleting the line**, because a pushed secret has been copied wherever the
repository has been cloned.

**Habit: secrets are caught before they are shared, and treated as burned once they are.**
Lesson 6.

### Thursday: the nightly run

Overnight, the pipeline rebuilt the image from nothing, with no cache. A package in the base image
had a fix published the day before, and the rebuild picked it up without anybody editing a line. The dynamic scan of the staging copy also ran overnight, because it takes
minutes the pushes of the day should not wait for.

**Habit: slow checks run on a schedule, so the fast ones can run on every push.** Lessons 2, 4 and 8.

### Friday: what the week counted

The champion looks at four numbers: how many findings were opened and closed, how long the open
ones have been open, which repositories and images were scanned at all, and how many exceptions
expire next week. None of them is a target, and lesson 20 explains why making one a target breaks
it.

**Habit: the programme is measured by how fast findings close, not by how many are found.**

### The life of a finding

Every finding in that week went through the same states, whatever tool raised it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"sp-l01-life\" aria-label=\"The states a finding goes through. A check raises it; a person triages it into one of three outcomes: fixed, then verified by the same check passing; excepted until a date, with a reason, and raised again when the date passes; or a false positive, and the check is tuned so it stops raising it.\"><defs><marker id=\"sp-l01-life-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l01-life-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"115\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">raised</text><text x=\"85.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">by a check</text><rect x=\"200\" y=\"115\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">triaged</text><text x=\"285.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">by a person, written down</text><rect x=\"430\" y=\"20\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fixed</text><text x=\"495.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in the change</text><rect x=\"590\" y=\"20\" width=\"115\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"647.5\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">verified</text><text x=\"647.5\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the check passes</text><rect x=\"430\" y=\"115\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">excepted</text><text x=\"525.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">until a date, with a reason</text><rect x=\"430\" y=\"210\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">false positive</text><text x=\"525.0\" y=\"247.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the check is tuned</text><path d=\"M150 143 L198 143\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-life-ah-paper-dim)\"></path><path d=\"M370 130 L400 130 L400 48 L428 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-life-ah-paper-dim)\"></path><path d=\"M370 143 L428 143\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-life-ah-paper-dim)\"></path><path d=\"M370 156 L400 156 L400 238 L428 238\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-life-ah-paper-dim)\"></path><path d=\"M560 48 L588 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l01-life-ah-paper-dim)\"></path><path d=\"M620 143 L660 143 L660 100 L85 100 L85 113\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l01-life-ah-amber)\"></path><text x=\"560\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">the date passes</text></svg>", "caption": "Three ways out of triage, and one of them comes back on its own."}
```

The state that matters most is the one in the middle. **Triage is a decision by a person, written
down**: the finding is real and gets fixed, or it is real and is excepted until a date with a
reason, or it is not real and the check is tuned so it stops saying so. A finding that sits in no
state at all, raised and never answered, is how a pipeline teaches a team to ignore it.

### Who does what

| role | what changes in their week |
|---|---|
| developer | fixes what the pipeline finds in their own change, before merge; runs the fast checks locally |
| security champion | one per team, part-time: triages what is not obvious, keeps exceptions honest, raises what needs the security team |
| security engineer | chooses and tunes the checks, writes the custom rules, decides the hard cases, measures the programme |
| on-call | handles the findings that arrive from outside the pipeline: a new advisory for something already running |

None of these roles is new. What is new is that **the pipeline is where they meet**, and the
pipeline's code is where their agreements are written.
