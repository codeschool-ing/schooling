---
title: Security debt, by age, and the trend
version: 1
---

Security debt is everything that is known and not yet dealt with: the open findings, plus the
exceptions lesson 7 granted with a date. The word is borrowed from technical debt, and it fits for
the same reason. **An old finding costs more to fix than a new one.** The person who wrote the code
has moved on, the dependency is three major versions behind instead of one, and the finding has been
seen so many times that nobody reads it. So the useful view of debt is not its size, but its age.

### The report

```
ana@vm:~/metrics$ python3 measure.py debt
severity  open  0-30 31-90 91-180  181+ past SLA
critical     3     3     0      0     0        0
high        10     8     2      0     0        2
medium      26     7    10      4     5        9
low         20     4     7      2     7        7
```

59 open findings, split by severity and into four age buckets: up to a month, up to a quarter, up
to half a year, and older. The last column counts the ones already past their SLA.

Read it from the bottom right. **Twelve findings have been open for more than 181 days**, five medium
and seven low, and they are the debt in the sense the word means: not work in progress, but work
that is not going to happen unless somebody decides it will. The 9 medium findings past their
90-day SLA are the most urgent line in the table, because they are promises already broken on
findings serious enough to matter.

The top two rows look healthy. All three open critical findings are less than a month old, and no
critical finding is past its SLA today. That is what a team fixing in order of severity looks like.
It is also why a debt report must be split by severity: the 59 as one number would be driven by the
medium and low rows and say nothing about whether the critical ones are handled.

### Buckets, not an average age

An average age of the open findings would be one number, and it would move for the wrong reasons:
fixing one very old finding lowers it as much as fixing many new ones. Buckets keep the shape. A
team whose `181+` column is growing is accumulating findings it will never fix, whatever its median
time to remediate says, and that is the pattern to catch early. Where the bucket edges sit matters
less than keeping them fixed, so the same table can be compared from one quarter to the next.

### The trend

```
ana@vm:~/metrics$ python3 measure.py trend
quarter   opened closed open at end
2025-10      143     79          64
2026-01      113    116          61
2026-04      126    128          59
2026-07      127    126          60
```

Per quarter: findings opened, findings closed, and how many were open on the quarter's last day.

The first row is an artefact of the data, and every real data set has one. The generated year
starts on 1 October 2025 with nothing open, so the first quarter fills the list from empty: 143
opened, 79 closed, 64 open at the end. A trend that starts the day the measuring started always
begins with a climb, and reading that climb as "things got worse" is a common mistake in the first
report a programme produces.

From the second quarter on, the company closes about as many findings as it opens, and the open
count holds near sixty: 61, 59, 60. **A flat line of open findings means the team keeps up, not that
it is getting anywhere.** Two other shapes are worth recognising:

| shape | what it means |
|---|---|
| open at end rising, quarter after quarter | more arrives than is closed; the backlog will not clear on its own |
| open at end flat | the team keeps up with arrivals; the old findings stay where they are |
| open at end falling | the backlog is being paid down, or something stopped finding things |

The last row has two readings, and they are opposites. A falling open count is good news when
closing went up, and bad news when opening went down because a scanner was switched off or a
target left the inventory. **Check coverage before celebrating a falling line**: it is the number
that tells the two apart, and the previous section is how.

### What to do with debt

Every finding in the `181+` column deserves one of the three decisions lesson 1 drew: fix it,
except it with an owner and a date, or close it as a false positive with the reason. What it should
not be is open and unowned for another quarter. Exceptions belong in the debt even though they are
not "open", because an exception is a decision to carry the risk until a date, and the date is when
it comes back.
