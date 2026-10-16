---
title: The scenarios grow, the code follows
version: 1
---

**Once the steps exist, a new example costs a few lines of Gherkin and no code at all.** That is when BDD
starts paying back: the team can add the cases discovery produced in the words it used to discuss them.

## Lesson 15's examples, as scenarios

Lia writes the two other examples from lesson 15 into the feature, in Joana's words rather than the test names.
The lowercase code and the pasted spaces go into one scenario, because Célia described them as one thing: *the
code is read however it is typed.*

```
# features/coupons.feature
Feature: Coupons
  A customer with a coupon code pays less for the order.

  Scenario: PIPOCA takes five reais off
    Given an order of R$ 36,00
    When the customer uses the code "PIPOCA"
    Then the order costs R$ 31,00

  Scenario: a code the cinema did not issue changes nothing
    Given an order of R$ 36,00
    When the customer uses the code "XYZ"
    Then the order costs R$ 36,00

  Scenario: the code is read however it is typed
    Given an order of R$ 28,00
    When the customer uses the code " pipoca "
    Then the order costs R$ 23,00
```

```
lia@lab:~/aurora$ behave
USING RUNNER: behave.runner:Runner
Feature: Coupons # features/coupons.feature:2
  A customer with a coupon code pays less for the order.
  Scenario: PIPOCA takes five reais off      # features/coupons.feature:5
    Given an order of R$ 36,00               # features/steps/coupons_steps.py:6
    When the customer uses the code "PIPOCA" # features/steps/coupons_steps.py:11
    Then the order costs R$ 31,00            # features/steps/coupons_steps.py:16

  Scenario: a code the cinema did not issue changes nothing  # features/coupons.feature:10
    Given an order of R$ 36,00                               # features/steps/coupons_steps.py:6
    When the customer uses the code "XYZ"                    # features/steps/coupons_steps.py:11
    Then the order costs R$ 36,00                            # features/steps/coupons_steps.py:16

  Scenario: the code is read however it is typed  # features/coupons.feature:15
    Given an order of R$ 28,00                    # features/steps/coupons_steps.py:6
    When the customer uses the code " pipoca "    # features/steps/coupons_steps.py:11
    Then the order costs R$ 23,00                 # features/steps/coupons_steps.py:16

1 feature passed, 0 failed, 0 skipped
3 scenarios passed, 0 failed, 0 skipped
9 steps passed, 0 failed, 0 skipped
Took 0min 0.001s
```

Three scenarios, nine steps, no new step definitions: the patterns from the previous section matched every line.

## A new rule arrives as a scenario

For the premiere of a Brazilian film in November, Joana wants a second code: *ESTREIA takes R$ 10,00 off.* In a
BDD team the new rule enters the project as an example, before anybody changes the code. Lia adds it to the
feature with Joana watching:

```
# features/coupons.feature
Feature: Coupons
  A customer with a coupon code pays less for the order.

  Scenario: PIPOCA takes five reais off
    Given an order of R$ 36,00
    When the customer uses the code "PIPOCA"
    Then the order costs R$ 31,00

  Scenario: a code the cinema did not issue changes nothing
    Given an order of R$ 36,00
    When the customer uses the code "XYZ"
    Then the order costs R$ 36,00

  Scenario: the code is read however it is typed
    Given an order of R$ 28,00
    When the customer uses the code " pipoca "
    Then the order costs R$ 23,00

  Scenario: ESTREIA takes ten reais off
    Given an order of R$ 36,00
    When the customer uses the code "ESTREIA"
    Then the order costs R$ 26,00
```

