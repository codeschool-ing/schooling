---
title: The spread, not the average
version: 1
---

"Our cycle time is nine days" sounds like an answer. It hides the only part of the answer anybody planning around it needs: **how often an item takes much longer than nine days**. Cycle times are not spread evenly around their average. Most items finish fairly quickly, a few take far longer, and nothing can take less than zero, so the distribution leans to the right with a long tail. In that shape the average is pulled towards the tail and describes no particular item.

**Save the program below as `cycle.py`** in your `delivery` folder.

```schooling-example
{
  "language": "python",
  "file": "cycle.py",
  "parts": [
    {
      "code": "\"\"\"cycle.py: how long the Billing team's items took, as a distribution.\"\"\"\nimport csv\nimport math\nimport sys\nfrom datetime import date\n\nfirst, last = date.fromisoformat(sys.argv[1]), date.fromisoformat(sys.argv[2])\n\n\ndef when(text):\n    return date.fromisoformat(text[:10]) if text else None\n",
      "note": "**The same start as `littles.py`**: a period from the command line, and the helper that turns a column into a date."
    },
    {
      "code": "\n\ndef percentile(values, p):\n    \"\"\"The smallest value with at least p% of the values at or below it.\"\"\"\n    ordered = sorted(values)\n    return ordered[math.ceil(p / 100 * len(ordered)) - 1]\n",
      "note": "**A percentile by nearest rank.** Sort the values and take the one at position p% of the way up, rounding up. It is always a value that really happened, which is what makes it easy to say out loud: *85% of items finished in this many days or fewer*."
    },
    {
      "code": "\n\ndays = [(when(i[\"merged\"]) - when(i[\"started\"])).days\n        for i in csv.DictReader(open(\"items.csv\"))\n        if i[\"merged\"] and first <= when(i[\"merged\"]) <= last]\n",
      "note": "**One cycle time per item merged in the period**, in calendar days from `started` to `merged`."
    },
    {
      "code": "\nprint(f\"{len(days)} items, cycle time in days\")\nprint(f\"  mean {sum(days) / len(days):.1f}   median {percentile(days, 50)}\"\n      f\"   85th {percentile(days, 85)}   95th {percentile(days, 95)}   max {max(days)}\")\n",
      "note": "**Five summaries on one line**: the mean, then the 50th, 85th and 95th percentiles, then the longest."
    },
    {
      "code": "\nfor low in range(0, max(days) + 1, 5):\n    count = sum(1 for d in days if low <= d < low + 5)\n    print(f\"  {low:2}-{low + 4:<2} {'#' * count}\")\n",
      "note": "**A histogram in text**: one row per five days, one `#` per item. It is crude, and it shows the shape no single number can."
    }
  ]
}
```

## Before the change

```
ana@laptop:~/delivery$ python3 cycle.py 2026-06-01 2026-07-31
52 items, cycle time in days
  mean 19.1   median 18   85th 29   95th 38   max 47
   0-4  ##
   5-9  ########
  10-14 ########
  15-19 ###########
  20-24 ##########
  25-29 ######
  30-34 ###
  35-39 ###
  40-44 
  45-49 #
```

Fifty-two items merged in June and July. Half of them took 18 days or fewer, which is the **median**. The 85th percentile is **29**: 85% of items finished within 29 days, and the remaining 15%, about one item in seven, took longer, up to 47.

## After it

```
ana@laptop:~/delivery$ python3 cycle.py 2026-09-01 2026-09-30
30 items, cycle time in days
  mean 5.0   median 4   85th 8   95th 12   max 17
   0-4  ##################
   5-9  ########
  10-14 ###
  15-19 #
```

In September the median is **4** days and the 85th percentile **8**. Look at the histogram rather than the summary line: the bulk moved into the first two rows, and the tail got shorter but did not disappear. One item still took 17 days. A team that only quoted the mean, 5.0, would be telling a stakeholder something that was false for more than a quarter of the items: eight of the thirty took longer.

## The number to quote

**Quote a percentile, and say which.** The 85th is the common choice, for a practical reason: it is high enough that a stakeholder is rarely let down, and low enough that one freak item does not set it. Said out loud it becomes a promise about the team's own history: *"85% of our items finish within eight days."*

The Kanban Guide calls a statement of that shape a **service level expectation**, an SLE: a cycle time and the probability of meeting it. It is not a target the team is held to, and it is not a deadline for any one item. It is a forecast, made from history, and lesson 3 uses it every morning: an item still open past eight days is already among the slow 15%.

The 95th percentile is worth knowing too, and worth quoting less. With thirty items, the 95th is the second-longest item, so a single new straggler moves it. **The fewer items in the period, the less the high percentiles can carry**, and fifty is a reasonable minimum before quoting the 95th to anybody.

## What the mean is good for

The mean is not useless. It is the number Little's law speaks in, and lesson 1 used it for exactly that, because the law is about averages. It is also sensitive to the tail on purpose: if the mean rises while the median stays put, the slow items got slower, and that is worth knowing. What it is bad at is being repeated to somebody who wants to know when their item will be ready.
