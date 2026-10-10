---
title: When will these items be done?
version: 1
---

The second question fixes the scope and asks for the date: **"we have thirty items left for the new invoicing screen; when will they be done?"** **Save the program below as `when.py`.**

```schooling-example
{
  "language": "python",
  "file": "when.py",
  "parts": [
    {
      "code": "\"\"\"when.py: when will a number of items be done? A Monte Carlo forecast.\"\"\"\nimport csv\nimport random\nimport sys\nfrom datetime import date, timedelta\n\nSTART = date(2026, 10, 1)\nitems_left = int(sys.argv[1])\nfirst, last = (date.fromisoformat(d) for d in (sys.argv[2:] or [\"2026-08-17\", \"2026-09-30\"]))\nRUNS = 10000\nrng = random.Random(2026)\n\n",
      "note": "**The same inputs as `howmany.py`**, except that the question is now a number of items, and the forecast starts on 1 October."
    },
    {
      "code": "merged = [date.fromisoformat(i[\"merged\"][:10]) for i in csv.DictReader(open(\"items.csv\")) if i[\"merged\"]]\nhistory = []\nday = first\nwhile day <= last:\n    history.append(sum(1 for m in merged if m == day))\n    day += timedelta(days=1)\n",
      "note": "**The same history**: one daily throughput per calendar day of the window."
    },
    {
      "code": "\n\ndef one_run():\n    done, days = 0, 0\n    while done < items_left:\n        done += rng.choice(history)\n        days += 1\n    return days\n",
      "note": "**One simulated future**: draw a day from the history, add its throughput, and keep going until the items are done. The number of days it took is the result."
    },
    {
      "code": "\n\nresults = sorted(one_run() for _ in range(RUNS))\nprint(f\"{items_left} items from {START}; {RUNS} runs\")\nfor p in (50, 70, 85, 95):\n    finish = START + timedelta(days=results[int(p / 100 * RUNS) - 1] - 1)\n    print(f\"{p}% of runs finished by {finish:%a %d %b}\")\n",
      "note": "**Read from the top down this time.** For \"when?\", the cautious answer is a date that most futures had *already reached*, so the 85% line counts from the early end. A finish on a Saturday or Sunday means the Friday before, since weekends finish nothing."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 when.py 30
30 items from 2026-10-01; 10000 runs
50% of runs finished by Tue 27 Oct
70% of runs finished by Thu 29 Oct
85% of runs finished by Sun 01 Nov
95% of runs finished by Wed 04 Nov
```

## Reading it

Here the percentiles count from the **early** end: 85% of the futures had finished all thirty items by 1 November. Since that is a Sunday, and weekends in the history finish nothing, the runs that end on it finished on Friday 30 October. So the sentence for the stakeholder is: **"85% likely by the end of October, almost certainly by the first week of November, and about even odds by the 27th."**

Notice how narrow it is: the median and the 95th percentile are only eight days apart. That is what thirty items averaged over many days does. The question is less uncertain than "how long will one item take?", where the spread was from one day to seventeen.

## Twice the work is not twice the uncertainty

```
ana@laptop:~/delivery$ python3 when.py 60
60 items from 2026-10-01; 10000 runs
50% of runs finished by Sun 22 Nov
70% of runs finished by Thu 26 Nov
85% of runs finished by Sun 29 Nov
95% of runs finished by Fri 04 Dec
```

Sixty items take about twice as long, a median of 22 November against 27 October. But the gap between the median and the 95th percentile grew only from eight days to twelve. Over more days, good and bad days have more chance to even out, so **the uncertainty grows more slowly than the work**. That is one reason long forecasts from history are more useful than people expect, provided the history still describes the team, which the next section tests.

## What the date does not include

This forecast assumes the thirty items stay thirty. Real work grows as it is done: an item turns out to be two, a bug is found, a stakeholder adds something. Lesson 11 adds that growth to the simulation, and it moves the date more than any of the uncertainty above.
