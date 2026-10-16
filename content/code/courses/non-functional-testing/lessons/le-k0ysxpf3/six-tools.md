---
title: Six tools side by side
version: 1
---

Lessons 4 to 7 have measured one box office with six load generators. **They overlap more than
their websites suggest**: every one of them sends HTTP requests, times the answers and reports
percentiles. What separates them is how a test is written, which load model comes easily, and how
a run says *fail*.

| | the test is | runs on | load model it writes most easily | pass or fail |
|---|---|---|---|---|
| JMeter (lesson 4) | an XML plan, built in a window | Java | closed: threads that loop | assertions per response; a percentile verdict is added on top |
| k6 (lesson 5) | JavaScript | one Go program | either: `constant-vus` or an arrival rate | `thresholds`, exit code 99 |
| Gatling (lesson 6) | Java, Kotlin, Scala or JavaScript | Java, through Maven | open: users a second, with a closed form | `assertions`, the build fails with exit code 1 |
| Locust (lesson 6) | Python | Python | closed: users that loop with a wait | written in a hook that sets the exit code |
| Artillery | YAML, with JavaScript for logic | Node.js | open: arrivals a second | `ensure`, exit code 1 |
| Vegeta | one line per request, and flags | one Go program | open, and nothing else | none built in; the report is read, or parsed |

## Reading the table

**Pick by who writes and reviews the test.** JavaScript, Java, Python and YAML each have an
audience on a given team, and a load test the team cannot read is a load test that stops being
maintained. JMeter's window helps somebody who does not program, at the price of a file nobody can
review.

**Pick by the model the requirement names.** A requirement in requests a second wants an open
model; k6's arrival rates, Gatling, Artillery and Vegeta write one directly. A requirement in
people with the page open wants a closed one; Locust, JMeter and k6's looping users write that.

**Pick by what the pipeline needs.** Three of the six, k6, Gatling and Artillery, turn a threshold into an exit code with no
extra code at all. Locust needs a few lines, as lesson 6 showed. Vegeta needs a script around it,
for example `vegeta report -type=json` read by `jq`, and that is a fair price for the one tool
here that cannot be talked out of its rate.

**And keep two of them, not six.** A team with one code-based tool for the journeys and Vegeta
for the single question "does this endpoint hold this rate" covers almost everything this part of
the course asks. Lesson 8 takes the numbers these tools print and asks which of them to believe.
