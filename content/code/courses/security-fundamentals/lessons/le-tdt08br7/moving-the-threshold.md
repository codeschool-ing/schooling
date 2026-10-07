---
title: Moving the threshold
version: 1
---

The obvious fix for the slow guesser is a lower threshold. Three failures in ten minutes instead of
five:

```
ana@laptop:~$ python3 detect.py 3
threshold 3: 21 alerts
  TP   9   FP  12
  FN   2   TN  75
precision 43%   recall 82%
```

Recall jumps from 27% to **82%**: nine of the eleven exercise cases are caught now, and only the slow
guesser's two windows of two failures slip under. Precision rises too, to 43%, because the true
positives grew faster than the false ones. But look at the false positives themselves: **from seven
to twelve.** The backup job is still there, and now the five staff windows with three or four typing
mistakes alert as well. The number of alerts a person has to look at in a week doubled, from ten to
twenty-one.

That is the trade every detection makes. **Lowering a threshold catches more, and alerts on more of
the harmless.** Raising it does the opposite. No threshold on this rule catches the slow guesser and
leaves the staff alone, because three failures from an attacker and three failures from a person
with cold fingers look the same in this log.

```schooling-figure
{"svg": "<svg id=\"sf-threshold\" viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The shop's week as cases by number of failures in ten minutes. Harmless cases, above the line: 60 with one failure, 15 with two, 4 with three, 1 with four, 7 with six (the backup job). Exercise cases, below the line: 2 with two failures, 6 with three, 3 with eight. A threshold of 5 alerts on everything from five up: the backup job and the fast guesser. A threshold of 3 also catches the slow guesser and five harmless staff windows.\"><text x=\"20\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">harmless</text><text x=\"20\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">exercise</text><text x=\"155.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"134\" y=\"48.0\" width=\"42\" height=\"102.0\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"155.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">60</text><text x=\"225.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"204\" y=\"124.5\" width=\"42\" height=\"25.5\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"116.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15</text><rect x=\"204\" y=\"170\" width=\"42\" height=\"18\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><text x=\"295.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"274\" y=\"143.2\" width=\"42\" height=\"6.8\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"295.0\" y=\"135.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"274\" y=\"170\" width=\"42\" height=\"54\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"295.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><text x=\"365.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><rect x=\"344\" y=\"148.3\" width=\"42\" height=\"1.7\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"365.0\" y=\"140.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><text x=\"435.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"505.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><rect x=\"484\" y=\"138.1\" width=\"42\" height=\"11.9\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"505.0\" y=\"130.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><text x=\"575.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">7</text><text x=\"645.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><rect x=\"624\" y=\"170\" width=\"42\" height=\"27\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"645.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><text x=\"400\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">failures in ten minutes</text><path d=\"M260 14 L260 270\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path><text x=\"266\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">threshold 3</text><path d=\"M400 14 L400 270\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path><text x=\"406\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">threshold 5</text></svg>", "caption": "Everything right of the line raises an alert. Moving the line left catches more of both."}
```

### Fixing the cause, not hiding the symptom

Seven of the false positives have one cause: an account whose password expired. The detector can
be told to ignore that account:

```
ana@laptop:~$ python3 detect.py 3 svc-backup
threshold 3: 14 alerts
  TP   9   FP   5
  FN   2   TN  75
precision 64%   recall 82%
```

Precision climbs to 64% and recall is untouched, which looks like a free win. It is not free, and
the reason matters. **An exception by name is a hole by name.** Anyone who learns that failures for
`svc-backup` are never alerted on now has an account they can guess against in silence. Ignoring a
noisy source is a decision, and it belongs in the risk register with a date, like lesson 4's
compensating control.

The better fix is upstream: give the backup job a working credential, and its failures stop
happening at all. The detector then needs no exception, and the day the backup account fails six
times at two in the morning again, that is news worth an alert.

### Better than a threshold

A threshold on one count is the simplest rule there is. Real detections reach higher precision and
recall by adding information, much of it the signals of lesson 7: whether the failures are against
one account or many, whether the source has ever signed in successfully, whether a success follows
the failures (a forgetful person) or never does (a guesser). Each extra signal separates two cases
the count alone could not. `soc-response` lessons 6 and 7 work on exactly this.
