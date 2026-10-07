---
title: Measuring whether the model is alive
version: 1
---

A model that checks itself produces numbers as a side effect, and a few of them say whether the
practice is working. The temptation is to measure what is easy to count. The discipline is to
measure what would change if the model died.

### Five numbers worth keeping

Each of these comes from a file in the repository or from its git log, so none of them depends on
anybody remembering to count:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l15-measures\" aria-label=\"Five measures of the model on 12 October 2026. Open threats with no requirement and no decision: 0, after R20 and R21. Known exceptions in the baseline: 3, R14, R17 and R21 unverified. Current acceptances: 2, RA-001 and RA-003. Acceptances overdue: 0 on 12 October, and 1 on 16 December. Threats found from outside the model: 2, T18 and T19, from a SOC 2 report.\"><rect x=\"20.0\" y=\"15.0\" width=\"340.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"35.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">open threats: no requirement, no decision</text><rect x=\"370.0\" y=\"15.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"400.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">0</text><text x=\"442.0\" y=\"35.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">after R20 and R21</text><rect x=\"20.0\" y=\"65.0\" width=\"340.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">known exceptions in the baseline</text><rect x=\"370.0\" y=\"65.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"400.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"442.0\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R14, R17, R21 unverified</text><rect x=\"20.0\" y=\"115.0\" width=\"340.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">current acceptances</text><rect x=\"370.0\" y=\"115.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"400.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"442.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RA-001 and RA-003</text><rect x=\"20.0\" y=\"165.0\" width=\"340.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">acceptances overdue</text><rect x=\"370.0\" y=\"165.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"400.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">0</text><text x=\"442.0\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">on 12 October; 1 on 16 December</text><rect x=\"20.0\" y=\"215.0\" width=\"340.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"32.0\" y=\"235.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">threats found from outside the model</text><rect x=\"370.0\" y=\"215.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"400.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"442.0\" y=\"235.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">T18, T19, from a SOC 2 report</text></svg>", "caption": "Every number here comes from a file or a git log, and none of them needs anybody to remember to count."}
```

- **Open threats**, with no requirement and no decision. This is the check's own "new" count, and
  the healthy value is zero at every merge. A threat can be open for a day; one open for a month
  means nobody has made a decision that was theirs to make.
- **Known exceptions in the baseline**, and whether the number is going down. Three is fine. Three
  that are still the same three a year later means verification is not happening.
- **Current acceptances, and how many are overdue.** Lesson 12 called this one of the simplest
  measures there is. A growing count of acceptances means risks are being lived with rather than
  treated; overdue ones mean the reviews that justify living with them are not happening.
- **Threats found outside the model.** T18 and T19 came from a SOC 2 report; others will come from
  incidents, audits and tests. Each is one the model's own process missed, and the ratio of these
  to the ones the team found itself is the closest thing to a measure of the model's quality.
- **How long the model trails the system.** The time between a change that should have touched the
  model and the commit that did. With the design review in the same pull request, it is zero by
  construction. Without it, it is the number that grows first when a model starts dying.

The history shows the last one directly. Every change to the threats, the requirements and the
decisions, with its date:

```
(.venv) ana@vm:~/tm/portal-model$ git log --format="%ad %s" --date=short -- threats.csv requirements.csv decisions
2026-10-12 Write requirements for T18 and T19
2026-10-12 Add the threats the gateway SOC 2 report raised
2026-10-09 Review RA-002 late, and accept T06 again until December
2026-10-01 Record the first decisions
2026-09-17 Write a requirement for each threat
2026-09-14 Add the threats the abuse cases found
2026-09-03 List the threats found with STRIDE
```

Six weeks is too short to show a trend, and the honest thing to say about Vereda's numbers is that
they describe a practice that has just started. The point of choosing them now is that in a year
the same command will either show a model that changed whenever the system did, or a list that
stopped in October.

### Numbers that mislead

Two popular measures are worse than none:

- **The number of threats.** More threats is not a better model; a model of the same portal with
  sixty generic threats from a tool, and none of T13's kind, would score higher and protect less.
  Lesson 3 made this point about pytm's 196 findings.
- **The percentage of threats "mitigated".** It rewards writing a requirement and stops there. A
  requirement nobody verifies counts as mitigated, which is why the check counts verification
  separately and the baseline keeps unverified ones in view.

A measure that a team can improve by doing less real work will be improved that way, without anybody
deciding to cheat.

### Where this leaves the course

Fifteen lessons ago this repository was an empty directory. It now holds a diagram that runs, 19
threats with ids, 21 requirements with their verification, estimates in reais with their ranges, a
ranked plan, decision records with owners and dates, a mapping to three frameworks, an evidence
index, and a check that fails when any of it falls out of step. None of those files is the threat
model on its own. **The threat model is the habit of changing them whenever the system changes**,
and the check is there so that the habit does not depend on anybody's memory.
