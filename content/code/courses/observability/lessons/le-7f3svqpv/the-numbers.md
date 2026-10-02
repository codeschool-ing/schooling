---
title: MTTD, MTTA, MTTR, and what averages hide
version: 1
---

Teams measure their response with a family of intervals, each the time between two moments of an
incident. Lesson 17's timeline has all the moments, so its incident can be measured exactly:

| interval | from | to | lesson 17 |
|---|---|---|---|
| time to detect | the failure starts | an alert fires | 3 min 9 s |
| time to acknowledge | the alert fires | a person says *I have it* | 2 s, the declaration standing in for an acknowledgement |
| time to mitigate | the failure starts | users stop being hurt | 4 min 12 s, the rollback |
| time to resolve | the failure starts | the incident is closed | 9 min 6 s |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Lesson 17's incident on a time axis, in seconds from the release. Release at 0, page at 189, incident declared at 191, rollback at 252, page resolved at 309, incident closed at 546. Below the axis, four brackets: time to detect from 0 to 189, time to acknowledge from 189 to 191, time to mitigate from 0 to 252, time to resolve from 0 to 546.\"><defs><marker id=\"iv-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M170 90 L690 90\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#iv-ah)\"></path><path d=\"M170.0 82 L170.0 98\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"170.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">release</text><text x=\"170.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><path d=\"M350.0 82 L350.0 98\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"350.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">page</text><text x=\"350.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">189 s</text><path d=\"M351.9047619047619 82 L351.9047619047619 98\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"351.9047619047619\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">declared</text><text x=\"351.9047619047619\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">191 s</text><path d=\"M410.0 82 L410.0 98\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"410.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">rollback</text><text x=\"410.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">252 s</text><path d=\"M464.2857142857143 82 L464.2857142857143 98\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"464.2857142857143\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">page resolved</text><text x=\"464.2857142857143\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">309 s</text><path d=\"M690.0 82 L690.0 98\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"690.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">closed</text><text x=\"690.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">546 s</text><rect x=\"170.0\" y=\"145\" width=\"180.0\" height=\"14\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"158\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time to detect</text><rect x=\"350.0\" y=\"179\" width=\"4\" height=\"14\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"158\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time to acknowledge</text><rect x=\"170.0\" y=\"213\" width=\"240.0\" height=\"14\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"158\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time to mitigate</text><rect x=\"170.0\" y=\"247\" width=\"520.0\" height=\"14\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"158\" y=\"254\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time to resolve</text></svg>", "caption": "The four intervals of one incident. Detection was most of the time to mitigate, and the window that filled before the page is what set it."}
```

The *M* in **MTTD** or **MTTR** is *mean*: the average of one interval over many incidents. MTTR is
the one quoted most, and it is also used for four different things (restore, repair, respond, resolve),
so **a report should say which interval it means** before anybody compares two numbers.

Each interval points at a different fix:

- **Detection** is the alerts. Lesson 17's was mostly the five-minute window of the burn-rate rule
  filling up, which is the price of not paging on blips.
- **Acknowledgement** is the rota and the escalation policy.
- **Mitigation** is the runbook and the tools: here, a deploy annotation that answered *what changed?*
  and a rollback that took one command.

**The mean misleads, for the same reason lesson 7 gave for latency.** Incident durations are skewed: most
are short, and a few last a whole night. A team with nine twenty-minute incidents and one of nine hours
has a mean of about an hour and a quarter, which describes none of them. The median and the longest
incident of the quarter say more, and the list of incidents itself says most.

And a falling MTTR is not always good news. It falls when a team gets faster, and it also falls when
it starts declaring small incidents it used to ignore, which is a good change that looks like the
same improvement. **The numbers start a conversation in the review; they do not end it.**
