---
title: The work grows while you do it
version: 1
---

Lesson 10's forecast for thirty items assumed there would always be thirty. There never are. As work is done, it is found to be bigger than it looked: an item splits in two, a review finds a case nobody had thought of, testing finds a bug, a stakeholder sees the first screen and asks for one more thing. **Scope growth is not a failure of planning; it is how knowledge work reveals itself**, and a forecast that ignores it is wrong in a known direction.

**Save the program below as `growth.py`.** It is `when.py` with one addition: every item finished may bring new work with it, at a rate you choose as a range.

```schooling-example
{
  "language": "python",
  "file": "growth.py",
  "parts": [
    {
      "code": "\"\"\"growth.py: when will the work be done, if the work keeps growing as it is done?\"\"\"\nimport csv\nimport random\nimport sys\nfrom datetime import date, timedelta\n\nSTART = date(2026, 10, 1)\nitems_left = int(sys.argv[1])\nlow, high = float(sys.argv[2]), float(sys.argv[3])     # new items found per item finished\nRUNS = 10000\nrng = random.Random(2026)\n\n",
      "note": "**One input more than `when.py`**: a range for how much new work turns up per item finished. `0.1 0.4` means every finished item brings between a tenth and four tenths of a new one, depending on the future."
    },
    {
      "code": "merged = [date.fromisoformat(i[\"merged\"][:10]) for i in csv.DictReader(open(\"items.csv\")) if i[\"merged\"]]\nhistory = []\nday = date(2026, 8, 17)\nwhile day <= date(2026, 9, 30):\n    history.append(sum(1 for m in merged if m == day))\n    day += timedelta(days=1)\n",
      "note": "**The same history as lesson 10**: one daily throughput per calendar day from 17 August to 30 September."
    },
    {
      "code": "\n\ndef one_run():\n    growth = rng.uniform(low, high)                    # this future's rate of discovery\n    left, days = items_left, 0\n    while left > 0:\n        done = min(left, rng.choice(history))\n        left -= done\n        left += sum(1 for _ in range(done) if rng.random() < growth)\n        days += 1\n    return days\n",
      "note": "**Each future gets its own rate of discovery**, drawn once from the range, because a project either turns out messy or it does not. Then, every simulated day, each item finished has that chance of adding a new item to the pile."
    },
    {
      "code": "\n\nresults = sorted(one_run() for _ in range(RUNS))\nprint(f\"{items_left} items, {low:.0%} to {high:.0%} more found per item finished; {RUNS} runs\")\nfor p in (50, 85, 95):\n    finish = START + timedelta(days=results[int(p / 100 * RUNS) - 1] - 1)\n    print(f\"{p}% of runs finished by {finish:%a %d %b}\")\n",
      "note": "**Read like `when.py`**: from the early end, a date most futures had reached."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 growth.py 30 0 0
30 items, 0% to 0% more found per item finished; 10000 runs
50% of runs finished by Tue 27 Oct
85% of runs finished by Sun 01 Nov
95% of runs finished by Wed 04 Nov
ana@laptop:~/delivery$ python3 growth.py 30 0.2 0.2
30 items, 20% to 20% more found per item finished; 10000 runs
50% of runs finished by Mon 02 Nov
85% of runs finished by Mon 09 Nov
95% of runs finished by Fri 13 Nov
ana@laptop:~/delivery$ python3 growth.py 30 0.1 0.4
30 items, 10% to 40% more found per item finished; 10000 runs
50% of runs finished by Thu 05 Nov
85% of runs finished by Sat 14 Nov
95% of runs finished by Fri 20 Nov
```

## Reading the three runs

**With no growth**, the program reproduces lesson 10's forecast: 85% by 1 November, meaning the end of October.

**With 20% growth**, every five items finished bring one more. The 85% date moves to **9 November**, more than a week later, as large as the whole spread lesson 10 found between its median and its 95th percentile. Scope growth moves the forecast more than the uncertainty in the team's pace does.

**With growth anywhere between 10% and 40%**, which is what a team that does not know its own growth rate should assume, the 85% date is **14 November**, and the range from median to 95th percentile widens from eight days to fifteen. Not knowing how much the work will grow is itself a source of uncertainty, and the simulation carries it honestly.

## Measuring your own growth rate

The range in the last run was a guess. A team can replace it with a measurement: for each piece of work it finished, **count the items it was planned as and the items it took**. A feature planned as twenty items that finished as twenty-six grew by 30%. Five or six past pieces of work give a range worth using, and the range is usually wider and higher than anybody expected.

The Billing team's files cannot measure this, because `billing.py` does not group items into features. A real board can, through epics, labels or parent items, and **it is the one number most worth adding to a team's records** if it forecasts work in batches larger than a few items.
