---
title: Promises about data, and how to measure them
version: 1
---

**"Is the data up to date?" has no useful answer until somebody says how old is too old, how often,
and to whom it was promised.** Three terms carry that, borrowed from Google's *Site Reliability
Engineering* (2016), where they describe services; data teams use them for tables. The common
mistake is to treat them as one thing. They are three, and each one rests on the one before it.

- An **SLI**, a service level *indicator*, is a measurement: the age of the newest ride in the tables
  at 09:00.
- An **SLO**, a service level *objective*, is a target the team sets itself on that measurement: at
  most two hours old, on 95% of mornings.
- An **SLA**, a service level *agreement*, is a promise to somebody outside the team, with a
  consequence when it is broken. Roda Livre shares its ride data with the city's transport office,
  and the contract says the feed is at most four hours old at 09:00, with a discount on the monthly
  fee for each morning it is not.

The objective is deliberately tighter than the agreement. **An SLO breach is the team hearing about
trouble while the promise outside is still being kept**, which is time to fix it before anybody else
notices.

For data, two indicators cover most of what readers care about. **Freshness** is how old the newest
data is. **Completeness** is whether all of it arrived: yesterday's rides counted in the tables
against the count the source reports. Lesson 7 does that reconciliation. This section measures the
first.

## Measuring freshness

Every later lesson works in a directory of its own; this one is `~/roda/choose`:

```sh
mkdir -p ~/roda/choose
cd ~/roda/choose
```

Each feed at Roda Livre lands as a file, and a file's modification time says when it last landed.
The program below makes four such files with known times and then checks them as a monitoring job
would. Save it as `freshness.py`:

```schooling-example
{"language": "python", "file": "choose/freshness.py", "parts": [
{"code": "# choose/freshness.py\nimport os\nfrom datetime import datetime, timedelta\nfrom zoneinfo import ZoneInfo\n\nSP = ZoneInfo(\"America/Sao_Paulo\")\nNOW = datetime(2025, 10, 6, 9, 0, tzinfo=SP)\nSLO = timedelta(hours=2)\n", "note": "The objective, and the moment it is checked. A real check would ask for `datetime.now(SP)`; this one is fixed at 09:00 on Monday 6 October 2025, when Marta opens her report, so your output matches the one below."},
{"code": "\nLANDED = {\n    \"rides.csv\": datetime(2025, 10, 6, 8, 40, tzinfo=SP),\n    \"docks.csv\": datetime(2025, 10, 6, 7, 5, tzinfo=SP),\n    \"payments.csv\": datetime(2025, 10, 6, 6, 50, tzinfo=SP),\n    \"repairs.csv\": datetime(2025, 10, 3, 17, 30, tzinfo=SP),\n}\nos.makedirs(\"landing\", exist_ok=True)\nfor name, when in LANDED.items():\n    path = os.path.join(\"landing\", name)\n    open(path, \"w\").close()\n    os.utime(path, (when.timestamp(), when.timestamp()))\n", "note": "The stand-in for four feeds. Each file is empty; what matters is its modification time, which `os.utime` sets to the moment that feed last landed. The repairs sheet was last saved on Friday afternoon."},
{"code": "\nprint(f\"checked {NOW:%a %d/%m %H:%M}, objective: at most {SLO}\")\nfor name in sorted(os.listdir(\"landing\")):\n    mtime = os.path.getmtime(os.path.join(\"landing\", name))\n    landed = datetime.fromtimestamp(mtime, SP)\n    age = NOW - landed\n    status = \"ok\" if age <= SLO else \"BREACH\"\n    hours = age.total_seconds() / 3600\n    print(f\"  {name:13} landed {landed:%a %H:%M}  {hours:5.1f} h  {status}\")\n", "note": "The check itself, which knows nothing about the files except their names and times. The age is the indicator, measured; comparing it with two hours is the objective."}
]}
```

Run it, and look at the files it made:

```
ana@lab:~/roda/choose$ python freshness.py
checked Mon 06/10 09:00, objective: at most 2:00:00
  docks.csv     landed Mon 07:05    1.9 h  ok
  payments.csv  landed Mon 06:50    2.2 h  BREACH
  repairs.csv   landed Fri 17:30   63.5 h  BREACH
  rides.csv     landed Mon 08:40    0.3 h  ok
ana@lab:~/roda/choose$ ls -l --time-style=long-iso landing
total 0
-rw-r--r-- 1 ana ana 0 2025-10-06 07:05 docks.csv
-rw-r--r-- 1 ana ana 0 2025-10-06 06:50 payments.csv
-rw-r--r-- 1 ana ana 0 2025-10-03 17:30 repairs.csv
-rw-r--r-- 1 ana ana 0 2025-10-06 08:40 rides.csv
```

