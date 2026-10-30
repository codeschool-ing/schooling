---
title: What to test, and where
version: 1
---

**Test what would hurt a student if it broke silently, at the cheapest layer that can see it.** That
sentence decides most cases, and the planner's own tests show how.

| what could break | who would notice, and when | where this course tests it |
|---|---|---|
| the week's total counts the wrong days | nobody, until a Sunday | plain JUnit, section 03 |
| a tap does not move the total | the student, at once | Compose test on Robolectric, section 04 |
| a padding or colour changes by accident | a reviewer, if they look | screenshot test, section 05 |
| the sync is scheduled twenty times | nobody; the battery drains | Robolectric with WorkManager's test driver, lesson 18 |
| a reminder posts without permission | nobody; it is dropped silently | Robolectric, lesson 19 |
| a refused permission leaves a dead button | the student, frustrated | a fake registry on Robolectric, lesson 20 |
| the notification never reaches the shade on a real phone | the student, much later | instrumented, section 06, not run |

**The silent failures matter most**, and they are most of the table. A crash gets reported; a total
that is wrong on Sundays, or a notification dropped without an error, can ship and stay shipped.
Each row in the table was found by asking "what would nobody notice?" and writing the test for that.

## What not to test

**Not the framework.** A test that Compose draws a `Text` with the string it was given tests Google's
code, which Google already tests. Test your decisions: which string, under which condition.

**Not the implementation.** A test that reads a private variable, or counts how many times a
function was called inside the screen, breaks whenever the code is tidied, and passes when the
screen is wrong in a way it did not count. Section 04's test asserts what a student sees.

**Not everything through screenshots.** One screenshot per screen and state is a safety net for the
look; a screenshot cannot say *which* number is wrong, and fifty of them fail together on every
library update. Assertions say what is meant; pictures catch what nobody thought to assert.

## When to run them

This lesson's whole suite ran again in 21 seconds in section 02, so it can run on every
change, on your machine and in continuous integration, which is the `testing-cicd` course's
subject. The instrumented ones, when you have a device, belong in a slower pipeline that runs less
often, before a release rather than on every commit. **A test that is only run before releases is a
test whose failures arrive late**, which is the argument for keeping as much as possible on the left
of section 02's figure.
