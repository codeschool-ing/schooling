---
title: The loop closes, and what is left open
version: 1
---

**The story is built inside the outer loop: Rafael works until the agreed examples pass, and then it is done.**
For the price rule that means two changes in `tickets.py`. The age line becomes *60 and over*, and Wednesday
stops being a second discount on top of the first: it is one more reason for half price, and half price is the
most a ticket can be reduced.

```python
# tickets.py
import sys

EVENING = 3600
MATINEE = 2800


def price(age, student, day, time):
    if time < "17:00":
        full = MATINEE
    else:
        full = EVENING
    half = False
    if student:
        half = True
    if age >= 60:
        half = True
    if age < 12:
        half = True
    if day == "wed":
        half = True
    if half:
        return full // 2
    return full


def brl(cents):
    return f"R$ {cents // 100},{cents % 100:02d}"


if __name__ == "__main__":
    age, student, day, time = sys.argv[1:]
    print(brl(price(int(age), student == "yes", day, time)))
```

Two lines changed: `age > 60` became `age >= 60`, and `full = full // 2` on Wednesdays became `half = True`. In a
real ATDD team each would have had its own TDD cycles inside the outer loop, as lesson 15 showed; here the point
is the outer test:

```
lia@lab:~/aurora$ behave features/prices.feature
USING RUNNER: behave.runner:Runner
Feature: Ticket prices # features/prices.feature:2
  R$ 36,00 from 17:00, R$ 28,00 before. Students, customers aged 60 and
  over and children under 12 pay half. Wednesdays are half price. Half
  price is the most any ticket is reduced.
  Scenario Outline: one ticket -- @1.1 the age line  # features/prices.feature:15
    Given a customer aged 59 who is not a student    # features/steps/prices_steps.py:6
    And a thu session at 20:00                       # features/steps/prices_steps.py:12
    When they buy a ticket                           # features/steps/prices_steps.py:17
    Then they pay R$ 36,00                           # features/steps/prices_steps.py:22

  Scenario Outline: one ticket -- @1.2 the age line  # features/prices.feature:16
    Given a customer aged 60 who is not a student    # features/steps/prices_steps.py:6
    And a thu session at 20:00                       # features/steps/prices_steps.py:12
    When they buy a ticket                           # features/steps/prices_steps.py:17
    Then they pay R$ 18,00                           # features/steps/prices_steps.py:22

  Scenario Outline: one ticket -- @1.3 the age line  # features/prices.feature:17
    Given a customer aged 61 who is not a student    # features/steps/prices_steps.py:6
    And a thu session at 20:00                       # features/steps/prices_steps.py:12
    When they buy a ticket                           # features/steps/prices_steps.py:17
    Then they pay R$ 18,00                           # features/steps/prices_steps.py:22

  Scenario Outline: one ticket -- @2.1 Wednesday with another discount  # features/prices.feature:21
    Given a customer aged 35 who is not a student                       # features/steps/prices_steps.py:6
    And a wed session at 20:00                                          # features/steps/prices_steps.py:12
    When they buy a ticket                                              # features/steps/prices_steps.py:17
    Then they pay R$ 18,00                                              # features/steps/prices_steps.py:22

  Scenario Outline: one ticket -- @2.2 Wednesday with another discount  # features/prices.feature:22
    Given a customer aged 35 who is a student                           # features/steps/prices_steps.py:6
    And a wed session at 20:00                                          # features/steps/prices_steps.py:12
    When they buy a ticket                                              # features/steps/prices_steps.py:17
    Then they pay R$ 18,00                                              # features/steps/prices_steps.py:22

  Scenario Outline: one ticket -- @2.3 Wednesday with another discount  # features/prices.feature:23
    Given a customer aged 8 who is not a student                        # features/steps/prices_steps.py:6
    And a wed session at 15:00                                          # features/steps/prices_steps.py:12
    When they buy a ticket                                              # features/steps/prices_steps.py:17
    Then they pay R$ 14,00                                              # features/steps/prices_steps.py:22

1 feature passed, 0 failed, 0 skipped
6 scenarios passed, 0 failed, 0 skipped
24 steps passed, 0 failed, 0 skipped
Took 0min 0.002s
```

Six of six. In ATDD terms the story is now done, and Joana does not need to read the code to know it: she agreed
the six rows before the work started, and the six rows pass.

## The checks that were already there

The coupon scenarios from lesson 16 run in the same project. Running behave with no feature named runs every feature,
and that is the check that the new code has not broken the old one. `--format progress` prints one dot per
scenario instead of every step, which is how a suite this size is usually read:

```
lia@lab:~/aurora$ behave --format progress
USING RUNNER: behave.runner:Runner
features/coupons.feature  ....
features/prices.feature  ......

2 features passed, 0 failed, 0 skipped
10 scenarios passed, 0 failed, 0 skipped
36 steps passed, 0 failed, 0 skipped
Took 0min 0.003s
```

Two features, ten scenarios. This is lesson 10's regression suite, grown out of the acceptance tests of every
story so far, and it will run on every change from now on.

## What the green tables do not say

The six rows say the rule holds for the six examples the three amigos chose. They do not say the program is right
about every input, and the map already showed one thing they leave out: the red card. A session typed as `9:30`
still compares as text, and still costs the evening price. Nobody has decided yet whether the box office ever
types it, so there is no row for it, and the acceptance tests are honest about that by not pretending.

That is the honest position for ATDD to leave a tester in. The agreed examples are covered, every day,
automatically. What is left is exactly what the earlier lessons gave a tester to do: owning the open questions,
exploring beyond the agreed cases, and bringing what that finds back to the next three amigos as new examples.