Two breaches, and they mean different things. **Payments is a real breach**: the export that
should land every hour last landed at 06:50, so at 09:00 its newest data was 2.2 hours old. Somebody
should look at the payments job now, before Marta's report shows a morning with no revenue.

**Repairs is a wrong objective.** The mechanics save their sheet on Friday afternoons, so on Monday
morning it is always about two and a half days old. A check that flags it every Monday is a check
that teaches the team to ignore it. The fix is not in the feed. Each feed needs its own objective,
set by what its readers need: two hours for rides, a week for repairs.

## From one morning to a month

One check says whether this morning was fine. The **indicator** that matters for an objective like
"95% of mornings" is a proportion over a period. This program simulates the rides export through
September: it lands at forty minutes past every hour, and on some mornings a run fails and the data
at 09:00 is older. Save it as `month.py`:

```python
# choose/month.py
import random
from datetime import date, timedelta

rng = random.Random(9)
OBJECTIVE = 0.95              # within the SLO on 95% of mornings

fresh, breaches = 0, []
for n in range(30):
    day = date(2025, 9, 1) + timedelta(days=n)
    failed = 0                # hourly exports that failed before 09:00
    if rng.random() < 0.15:
        failed = rng.randint(1, 4)
    age = 20 + 60 * failed    # minutes since the last export landed
    if age <= 120:
        fresh += 1
    else:
        breaches.append(f"{day:%d/%m} ({age // 60}h{age % 60:02d})")

sli = fresh / 30
print(f"SLI: {fresh} of 30 mornings fresh = {sli:.1%}")
print(f"objective {OBJECTIVE:.0%}:", "met" if sli >= OBJECTIVE else "MISSED")
print("breaches:", ", ".join(breaches) or "none")
```

Run it:

```
ana@lab:~/roda/choose$ python month.py
SLI: 28 of 30 mornings fresh = 93.3%
objective 95%: MISSED
breaches: 16/09 (2h20), 23/09 (3h20)
```

Twenty-eight good mornings out of thirty is 93.3%, and the objective is missed. That looks harsh for
two bad mornings, and it is the arithmetic of the target: 95% of thirty mornings allows one and a
half, so in practice **a 95% objective over a month tolerates one bad morning**. Whether that is the
right number is a conversation with Marta, and the program makes it a conversation about a fact.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A bar chart of the age of the rides data at 09:00 on each of the thirty mornings of September 2025. Twenty-seven bars sit at twenty minutes and one, on 3 September, at an hour and twenty, still inside the objective. On 16 September the age is 2 hours 20 minutes and on 23 September 3 hours 20 minutes, both above the two-hour objective line and below the four-hour agreement line.\" data-fig=\"month\"><defs><marker id=\"month-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"70\" y1=\"250\" x2=\"670\" y2=\"250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"70\" y1=\"250\" x2=\"70\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"62\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 h</text><text x=\"62\" y=\"203.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1 h</text><text x=\"62\" y=\"156.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2 h</text><text x=\"62\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3 h</text><text x=\"62\" y=\"63.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4 h</text><text x=\"62\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">age at 09:00</text><rect x=\"73.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"93.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"113.0\" y=\"187.8\" width=\"14.0\" height=\"62.2\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"133.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"153.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"173.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"193.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"213.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"233.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"253.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"273.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"293.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"313.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"333.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"353.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"373.0\" y=\"141.1\" width=\"14.0\" height=\"108.9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"393.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"413.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"433.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"453.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"473.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"493.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"513.0\" y=\"94.4\" width=\"14.0\" height=\"155.6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"533.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"553.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"573.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"593.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"613.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"633.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"653.0\" y=\"234.4\" width=\"14.0\" height=\"15.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"80.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">01/09</text><text x=\"220.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">08/09</text><text x=\"360.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15/09</text><text x=\"500.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">22/09</text><text x=\"640.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">29/09</text><line x1=\"70\" y1=\"156.7\" x2=\"670\" y2=\"156.7\" stroke=\"var(--phosphor)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></line><line x1=\"70\" y1=\"63.3\" x2=\"670\" y2=\"63.3\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></line><text x=\"78\" y=\"146.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">objective (SLO): at most 2 h</text><text x=\"78\" y=\"53.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">agreement with the city (SLA): at most 4 h</text><text x=\"380.0\" y=\"132.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2h20</text><text x=\"520.0\" y=\"85.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3h20</text></svg>", "caption": "Thirty mornings of September 2025. Two crossed the objective the team set itself, and neither reached the agreement with the city."}
```

The figure shows why there are two lines. On 3 September one export failed and the data was
an hour and twenty minutes old: a failure, and still a fresh morning. Both breaches crossed the objective and stayed inside
the agreement: on 23 September the data was 3 hours 20 minutes old, which is a bad morning for the
team and still a kept promise to the city. The allowance an objective leaves, and what a team does
when it is spent, is called an error budget; `observability` takes that further.
