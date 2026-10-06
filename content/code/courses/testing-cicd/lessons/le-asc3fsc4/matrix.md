---
title: The matrix
version: 1
---

A **matrix** runs the same job once per combination of a few variables: versions of the language,
operating systems, databases, time zones. Each combination is a **cell**. The lab's matrix has two
axes, three Python versions and two time zones, so six cells. The reason to pay for six runs
instead of one is that **some bugs exist only in some cells**, and a single run on the author's
configuration cannot see them.

Lesson 3 section 09 pointed at the `WAREHOUSE` zone on line 11 of `dispatch.py`. Here a colleague
simplifies that function, reasoning that the shop and its server are both in São Paulo, so there is
no need to name a zone:

```
ana@laptop:~/shipquote$ git diff
diff --git a/shipquote/dispatch.py b/shipquote/dispatch.py
index 4c2649f..54c8b89 100644
--- a/shipquote/dispatch.py
+++ b/shipquote/dispatch.py
@@ -1,14 +1,11 @@
 """Which day an order leaves the warehouse."""
 from datetime import date, datetime, time, timedelta
-from zoneinfo import ZoneInfo
-
-WAREHOUSE = ZoneInfo("America/Sao_Paulo")
 CUTOFF = time(14, 0)          # orders after 14:00 leave the next working day
 
 
 def dispatch_date(ordered_at: float) -> date:
     """The day an order placed at this Unix time leaves the warehouse."""
-    local = datetime.fromtimestamp(ordered_at, WAREHOUSE)
+    local = datetime.fromtimestamp(ordered_at)
     day = local.date()
     if local.time() >= CUTOFF:
         day += timedelta(days=1)
ana@laptop:~/shipquote$ python -m pytest -q tests/test_dispatch.py
...                                                                      [100%]
3 passed in 0.14s
ana@laptop:~/shipquote$ git push
remote: ci: run 4, commit 1247039, checked out clean        
remote: ci: 3.11  America/Sao_Paulo  pass  41 passed, 2 skipped in 1.92s        
remote: ci: 3.11  UTC                FAIL  1 failed, 40 passed, 2 skipped in 1.39s        
remote: ci: 3.12  America/Sao_Paulo  pass  41 passed, 2 skipped in 1.89s        
remote: ci: 3.12  UTC                FAIL  1 failed, 40 passed, 2 skipped in 1.39s        
remote: ci: 3.13  America/Sao_Paulo  pass  41 passed, 2 skipped in 1.97s        
remote: ci: 3.13  UTC                FAIL  1 failed, 40 passed, 2 skipped in 1.43s        
remote: ci: run 4 FAILED, logs in /home/ana/ci/runs/4        
To /home/ana/ci/shipquote.git
   6b77129..1247039  main -> main
```

On the laptop, all three dispatch tests pass: the laptop's clock is set to São Paulo. In the CI,
**the three São Paulo cells pass and the three UTC cells fail**, one test each. Without a zone,
`datetime.fromtimestamp` reads the time in whatever zone the machine is set to. The test's order
was placed at 13:30 in São Paulo, which is 16:30 in UTC: after the cut-off, so a machine in UTC
dispatches it the next day.

## Reading the shape

The pattern of red and green is a diagnosis before anybody opens a log. **The failure follows the
time zone and ignores the Python version**: every UTC cell failed, whatever the interpreter, and
every São Paulo cell passed. So the cause is something that depends on the zone, and the Python
upgrade the team was planning is not to blame.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Run 4 of the lab's CI as a grid of six cells: three Python versions, 3.11, 3.12 and 3.13, across two time zones. The three cells in America/Sao_Paulo passed with 41 tests passed. The three cells in UTC failed, each with one failed test. The failure follows the time zone and ignores the Python version.\"><text x=\"320.0\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">Python 3.11</text><text x=\"460.0\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">Python 3.12</text><text x=\"600.0\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">Python 3.13</text><text x=\"234\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">America/Sao_Paulo</text><rect x=\"258\" y=\"66\" width=\"124\" height=\"48\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"320.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">pass</text><text x=\"320.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">41 passed</text><rect x=\"398\" y=\"66\" width=\"124\" height=\"48\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"460.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">pass</text><text x=\"460.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">41 passed</text><rect x=\"538\" y=\"66\" width=\"124\" height=\"48\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"600.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">pass</text><text x=\"600.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">41 passed</text><text x=\"234\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">UTC</text><rect x=\"258\" y=\"126\" width=\"124\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"320.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">fail</text><text x=\"320.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1 failed</text><rect x=\"398\" y=\"126\" width=\"124\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"460.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">fail</text><text x=\"460.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1 failed</text><rect x=\"538\" y=\"126\" width=\"124\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"600.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">fail</text><text x=\"600.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1 failed</text><path d=\"M250 196 L670 196\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"460.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the failure follows the row, not the column</text></svg>", "caption": "Run 4, drawn as its matrix. Red along a whole row, and the same picture in every column, says the cause is the time zone before anybody opens a log."}
```

The axes a matrix should have are the ones **production can differ on from the developer's
machine**. Most servers and almost every hosted CI runner run in UTC, while a team in Brazil
develops in São Paulo time, so this axis earns its place in a Brazilian project. Common others:

| axis | catches |
|---|---|
| language versions the project supports | a feature used before the oldest version has it |
| operating systems | path separators, line endings, case-insensitive file systems |
| database versions | SQL accepted by one and refused by another |
| time zone and locale | dates, formatting of numbers, sorting of accented words |

## The cost of a cell

Every axis multiplies: three Pythons, two zones and two databases would be twelve cells. Teams
keep matrices small by **testing the edges of each axis** rather than every value, the oldest and
newest Python they support rather than every version between, and by excluding combinations that
cannot happen in production. Lesson 6 writes this matrix as a GitHub Actions `strategy.matrix`,
with `include` and `exclude` for exactly that.
