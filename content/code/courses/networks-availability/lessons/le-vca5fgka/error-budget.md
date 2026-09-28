---
title: The error budget
version: 1
---

An objective of 99.9% sounds like a demand for perfection that falls a little short. Read from the other
side it is an allowance: **0.1% of the time may be spent being down, and the team decides what to spend
it on.** That allowance is the **error budget**.
This program works it out for a 30-day month, and counts how many failovers like the one lesson 15
measured would fit in each:

```schooling-example
{"language": "python", "file": "budget.py", "parts": [{"code": "MONTH = 30 * 24 * 60 * 60  # a 30-day month, in seconds\nFAILOVER = 3.264           # the gap lesson 15 measured, in seconds", "note": "The window is a 30-day month, stated rather than assumed. The failover is the gap lesson 15 measured on its ping, from the last reply before the cable was pulled to the first one after."}, {"code": "for slo in (0.99, 0.999, 0.9995, 0.9999):\n    budget = MONTH * (1 - slo)", "note": "The budget is what the objective leaves over: 1% of the month at 99%, a tenth of that at 99.9%."}, {"code": "    print(f\"{slo:.2%}  budget {budget / 60:6.2f} min  \"\n          f\"= {int(budget // FAILOVER):5} failovers of {FAILOVER} s\")", "note": "Each budget in minutes, and as the number of whole failovers of that length it could absorb."}], "output": "99.00%  budget 432.00 min  =  7941 failovers of 3.264 s\n99.90%  budget  43.20 min  =   794 failovers of 3.264 s\n99.95%  budget  21.60 min  =   397 failovers of 3.264 s\n99.99%  budget   4.32 min  =    79 failovers of 3.264 s"}
```

**The window moves the number.** Lesson 14 gave 43.80 minutes a month for 99.9%, using a twelfth of a
365-day year, which is an average month of about 30.4 days. Here, with a 30-day month, it is 43.20. The
difference is small, and it is exactly the kind of difference two parties to a contract end up arguing
about, which is why an SLA states its window.

**Failovers are cheap and people are expensive.** At three nines, 794 failovers of 3.264 seconds fit in a
month; at four nines, 79 still do. A single incident that needs a person, a page at night, somebody
logging in, a diagnosis and a restart, takes far longer. Even at a quick 45 minutes it spends more than
the whole 99.9% month, 43.20 minutes, on its own. **The budget is not spent by failures the machines
handle; it is spent by the ones that wait for somebody.** That is the argument for the automatic failover of lessons 15 and 16, stated in minutes.

## Spending it on purpose

A budget is also a permission. Every change to a running system risks some downtime: a deployment, an
upgrade, a configuration pushed to a balancer. If the month's budget is untouched, the team can move faster
and take those risks. If it is spent, the sensible policy is to stop changing things until it recovers,
and to put the effort into whatever spent it.

That turns an old argument between the people who build features and the people who keep the service up
into arithmetic both can read. **An objective of 100% is a promise never to change anything**, because
every change carries risk; the error budget is the agreed amount of risk the business is willing to buy
with its speed.