```
lia@lab:~/aurora$ behave
USING RUNNER: behave.runner:Runner
Feature: Coupons # features/coupons.feature:2
  A customer with a coupon code pays less for the order.
  Scenario: PIPOCA takes five reais off      # features/coupons.feature:5
    Given an order of R$ 36,00               # features/steps/coupons_steps.py:6
    When the customer uses the code "PIPOCA" # features/steps/coupons_steps.py:11
    Then the order costs R$ 31,00            # features/steps/coupons_steps.py:16

  Scenario: a code the cinema did not issue changes nothing  # features/coupons.feature:10
    Given an order of R$ 36,00                               # features/steps/coupons_steps.py:6
    When the customer uses the code "XYZ"                    # features/steps/coupons_steps.py:11
    Then the order costs R$ 36,00                            # features/steps/coupons_steps.py:16

  Scenario: the code is read however it is typed  # features/coupons.feature:15
    Given an order of R$ 28,00                    # features/steps/coupons_steps.py:6
    When the customer uses the code " pipoca "    # features/steps/coupons_steps.py:11
    Then the order costs R$ 23,00                 # features/steps/coupons_steps.py:16

  Scenario: ESTREIA takes ten reais off       # features/coupons.feature:20
    Given an order of R$ 36,00                # features/steps/coupons_steps.py:6
    When the customer uses the code "ESTREIA" # features/steps/coupons_steps.py:11
    Then the order costs R$ 26,00             # features/steps/coupons_steps.py:16
      ASSERT FAILED: 3600



Failing scenarios:
  features/coupons.feature:20  ESTREIA takes ten reais off

0 features passed, 1 failed, 0 skipped
3 scenarios passed, 1 failed, 0 skipped
11 steps passed, 1 failed, 0 skipped
Took 0min 0.001s
```

Read the failure the way lesson 15 taught: the scenario named under *Failing scenarios*, the step that failed,
and `ASSERT FAILED: 3600`, the total the code actually produced, printed by the text after the comma in the
`assert`. ESTREIA is an unknown code to the current program, so it changes nothing. The scenario is red because
the rule is new, which is exactly what a new scenario should do.

Rafael's change is one entry in the table from lesson 15's refactor:

```python
# coupons.py
COUPONS = {"PIPOCA": 500, "ESTREIA": 1000}


def apply(code, total):
    off = COUPONS.get(code.strip().upper(), 0)
    return total - off
```

```
lia@lab:~/aurora$ behave
USING RUNNER: behave.runner:Runner
Feature: Coupons # features/coupons.feature:2
  A customer with a coupon code pays less for the order.
  Scenario: PIPOCA takes five reais off      # features/coupons.feature:5
    Given an order of R$ 36,00               # features/steps/coupons_steps.py:6
    When the customer uses the code "PIPOCA" # features/steps/coupons_steps.py:11
    Then the order costs R$ 31,00            # features/steps/coupons_steps.py:16

  Scenario: a code the cinema did not issue changes nothing  # features/coupons.feature:10
    Given an order of R$ 36,00                               # features/steps/coupons_steps.py:6
    When the customer uses the code "XYZ"                    # features/steps/coupons_steps.py:11
    Then the order costs R$ 36,00                            # features/steps/coupons_steps.py:16

  Scenario: the code is read however it is typed  # features/coupons.feature:15
    Given an order of R$ 28,00                    # features/steps/coupons_steps.py:6
    When the customer uses the code " pipoca "    # features/steps/coupons_steps.py:11
    Then the order costs R$ 23,00                 # features/steps/coupons_steps.py:16

  Scenario: ESTREIA takes ten reais off       # features/coupons.feature:20
    Given an order of R$ 36,00                # features/steps/coupons_steps.py:6
    When the customer uses the code "ESTREIA" # features/steps/coupons_steps.py:11
    Then the order costs R$ 26,00             # features/steps/coupons_steps.py:16

1 feature passed, 0 failed, 0 skipped
4 scenarios passed, 0 failed, 0 skipped
12 steps passed, 0 failed, 0 skipped
Took 0min 0.001s
```

## Where it goes wrong

Teams that adopt BDD tools without the conversations tend to fail in the same few ways, and a tester is often
the first to notice:

- **scenarios written after the code**, by the developer, to describe what was built: the tool is there, the
  discovery is not, and the scenarios agree with the code by construction;
- **scenarios nobody outside the team reads**: if Joana never sees the feature file, the shared language is
  shared by two people;
- **scenarios as test scripts**: imperative steps, dozens of cases, every price on the board, until the feature
  file is a regression suite with extra syntax;
- **steps that hide the example**: *Given a standard order* tells a reader nothing; *Given an order of R$ 36,00*
  is the example.

None of these is a problem with Gherkin. Each one is the discovery practice missing, and the next lesson is
about the meeting where discovery happens.
