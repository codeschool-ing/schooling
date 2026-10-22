---
title: A sentence with no code, and what the sentences cost
version: 1
---

A conversation produces sentences faster than anybody writes methods, so Cucumber needs something
to say about a sentence no method claims. Add one line to the end of the first scenario, a promise
the shop has never made:

```
  Scenario: An order takes copies out of stock
    Given the shop has 5 copies of "The War of the Worlds"
    When she orders 2 copies of "The War of the Worlds"
    Then the order is accepted with a total of 6400 cents
    And "The War of the Worlds" has 3 copies left
    And she receives an e-mail confirming the order
```

and run the features again, this time keeping the lines that follow the exception:

```
ana@vm:~/bookshop$ PENDING
```

An **undefined step** is an error, not a skip. The steps before it ran, so the order was really
placed; then the scenario stopped at the line no method claims, the pretty report put a small
square where the tick would have been, and the build failed. Cucumber 8 has no setting that lets
an undefined step pass, and that is the right default: a sentence that runs nothing would
otherwise read as a check that holds.

What it prints instead is a **snippet**, the skeleton of the missing method. The sentence has become
the pattern, the keyword is `@Then` because an `And` continues the `Then` above it, and the method
name is the sentence in snake case (`cucumber.snippet-type=camelcase` asks for the other
convention). The body throws `PendingException`, Cucumber's word for *written but not done*, so
pasting the snippet and forgetting it cannot turn the scenario green by accident.

The snippet is also where the conversation comes back. The shop sends no e-mail, so this sentence
is either a wish nobody agreed to, and goes, or new work, and needs the three people again before it
needs a method. Remove the line before going on.

## A step that fails

A failure reads the same way, at the level of the sentence. Change `6400` to `6300` in the first
scenario's `Then` and run:

```
ana@vm:~/bookshop$ PENDING
```

The cross marks the sentence that failed, and under it AssertJ says what it expected and what came
back. The step after it is marked with a curved arrow, **skipped**: once one step fails, Cucumber
runs nothing else in that scenario, because every later step assumed the earlier ones held. The
other two scenarios are untouched, which is what keeping one `When` per scenario buys. The
question the failure asks is still the conversation's: either the example was wrong or the code is.
Put `6400` back.

## What the sentences cost

Count what three scenarios cost this project: a BOM and four dependencies, a feature file, a suite
class, a configuration class, and 86 lines of steps, with a matching layer between every
sentence and its method. Lesson 20's `BooksApiIT` checks a customer placing an order in one method
of about twenty lines. Both run the same HTTP calls against the same database.

The price is paid in three places. The first is **indirection**: to find what a step does, you go
from the sentence to the method by its text, which an editor with a Cucumber plugin makes a click
and anything else makes a search. The second is a vocabulary to look after. Sentences are global
across the glue, so the next feature that wants *the shop has 5 copies of …* reuses it, and one that
wants almost the same words either bends to fit or adds a near-duplicate; somebody has to keep the
steps a language rather than a pile. The third is that every renamed sentence detaches from its
code. Cucumber says so loudly, as the snippet above showed, but somebody still has to mend it.

It pays when people who do not read Java read the scenarios or write new ones: a product owner who
approves them in a pull request, testers who compose new examples from steps that already exist,
an auditor who asks which rule a test proves. Then the feature file is the cheapest shared record
the team has, and it fails the build when it stops being true.

It does not pay when only developers read the scenarios. The sentences are then a second copy of
what a JUnit test with a good `@DisplayName` (lesson 18) already says, and the glue is code with no
reader. A team that installs Cucumber "for the tests" and never holds the conversation gets the cost
without the benefit, which is the wrong picture from the start of this lesson with a bill attached.
**The tool is optional; the examples agreed before the code are not**, and they fit in a test name
as well as in a feature file.
