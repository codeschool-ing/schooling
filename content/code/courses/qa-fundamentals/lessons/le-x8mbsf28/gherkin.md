---
title: Gherkin, the format examples are written in
version: 1
---

**Gherkin is a small structured language for writing examples of behaviour so that people can read them and a
tool can run them.** It came with Cucumber, a BDD tool Aslak Hellesøy started in 2008, and it is now read by
tools in most programming languages; in Python the usual one is **behave**, which you installed in lesson 1.

A Gherkin file describes one **feature** and holds **scenarios**, each one a concrete example. Here is the
first scenario Cine Aurora wrote for coupons. Save it in `~/aurora` in a new folder, as
`features/coupons.feature`:

```
# features/coupons.feature
Feature: Coupons
  A customer with a coupon code pays less for the order.

  Scenario: PIPOCA takes five reais off
    Given an order of R$ 36,00
    When the customer uses the code "PIPOCA"
    Then the order costs R$ 31,00
```

## The keywords

| keyword | what it does |
|---|---|
| `Feature:` | names the feature; the lines under it are a free description for people, which the tool ignores |
| `Scenario:` | one example, with a name that says what it shows |
| `Given` | the situation before anything happens: the context |
| `When` | the one action the example is about |
| `Then` | the outcome that should be observable afterwards |
| `And`, `But` | continue the step above, so a scenario does not read *Given … Given … Given* |
| `#` | a comment, for people only |

It is lesson 12's *given, when, then*, with the keywords at the start of the line so a tool can find them. The
same discipline applies: one *When* per scenario, because a scenario with three actions is three examples
tangled together, and a failure in it says less.

## Declarative, not imperative

The most common way to write bad Gherkin is to describe the clicks instead of the behaviour. Compare two
scenarios that check the same thing:

| imperative | declarative |
|---|---|
| Given I open the box office screen | Given an order of R$ 36,00 |
| And I click "new order" | When the customer uses the code "PIPOCA" |
| And I choose session "thu 20:00" | Then the order costs R$ 31,00 |
| And I type "35" in the age field | |
| And I click "add ticket" | |
| And I type "PIPOCA" in the coupon field | |
| And I click "apply" | |
| Then the total field shows "R$ 31,00" | |

The imperative one is longer, harder for Joana to read, and breaks every time a button is renamed, although
the rule has not changed. The declarative one says what the business cares about and nothing else. The *how*,
which screen, which field, belongs in the code that runs the steps, where one change fixes every scenario.

A good test for a scenario: **could Joana have written it?** Not typed the syntax, but said those sentences. If a
step mentions a button, a database or a variable, it is speaking the developers' language, not the shared one.

## What a scenario is not

A Gherkin file is not a test plan written in a strange format. It is a small number of examples, chosen in
discovery because each one shows something about the rule: the ordinary case, the boundary, the combination
that was argued about. A feature file with two hundred scenarios covering every price on the board is a
regression suite that nobody outside the team will read, and the reason for writing it in Gherkin has gone. The
many cases belong in ordinary automated checks like lesson 15's; the scenarios are the ones worth a
conversation.
