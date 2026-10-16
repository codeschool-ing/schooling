---
title: A month of sales, counted
version: 1
---

**Before release, the sixty-year-old's defect cost two commands to find and one character to fix.** It
is worth seeing what the same defect costs if it ships, and you do not have to imagine it: a short
program can sell a month of tickets through `tickets.py` and count.

Cine Aurora's real sales are not in this course, so the program invents a plausible month from a fixed
seed. What it charges is not invented: every price comes from the shop's own `price`. Save it in
`~/aurora` beside `tickets.py` as `overcharge.py`.

```schooling-example
{"language": "python", "file": "overcharge.py", "parts": [{"code": "# overcharge.py\nimport random\nfrom tickets import brl, price\n", "note": "It uses the shop’s own `price` and `brl` from `tickets.py`, so it charges exactly what the shop would. Keep both files in `~/aurora`."}, {"code": "\nDAYS = [\"thu\", \"fri\", \"sat\", \"sun\", \"mon\", \"tue\", \"wed\"]\nSESSIONS = [\"14:00\", \"16:30\", \"19:00\", \"21:30\"]\n", "note": "A week starting on a Thursday, which is the day new films open in Brazil, and the four sessions of one screen."}, {"code": "\nrng = random.Random(30)\nsold = tickets = extra = 0\nfor n in range(30):\n    day = DAYS[n % 7]\n    for _ in range(120):\n        age = rng.randint(15, 80)\n        time = rng.choice(SESSIONS)\n        paid = price(age, False, day, time)\n        sold += 1\n", "note": "Thirty days of 120 online sales each, to customers aged 15 to 80, none of them students. The sales are invented, from a fixed seed, so every run makes the same month and your numbers match these."}, {"code": "        if age == 60 and day != \"wed\":\n            tickets += 1\n            extra += paid - paid // 2\n", "note": "A sixty-year-old should have paid half. On a Wednesday everybody pays half anyway, so the defect costs them nothing that day and is not counted."}, {"code": "\nprint(sold, \"tickets sold in 30 days\")\nprint(tickets, \"of them to a sixty-year-old, outside a Wednesday\")\nprint(brl(extra), \"charged too much\")\n", "note": "The three numbers a manager would ask for."}]}
```

```
lia@lab:~/aurora$ python overcharge.py
3600 tickets sold in 30 days
41 of them to a sixty-year-old, outside a Wednesday
R$ 658,00 charged too much
```

**Forty-one tickets, R$ 658,00.** That is one screen, one month, online sales only. It is the smallest of
the four costs from the previous section, the one that can be counted, and it is already more than the
fix ever cost.

## What the count does not include

Look at what each of those forty-one tickets turns into once the defect is found:

- **finding the customers.** The shop records a sale; it may or may not record the age that was typed.
  If it does not, nobody can tell which of the 3600 tickets went to a sixty-year-old, and the refund
  becomes a notice at the counter asking people to come forward;
- **refunding them**, through a payment provider that charges a fee per refund;
- **the conversations.** Célia hears about it from regulars before anybody else does, and each
  conversation is ten minutes of her evening;
- **the second defect.** The program above had to skip Wednesdays, because on a Wednesday the shop
  charges everybody half. While writing it, Lia noticed what that line implies for a student on a
  Wednesday. Lesson 6 runs it.

None of those has a number in the output, and every one is real. That is the honest form of the
famous curve: the part you can count is small, and it is the floor.

## Counting it the other way

Now change one thing. Suppose the defect had been found and fixed before the first sale. The program
would print `R$ 0,00`, and every item in the list above would disappear with it. **The saving from
finding a defect early is everything that would have happened after**, and most of it never appears on
anybody's report, which is exactly why teams underestimate it.

The program also shows a habit worth keeping: when somebody asks *how bad is it?*, measure before you
answer. "Some pensioners were overcharged" invites a shrug. "Forty-one tickets in a month on one screen,
R$ 658,00 before refund fees" gets a fix scheduled.
