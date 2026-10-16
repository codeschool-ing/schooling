---
title: A few numbers worth keeping
version: 1
---

**A handful of measures hold up better than the rest, because they look at what reaches customers and are hard to
improve without improving the product.** None of them is safe from Goodhart's law; all of them are safer than counting
activity.

## Escaped defects, and the detection percentage

An **escaped defect** is one found after release, by a customer or by the staff using the product for real. The count of
escaped defects, by area and by severity, answers the question every tester is really asking: *what are we missing?*

The **defect detection percentage** puts it in proportion: of all the defects known, the share found before release.

> **detection percentage = defects found before release ÷ all defects found**

It cannot be read on release day, only weeks later, once customers have had time to find what testing missed. That delay
is also what makes it hard to game: a defect a customer reports cannot be closed as "won't fix" on Thursday night.

## Cine Aurora's records, in the lab

Lia keeps the team's defect records in a plain file, one row per defect: the area, whether it was found **before** or
**after** release, its severity, and the days it took to fix, or `open`. Save this in `~/aurora` as `defects.csv`:

```
# defects.csv
id,area,found,severity,days_to_fix
1,prices,before,high,1
2,prices,after,high,open
3,prices,before,high,1
4,prices,before,medium,2
5,orders,before,high,1
6,coupons,after,medium,1
7,refunds,before,critical,0
8,seat map,after,medium,3
9,report,before,low,1
```

These are the defects this course has met: the age line, the 9:30 session, Wednesday stacking, the inputs nobody
mentioned, the refused orders, the pasted coupon codes, the refund crash, and two more from the Friday release. One of
them is defect 8: the seat map on phones, which lesson 20's summary listed as *not tested*, showed a taken seat as free,
and a customer found it the first weekend.

A short program turns the file into the three numbers from the first section:

```schooling-example
{"language": "python", "file": "metrics.py", "parts": [{"code": "# metrics.py\nimport csv\n\nwith open(\"defects.csv\") as f:\n    rows = list(csv.DictReader(line for line in f if not line.startswith(\"#\")))\n", "note": "Python’s `csv` module reads the file into one dictionary per row, keyed by the header. The line starting with `#` is skipped, because it names the file and is not a record."}, {"code": "\nbefore = [r for r in rows if r[\"found\"] == \"before\"]\nafter = [r for r in rows if r[\"found\"] == \"after\"]\n", "note": "The defects split in two by one question: found before the release, or after it."}, {"code": "print(\"defects:\", len(rows))\nprint(\"found before release:\", len(before))\nprint(\"found after release:\", len(after))\nprint(f\"detection percentage: {len(before) / len(rows):.0%}\")\n", "note": "The counts, and the detection percentage: found before, divided by all. `:.0%` prints a fraction as a whole percentage."}, {"code": "print(\"escaped, by area:\", \", \".join(r[\"area\"] for r in after))\nprint(\"still open:\", \", \".join(\"defect \" + r[\"id\"] for r in rows if r[\"days_to_fix\"] == \"open\"))\n", "note": "And the two lists a number should never be shown without: where the escaped defects were, and which defects are still open."}]}
```

```
lia@lab:~/aurora$ python metrics.py
defects: 9
found before release: 6
found after release: 3
detection percentage: 67%
escaped, by area: prices, coupons, seat map
still open: defect 2
```

Nine defects, six found first, a detection percentage of 67%, and defect 2, the 9:30 session, still open with its
workaround. The escaped three are each worth a sentence. The 9:30
session escaped because nobody had asked how times were typed. The coupon spaces escaped because nobody had watched
Célia paste. The seat map on phones escaped because it was on the list of things not tested, written down and accepted:
a gap that was *known* and *chosen*, which is the honest kind of escape.

## Flow numbers, read with care

Lesson 13's lead time, cycle time and flow efficiency are useful in the same way: they describe what the customer
experiences, waiting. The cautions from that lesson still apply. A lead time that falls because cards skip testing is
the theatre of the previous section.

## How Cine Aurora uses them

Once a month, at the review of the flow measures, Lia brings three numbers and no more: escaped defects since the last
review, the detection percentage over the last three months, and the days to fix any pricing defect. Each is shown with
the defects behind it, never alone. Nobody is ranked by them. Each month the team asks the same question of each number,
**what does this change about what we do next?**, and when the answer is *nothing* twice in a row, the number is dropped.
