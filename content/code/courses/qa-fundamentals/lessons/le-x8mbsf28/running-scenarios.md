---
title: Making a scenario run
version: 1
---

**A scenario runs when every one of its steps is matched to a small piece of code, a step definition.** behave
reads the feature file, and for each line looks for a function whose pattern matches it. Run it in `~/aurora`,
where `features/` is, with the feature from the previous section and nothing else yet:

```
lia@lab:~/aurora$ behave
USING RUNNER: behave.runner:Runner
Feature: Coupons # features/coupons.feature:2
  A customer with a coupon code pays less for the order.
  Scenario: PIPOCA takes five reais off      # features/coupons.feature:5
    Given an order of R$ 36,00               # None
    When the customer uses the code "PIPOCA" # None
    Then the order costs R$ 31,00            # None


You can implement step definitions for undefined steps with these snippets:

from behave.api.pending_step import StepNotImplementedError
@given(u'an order of R$ 36,00')
def step_impl(context):
    raise StepNotImplementedError(u'Given an order of R$ 36,00')


@when(u'the customer uses the code "PIPOCA"')
def step_impl(context):
    raise StepNotImplementedError(u'When the customer uses the code "PIPOCA"')


@then(u'the order costs R$ 31,00')
def step_impl(context):
    raise StepNotImplementedError(u'Then the order costs R$ 31,00')



Errored scenarios:
  features/coupons.feature:5  PIPOCA takes five reais off

0 features passed, 0 failed, 1 error, 0 skipped
0 scenarios passed, 0 failed, 1 error, 0 skipped
0 steps passed, 0 failed, 0 skipped, 3 undefined
Took 0min 0.000s
```

Nothing failed, because nothing ran. behave lists the three steps as **undefined** and prints a skeleton
for each. Read the summary at the bottom: zero passed, zero failed, one error, three undefined. An undefined step
is behave's way of saying the sentence is understood by people and not yet by the machine.

## The step definitions

Rafael writes the three definitions in a second file, `features/steps/coupons_steps.py`, where behave looks for
them:

```schooling-example
{"language": "python", "file": "features/steps/coupons_steps.py", "parts": [{"code": "# features/steps/coupons_steps.py\nfrom behave import given, when, then\nfrom coupons import apply\n", "note": "behave’s three decorators, one per keyword, and lesson 15’s `apply`: the scenarios run the same code the unit tests run. `And` and `But` need no decorator of their own; they take the keyword of the step above."}, {"code": "\n\n@given(\"an order of R$ {reais:d},{cents:d}\")\ndef an_order(context, reais, cents):\n    context.total = reais * 100 + cents\n", "note": "The pattern is the sentence, with the parts that vary in braces. `:d` means a whole number, so `R$ 36,00` gives `reais` 36 and `cents` 0. `context` is an object behave hands to every step of a scenario, so a value set in `Given` is there for `When` and `Then`."}, {"code": "\n\n@when('the customer uses the code \"{code}\"')\ndef uses_code(context, code):\n    context.total = apply(code, context.total)\n", "note": "The action: whatever is between the quotes is the code, spaces included, and the total is replaced by what `apply` returns."}, {"code": "\n\n@then(\"the order costs R$ {reais:d},{cents:d}\")\ndef costs(context, reais, cents):\n    assert context.total == reais * 100 + cents, context.total\n", "note": "The outcome. `assert` fails the step if the comparison is false, and the text after the comma, here the actual total, is what behave prints when it does."}]}
```

Each decorator holds a pattern, and the `{…}` parts are captured. Because the patterns name the reais and the
centavos instead of one fixed price, these three functions match *any* order total and *any* code, which is the
point: the sentences are reusable, and the next scenarios will need no new code. Run behave again:

```
lia@lab:~/aurora$ behave
USING RUNNER: behave.runner:Runner
Feature: Coupons # features/coupons.feature:2
  A customer with a coupon code pays less for the order.
  Scenario: PIPOCA takes five reais off      # features/coupons.feature:5
    Given an order of R$ 36,00               # features/steps/coupons_steps.py:6
    When the customer uses the code "PIPOCA" # features/steps/coupons_steps.py:11
    Then the order costs R$ 31,00            # features/steps/coupons_steps.py:16

1 feature passed, 0 failed, 0 skipped
1 scenario passed, 0 failed, 0 skipped
3 steps passed, 0 failed, 0 skipped
Took 0min 0.000s
```

Green, with each step shown beside the line of code that ran it. That second column is useful when a step
matches a function you did not expect.

## Who writes what

Look at where the work ended up. The feature file is in Cine Aurora's words, readable by Joana and Célia, and
was formulated by Lia from the conversation. The step definitions are in Python and belong to the developers. The
coupon code itself is lesson 15's, untouched: behave calls the same `apply` the unit tests call.

That split is the whole architecture of BDD tooling, and it has a cost. Every step is a pattern somebody has to
maintain, and a team that writes steps carelessly ends up with forty slightly different ways of saying *an order
of*, each with its own function. The cure is the shared language from the first section: if everybody says *an
order of R$ 36,00* the same way, one step serves every scenario that needs an order.
