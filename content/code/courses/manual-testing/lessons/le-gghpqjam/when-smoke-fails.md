---
title: When smoke fails
version: 1
---

A failed smoke run tempts two opposite mistakes: pressing on with whatever parts seem to work, or
writing a defect report for every line that says `FAIL`. **A failed smoke run is one finding about
the build, and the plan already says what happens next**: testing stops in what it touches, the
developer hears about it at once, and nothing resumes until a new build passes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" data-fig=\"l08-smoke-gate\" aria-label=\"A flow. A new build goes to smoke, five checks taking a minute. If all pass, the application is restarted and the planned testing starts: cases, sanity, regression. If any check fails, the first question is whether the cause is your lab or the build. If it is the lab, fix it and run smoke again. If it is the build, suspend testing and tell the developer once, then wait for the next build, which goes to smoke again.\"><defs><marker id=\"mt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"mt-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"140.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a new build</text><rect x=\"220.0\" y=\"26.0\" width=\"170.0\" height=\"54.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"45.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">smoke</text><text x=\"305.0\" y=\"60.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">five checks, a minute</text><rect x=\"450.0\" y=\"26.0\" width=\"230.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"45.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">restart, then the planned testing</text><text x=\"565.0\" y=\"60.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cases, sanity, regression</text><path d=\"M162.0 53.0 L216.0 53.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M392.0 53.0 L446.0 53.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-phosphor)\"></path><text x=\"419.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">all pass</text><rect x=\"220.0\" y=\"130.0\" width=\"170.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">your lab, or the build?</text><path d=\"M305.0 82.0 L305.0 126.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"298.0\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">any fails</text><rect x=\"450.0\" y=\"126.0\" width=\"230.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"143.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">your lab: fix it</text><text x=\"565.0\" y=\"158.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">and run smoke again</text><path d=\"M392.0 151.0 L446.0 151.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><text x=\"419.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the lab</text><path d=\"M565 124 L565 104 L360 104 L360 84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"220.0\" y=\"226.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"243.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">suspend, and tell</text><text x=\"305.0\" y=\"258.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the developer once</text><path d=\"M305.0 174.0 L305.0 222.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"312.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the build</text><rect x=\"20.0\" y=\"230.0\" width=\"140.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">wait for the next build</text><path d=\"M218.0 251.0 L164.0 251.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M90.0 228.0 L90.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path></svg>", "caption": "Smoke as a gate. Nothing after it starts on a build that has not passed it, and a new build goes through it from the beginning."}
```

## Five lines, one cause

Rui says a new build is ready; Ana starts it and runs the smoke list. To see what she saw, stop
boxoffice with Ctrl-C in its terminal and run the script again:

```
ana@laptop:~/boxoffice$ sh smoke.sh; echo $?
FAIL  the server answers
FAIL  the home page lists three shows
FAIL  the sign-up page loads
FAIL  one booking goes through
FAIL  the outbox opens
5 of 5 checks failed
1
```

Five failures and a status of 1. They are not five defects. When every check fails, including the
first, the likeliest explanation is that nothing is answering at all, and one request says so:

```
ana@laptop:~/boxoffice$ curl http://127.0.0.1:8000/health
curl: (7) Failed to connect to 127.0.0.1 port 8000 after 0 ms: Couldn't connect to server
```

Nothing is listening on port 8000. That is the first check failing, and the other four failing
because of it.

## First, rule out your own lab

Before telling anybody the build is broken, Ana makes sure it is the build. `Couldn't connect to
server` is one of the failures lesson 1 section 05 covers: the server was never started, it was
stopped, or it stopped with an error. The terminal where boxoffice runs answers which. If its last
line is Ana's own Ctrl-C, or the program was started in another directory, the problem is the lab,
and the fix is hers; in your own run above it was exactly that, the Ctrl-C you pressed. In Ana's
case the build was started properly and its terminal shows it ending with a traceback, so **the
build does not start**, and that is news for Rui.

The same habit applies to a single failure. A booking check that fails while the other four pass
is worth one rerun and one look in the browser before it is reported: if the check books a show
whose booking has closed, the check is wrong, and if it passes on the second run with nothing
changed, that is a finding of its own, a build that fails sometimes.

## Then, the plan

Lesson 1's plan names the suspension criterion for boxoffice: **the build does not start, or a
quarter of one area's cases fail**. A build that does not start meets the first half, so testing
stops on the whole of it. A build where only the booking check fails meets the spirit of the second:
booking is the area most of the cases run through, the discount cases of risk A and the order cases
of risk C among them, so those areas stop. Sign-up cases that never book anything can carry on, and
the plan is where that judgement gets written down rather than made fresh on a stressful morning.

Suspension is not idleness. Ana goes back to the work that does not need a build: writing the cases
for the next feature, reviewing requirements as lesson 6 did, preparing data.

## Then, tell Rui once

One message, sent at once, with what Rui needs to act and nothing he has to ask about:

- which build: the version and where it came from, since `/health` cannot say when it is down;
- the smoke output, pasted as it printed, five lines and the count;
- what Ana checked on her side, here that the server was started from the new file in
  `~/boxoffice` and stopped with the traceback in its terminal, which she pastes too;
- what is suspended, and that testing resumes on the next build that passes smoke.

That is one report about one problem. Lesson 15 is about writing defect reports in general, and the
same rule holds there: one cause, one report, however many checks it knocked over.

## And when the next build arrives

**Resumption has a criterion too**, the other half of suspension: a new build that passes the whole
smoke list. Ana restarts boxoffice from the new file, runs the list, sees five passes and a status
of 0, and restarts once more to clear the order the smoke check left behind. Then the testing that
stopped picks up where it was, starting with the cases that were blocked.

What she does not do is patch the build herself to get past the failure, or restart it until a run
happens to pass. Both produce a build that is not the one Rui sent, and every result after that is a
result about something nobody shipped.
