---
title: The map becomes a Scenario Outline
version: 1
---

**When many examples share one shape, Gherkin writes the shape once and the examples as a table: a Scenario
Outline.** Each row of the table is a scenario of its own when it runs. It is the formulation step of lesson 16,
for a rule whose examples differ only in their numbers.

The green cards from the map become two tables, one per rule, because each table says what it is examples *of*.
Save this in `~/aurora` as `features/prices.feature`:

```
# features/prices.feature
Feature: Ticket prices
  R$ 36,00 from 17:00, R$ 28,00 before. Students, customers aged 60 and
  over and children under 12 pay half. Wednesdays are half price. Half
  price is the most any ticket is reduced.

  Scenario Outline: one ticket
    Given a customer aged <age> who <is> a student
    And a <day> session at <time>
    When they buy a ticket
    Then they pay R$ <price>

    Examples: the age line
      | age | is     | day | time  | price |
      | 59  | is not | thu | 20:00 | 36,00 |
      | 60  | is not | thu | 20:00 | 18,00 |
      | 61  | is not | thu | 20:00 | 18,00 |

    Examples: Wednesday with another discount
      | age | is     | day | time  | price |
      | 35  | is not | wed | 20:00 | 18,00 |
      | 35  | is     | wed | 20:00 | 18,00 |
      | 8   | is not | wed | 15:00 | 14,00 |
```

The words in angle brackets are filled in from each row. The description under `Feature:` is Joana's rule, all
five sentences, with *aged 60 and over* where the first version said *over 60*: the map is where that was decided,
and the feature file is where it is written down for good.

## The steps

Four sentences need four step definitions, in `features/steps/prices_steps.py`. They call lesson 1's `price` and
`brl`, so the acceptance tests run the very code the box office would:

```schooling-example
{"language": "python", "file": "features/steps/prices_steps.py", "parts": [{"code": "# features/steps/prices_steps.py\nfrom behave import given, when, then\nfrom tickets import brl, price\n", "note": "The price rule and the formatter from lesson 1’s `tickets.py`, the same functions the command line uses."}, {"code": "\n\n@given(\"a customer aged {age:d} who {is_} a student\")\ndef a_customer(context, age, is_):\n    context.age = age\n    context.student = is_ == \"is\"\n", "note": "The customer: an age, and whether they are a student. The table writes `is` or `is not`, so the sentence reads naturally in both rows and the step turns it into `True` or `False`."}, {"code": "\n\n@given(\"a {day} session at {time}\")\ndef a_session(context, day, time):\n    context.day, context.time = day, time\n", "note": "The session, kept exactly as written: the day and the time are passed on as text, as the box office types them."}, {"code": "\n\n@when(\"they buy a ticket\")\ndef they_buy(context):\n    context.paid = brl(price(context.age, context.student, context.day, context.time))\n", "note": "The action calls the real rule and keeps the price as the customer would see it, `R$ 18,00`."}, {"code": "\n\n@then(\"they pay R$ {amount}\")\ndef they_pay(context, amount):\n    assert context.paid == f\"R$ {amount}\", context.paid\n", "note": "The outcome compares text with text, so a failure prints the price the program charged, in reais."}]}
```

## The first run

The story has not been built yet. Its acceptance tests are run anyway, because in ATDD a story starts red:

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
      ASSERT FAILED: R$ 36,00


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
      ASSERT FAILED: R$ 9,00


  Scenario Outline: one ticket -- @2.3 Wednesday with another discount  # features/prices.feature:23
    Given a customer aged 8 who is not a student                        # features/steps/prices_steps.py:6
    And a wed session at 15:00                                          # features/steps/prices_steps.py:12
    When they buy a ticket                                              # features/steps/prices_steps.py:17
    Then they pay R$ 14,00                                              # features/steps/prices_steps.py:22
      ASSERT FAILED: R$ 7,00



Failing scenarios:
  features/prices.feature:16  one ticket -- @1.2 the age line
  features/prices.feature:22  one ticket -- @2.2 Wednesday with another discount
  features/prices.feature:23  one ticket -- @2.3 Wednesday with another discount

0 features passed, 1 failed, 0 skipped
3 scenarios passed, 3 failed, 0 skipped
21 steps passed, 3 failed, 0 skipped
Took 0min 0.002s
```

Three rows pass and three fail, and every failure is a known defect from an earlier lesson, now written in
Joana's terms. The sixty-year-old from lesson 1 pays R$ 36,00. The student on a Wednesday from lesson 6 pays
R$ 9,00, and the child at the Wednesday matinée pays R$ 7,00. The rows that pass matter as well: the 59 and
61 rows pin the line from both sides, and the adult on a Wednesday shows that the Wednesday discount itself works.

Notice how the failures are reported: *one ticket -- @1.2 the age line* is the outline's name, then the table's
name and the row. A table with a good name makes a failure readable to the person who chose the examples.
