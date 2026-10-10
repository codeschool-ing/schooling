---
title: A budget for the page
version: 1
---

Lesson 10 measured two pages and read the numbers by eye. That works once. **A performance budget
is the same reading written down in advance**: a limit for each number that matters, agreed before
the next change is made, so that a report can be checked against it by a program rather than by
whoever happens to look. A budget turns "the page got slower" from an opinion into a line that
says `OVER`.

**The usual mistake is to budget the score.** A score of 0.9 is a blend of five metrics, so it can stay
put while one of them crosses its threshold, and nobody can say which change bought the drop.
Budget what the requirement names, and what a developer can act on:

| kind | examples | why it is in the budget |
|---|---|---|
| **timings** | LCP, CLS, TBT | they are the requirement, or its lab stand-in |
| **weight** | bytes of JavaScript, bytes of images, total bytes | they are what a change adds, visible in the diff that adds them |
| **counts** | requests | each one costs a round trip on a slow network |

The timings say whether the page is good enough. **The weights say why it stopped being good
enough**, and they move the moment somebody adds a library or a picture, long before anybody
measures a timing on a phone. They are also steadier: a page's image bytes are the same on every
run, while its LCP moves a little each time.

## Lighthouse 13 has no budget of its own

Older versions of Lighthouse took a budget file with a `--budget-path` flag. Before writing one,
check what the installed version offers:

```
ana@nft:~/boxoffice$ lighthouse --help | grep -ci budget
0
ana@nft:~/boxoffice$ lighthouse --list-all-audits | grep -ci budget
0
```

Neither the flags nor the list of audits mention a budget, so in 13.5.0 the check is yours to
write. It is a few lines, because the report already holds every number.

## The check

`perf/budget.py` keeps the budget and the check together. Make the directory with
`mkdir -p ~/boxoffice/perf`, then `nano perf/budget.py`:

```schooling-example
{"language": "python", "file": "boxoffice/perf/budget.py", "parts": [{"code": "# boxoffice/perf/budget.py\n# The page's performance budget, and the check that holds a page to it.\n# Give it several Lighthouse reports of the same page: every number is the\n# median of them. Exits 1 when anything is over budget.\nimport json, statistics, sys\n\nBUDGET = {                               # milliseconds, bytes or a count\n    \"largest-contentful-paint\": 2500,\n    \"cumulative-layout-shift\": 0.1,      # no unit\n    \"total-blocking-time\": 200,\n    \"script bytes\": 50_000,\n    \"image bytes\": 200_000,\n    \"total bytes\": 400_000,\n    \"total requests\": 15,\n}\n", "note": "The budget is a table at the top of the file, one line per number, and that is where a team argues about it: a change to a budget is a change to this file, reviewed like any other. The names are the ones the report uses, so the check needs no translation table."}, {"code": "def measured(report):\n    audits = report[\"audits\"]\n    seen = {}\n    for name in (\"largest-contentful-paint\", \"cumulative-layout-shift\",\n                 \"total-blocking-time\"):\n        seen[name] = audits[name][\"numericValue\"]\n    for row in audits[\"resource-summary\"][\"details\"][\"items\"]:\n        seen[row[\"resourceType\"] + \" bytes\"] = row[\"transferSize\"]\n        seen[row[\"resourceType\"] + \" requests\"] = row[\"requestCount\"]\n    return seen\n", "note": "`measured` reads one report. The three timings come from each audit's `numericValue`, in milliseconds (CLS has no unit). The bytes and the counts come from `resource-summary`, one row per kind of resource, the audit lesson 10 read with `jq`."}, {"code": "if len(sys.argv) < 2:\n    sys.exit(\"usage: python3 perf/budget.py REPORT.json [REPORT.json ...]\")\nruns = [measured(json.load(open(path))) for path in sys.argv[1:]]\n", "note": "Every argument is a report, and there has to be at least one. A check that is called with nothing to check says so and fails, instead of printing an empty table and passing."}, {"code": "over = 0\nfor name, limit in BUDGET.items():\n    value = statistics.median(run[name] for run in runs)\n    verdict = \"ok\" if value <= limit else \"OVER\"\n    over += verdict == \"OVER\"\n    shown = f\"{value:,.0f}\" if value >= 10 or value == int(value) else f\"{value:.3f}\"\n    print(f\"{name:26} {shown:>12} {limit:>10,}  {verdict}\")\nprint(f\"{len(runs)} runs, {over} over budget\")\nsys.exit(1 if over else 0)", "note": "For each line of the budget, the median across the reports, compared with its limit. The exit code is the verdict: 0 when everything fits, 1 when anything is over. That is the whole interface a pipeline needs."}]}
```

The limits are the Core Web Vitals' good thresholds for the timings, and for the weights a
number that leaves room for the fixed page and none for the slow one's picture. Your own numbers
would come from your own pages: what they weigh today, and what the requirement allows.

Run Lighthouse once on each page from lesson 10, then the check on each report. The server runs
in the first terminal, as before:

```
ana@nft:~/boxoffice$ lighthouse http://127.0.0.1:8000/ --quiet --only-categories=performance --output=json --chrome-flags="--headless=new --no-sandbox" --output-path=slow.json
ana@nft:~/boxoffice$ python3 perf/budget.py slow.json; echo "exit $?"
largest-contentful-paint         12,902      2,500  OVER
cumulative-layout-shift           0.139        0.1  OVER
total-blocking-time               1,474        200  OVER
script bytes                        405     50,000  ok
image bytes                   2,431,681    200,000  OVER
total bytes                   2,435,282    400,000  OVER
total requests                        4         15  ok
1 runs, 5 over budget
exit 1
```

```
ana@nft:~/boxoffice$ lighthouse http://127.0.0.1:8000/fast.html --quiet --only-categories=performance --output=json --chrome-flags="--headless=new --no-sandbox" --output-path=fast.json
ana@nft:~/boxoffice$ python3 perf/budget.py fast.json; echo "exit $?"
largest-contentful-paint            915      2,500  ok
cumulative-layout-shift               0        0.1  ok
total-blocking-time                   0        200  ok
script bytes                          0     50,000  ok
image bytes                      20,563    200,000  ok
total bytes                      23,467    400,000  ok
total requests                        3         15  ok
1 runs, 0 over budget
exit 0
```

**Five lines over on the slow page and none on the fixed one, and the exit code says the same
thing**: 1 and 0. The slow page's `total requests`, 4 against 15, is within budget, which is a
reminder that a budget only catches what it names. One report per page is enough to show the
check working; the next sections say why a gate needs more than one.
