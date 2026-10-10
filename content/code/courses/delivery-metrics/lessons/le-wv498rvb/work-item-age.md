---
title: Work item age, the number that is not late
version: 1
---

Cycle time has one weakness no amount of care can fix: **it is only known once an item is finished**. An item that has been stuck for six weeks contributes nothing to any cycle time until the day it is finally done, and on that day it arrives on the scatterplot as a surprise that everybody could have seen coming.

**Work item age** is the measurement that is not late. It is the number of days since an open item was started, it is known for every item every morning, and it grows by one a day until the item finishes. On the day an item finishes, its age becomes its cycle time. So age is cycle time **while it is still happening**, and that makes the two directly comparable: an open item whose age has passed the 85th percentile of recent cycle times is already slower than 85% of what the team finished lately, whatever happens next.

**Save the program below as `age.py`.** It takes a date, stands on the board as it was that evening, and lists every open item with its age.

```schooling-example
{
  "language": "python",
  "file": "age.py",
  "parts": [
    {
      "code": "\"\"\"age.py: how old the open items are, against how long finished ones took.\"\"\"\nimport csv\nimport math\nimport sys\nfrom datetime import date, timedelta\n\ntoday = date.fromisoformat(sys.argv[1])\nitems = list(csv.DictReader(open(\"items.csv\")))\n\n\ndef when(text):\n    return date.fromisoformat(text[:10]) if text else None\n\n\ndef percentile(values, p):\n    ordered = sorted(values)\n    return ordered[math.ceil(p / 100 * len(ordered)) - 1]\n",
      "note": "**\"Today\" comes from the command line**, so you can stand on the board on any day of the history and see it as the team saw it then. The two helpers are the ones from lessons 1 and 2."
    },
    {
      "code": "\n\nrecent = [(when(i[\"merged\"]) - when(i[\"started\"])).days for i in items\n          if i[\"merged\"] and today - timedelta(days=30) < when(i[\"merged\"]) <= today]\np50, p85 = percentile(recent, 50), percentile(recent, 85)\nprint(f\"finished in the last 30 days: {len(recent)}, median {p50} days, 85th {p85} days\")\nprint(\"  item     column       age\")\n",
      "note": "**The yardstick is recent history**: the cycle times of items finished in the 30 days before today. An open item's age is compared with how long finished items actually took, not with an estimate."
    },
    {
      "code": "\nfor i in items:\n    started, review, merged = when(i[\"started\"]), when(i[\"review\"]), when(i[\"merged\"])\n    if not started or started > today or (merged and merged <= today):\n        continue\n",
      "note": "**Only items open on that day**: started on or before it, and not merged by then."
    },
    {
      "code": "    column = \"review\" if review and review <= today else \"development\"\n    age = (today - started).days\n    flag = \"past the 85th\" if age > p85 else \"past the median\" if age > p50 else \"\"\n    print(f\"  {i['id']}  {column:12} {age:3}  {flag}\".rstrip())\n",
      "note": "**Age is days since the item started**, and it keeps growing until the item finishes. The flag says which part of recent history the item has already outlived."
    }
  ]
}
```

## The board on 30 September

```
ana@laptop:~/delivery$ python3 age.py 2026-09-30
finished in the last 30 days: 30, median 4 days, 85th 8 days
  item     column       age
  BIL-189  development   40  past the 85th
  BIL-219  review         7  past the median
  BIL-226  development    0
  BIL-227  development    0
  BIL-228  development    0
  BIL-229  review         0
```

Six items are open, and one of them is five times older than the 85th percentile. **`BIL-189` is a one-point bug that has been open for forty days.** It is the item lesson 1 found by arithmetic, when September's work in progress came out one higher than the finished items explained, and that lesson 2's scatterplot could not show at all because it has no dot. Here it is the first line of the output.

What happened to it is ordinary. On 21 August its developer started it, found that it needed a change from another team, and marked it blocked. A blocked item, by the team's own reading of their new rule, did not count against the limit of one item per developer, so the developer started something else. Every standup since then has asked each person what they are working on, and the honest answer has never included `BIL-189`.

## The same board on 15 July

```
ana@laptop:~/delivery$ python3 age.py 2026-07-15
finished in the last 30 days: 26, median 17 days, 85th 31 days
  item     column       age
  BIL-121  review        35  past the 85th
  BIL-123  review        34  past the 85th
  BIL-130  review        27  past the median
  BIL-134  review        22  past the median
  BIL-136  review        20  past the median
  BIL-137  review        19  past the median
  BIL-138  development   16
  BIL-141  development   15
  BIL-142  review        14
  BIL-143  review        13
  BIL-144  review        12
  BIL-145  review        12
  BIL-146  review         9
  BIL-147  development    8
  BIL-148  development    8
  BIL-149  development    8
  BIL-150  development    7
  BIL-151  development    6
  BIL-152  development    6
  BIL-153  development    6
  BIL-154  development    5
  BIL-155  development    5
  BIL-156  development    1
  BIL-157  development    0
  BIL-158  development    0
```

Twenty-five items open, and the yardstick itself is longer: a median of 17 days and an 85th percentile of 31, because the recent history it is measured against was slow too. Even against that generous yardstick, **every item past the median is in review**. The six oldest items on the board were all waiting for one person. Age points at the queue without anybody having to suspect it, which is the same finding lesson 2 reached from averages, available here on any single morning of July.

## Age against what?

An age means something only beside a yardstick, and the program uses the cycle times of items finished in the last 30 days. That choice matters in both directions. A yardstick taken from the team's slow period makes everything look normal, as on 15 July, where a 31-day-old item was not yet flagged. A yardstick taken from a different team, or from an estimate, measures the item against a system it was never part of. **Use your own recent history, and say which window.** When the system changes, as the Billing team's did on 3 August, the yardstick takes a few weeks to catch up, and for those weeks the flags are generous.
