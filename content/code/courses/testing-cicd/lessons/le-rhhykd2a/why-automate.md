---
title: Checking by hand, and why it stops
version: 1
---

A common picture of testing is a person clicking through the application before a release, ticking
boxes on a list. That person is doing real work, and it does not scale. **An automated test is a
program that runs some of your code and compares what it did with what you expected.** It answers
yes or no, it answers the same way every time, and it costs almost nothing to ask again.

The arithmetic is what makes the difference. The project this course works on, `shipquote`, has
31 checks by the end of this lesson: prices per zone, weights at the edges, a free-shipping
threshold, the HTTP answers. Done by hand, each one is a minute of typing a CEP and reading a
number. That is half an hour per change. A team that merges ten changes a day would spend five
hours a day re-checking things that did not break, and in practice nobody does. **The checks that
are skipped are the ones that would have caught the regression.**

The same 31 checks, as a program, run in about a second and a quarter on a laptop. You will see
that number printed in section 09 of this lesson. A second and a quarter is short enough to run
after every save, which changes when a mistake is found: minutes after it was made, by the person
who made it, while the change is still in their head.

## What a test can and cannot tell you

A passing test says one thing: **for these inputs, the code did what the test expected.** It does
not say the code is correct for inputs nobody tried, and it does not say the expectation was
right. A test that checks the wrong number passes happily. That is why a test is only as good as
the thinking that chose its inputs, which section 10 of this lesson works through.

What automation buys, then, is not certainty. It buys three cheaper things:

1. **Repetition.** The 500th run costs what the first did, so old behaviour keeps being checked
   long after anybody remembers why it mattered.
2. **A record.** A test file says, in code, what the program promises. A new team member can read
   `test_an_order_of_199_reais_or_more_ships_free` and learn a business rule.
3. **Permission to change things.** Refactoring code with no tests means hoping. With tests, a
   change that breaks a promise says so in seconds.

## Where the course is going

This lesson names the kinds of test by what they exercise. Lessons 2 to 4 make tests cheaper and
more honest: doubles for the parts you do not control, fixtures for the data, and coverage for the
question "what did the tests never run?". From lesson 5 the tests leave your laptop and run on
every push, in a pipeline, and from lesson 7 the same pipeline delivers what passed. The last
three lessons are about releasing safely and stopping a release that is going wrong.

**The project is small on purpose.** `shipquote` is a few hundred lines of Python with no
dependency outside the standard library. The language is incidental: pytest has a counterpart in
every ecosystem (JUnit, Jest, `go test`, XCTest), and what this course says about tests and
pipelines holds in all of them. The lab script beside the course rebuilds the project exactly as
the lessons show it, commit hashes included.
