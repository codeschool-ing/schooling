---
title: Checking relations when nobody knows the answer
version: 1
---

**Sometimes a tester cannot say what the right result is, but can say how two results must relate to each other.**
Nobody may know what a 9:30 ticket should cost; everybody knows a morning ticket must not cost more than an afternoon
one. A check built on relations like that is a **partial oracle**: it cannot confirm a result is right, but it can
prove that two results cannot both be.

The idea has a name in research, **metamorphic testing**, from Tsong Yueh Chen and colleagues in 1998, where the
relations are called metamorphic relations. The idea is older than the name, and it is the most useful thing to know
about oracles, because it turns *we cannot tell* into *we can tell something*.

## Relations in the price rule

Joana's five sentences imply relations nobody wrote down:

- **an earlier session never costs more than a later one on the same day**, because there are only two prices and
  the cheaper one is before 17:00;
- **being a student never makes a ticket cost more**;
- **adding a ticket to an order never makes the order cheaper**;
- **a price is never more than R$ 36,00 and never less than R$ 14,00**.

Each of these can be checked across hundreds of inputs without anybody working out a single expected price.

## A relations check, in the lab

Lia wrote a short program that checks the first two relations across a spread of times, days and ages, against the
version of `tickets.py` that passed every acceptance test in lesson 17. Save it in `~/aurora` as `relations.py`:

```schooling-example
{"language": "python", "file": "relations.py", "parts": [{"code": "# relations.py\nfrom tickets import price\n\nTIMES = [\"9:30\", \"11:00\", \"15:00\", \"16:59\", \"17:00\", \"20:00\"]\n", "note": "The price rule from lesson 17, and a spread of session times in the order they happen in a day, written the way the schedule writes them."}, {"code": "\nfound = 0\nfor day in (\"thu\", \"wed\", \"sun\"):\n    for age in (35, 70):\n", "note": "Three days, one of them Wednesday, and two ages, one of them past the age line: every combination gets both relations checked."}, {"code": "        prices = [price(age, False, day, t) for t in TIMES]\n        for i in range(len(TIMES) - 1):\n            if prices[i] > prices[i + 1]:\n                found += 1\n                print(f\"{day}, age {age}: {TIMES[i]} costs {prices[i]}, but the later {TIMES[i + 1]} costs {prices[i + 1]}\")\n", "note": "The first relation: walking through the day, a price may stay the same or go up, never down. No price is written anywhere; only the comparison between neighbours."}, {"code": "        for time in TIMES:\n            if price(age, True, day, time) > price(age, False, day, time):\n                found += 1\n                print(f\"{day}, age {age}, {time}: a student pays more than a non-student\")\n", "note": "The second relation: the same customer, as a student and not, at the same session. Being a student may lower the price or leave it alone, never raise it."}, {"code": "print(found, \"broken relations\")\n", "note": "The count at the end, so a run where nothing breaks still says what it checked."}]}
```

```
lia@lab:~/aurora$ python relations.py
thu, age 35: 9:30 costs 3600, but the later 11:00 costs 2800
thu, age 70: 9:30 costs 1800, but the later 11:00 costs 1400
wed, age 35: 9:30 costs 1800, but the later 11:00 costs 1400
wed, age 70: 9:30 costs 1800, but the later 11:00 costs 1400
sun, age 35: 9:30 costs 3600, but the later 11:00 costs 2800
sun, age 70: 9:30 costs 1800, but the later 11:00 costs 1400
6 broken relations
```

Six broken relations, and every one is the 9:30 session: at 9:30 the program charges the evening price, then at 11:00
it charges the matinée price. The check does not know what 9:30 should cost. It knows that 9:30 cannot cost more than
11:00 on the same day, and that was enough to find the defect lesson 17's green tables were honest about not covering.

The student relation found nothing, and that matters too: across 36 combinations, being a student never raised a price.
A relation that holds is evidence, not proof, about the inputs it was tried on.

## Where relations come from

Good relations come from asking what must stay the same, or move in one direction, when an input changes:

| change the input | and the result must |
|---|---|
| move the session later in the day | not get more expensive |
| add a reason for half price | not get more expensive |
| add a ticket to an order | get more expensive, by that ticket's price |
| sort the session list twice | give the same list as sorting once |
| run the same order twice | give the same total both times |

Each row is a test that needs no expected value, and each is a question to a person when it fails: the relation might
be wrong, which happens, or the program might be. Either way somebody learns something they did not know.
