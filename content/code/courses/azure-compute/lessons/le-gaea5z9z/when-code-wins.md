---
title: When code wins, and when it does not
version: 1
---

Two opinions about Logic Apps circulate, and both are wrong in the same way. One says it is for
people who cannot program, so a team that can should write code. The other says that no code means
nothing to maintain, so it is always the cheaper choice. **Both judge the tool by who uses it,
when the question is what the job looks like.** A workflow that makes six calls a day to services
that already have connectors is a few lines of a definition and nothing else. A job that walks
thousands of records and decides something about each one is a program, wherever it is written.

The three developers at the shop can write either. Four properties of the job decide it.

## Can it be tested before it runs?

A function is code: lesson 15's `function_app.py` runs on a laptop in the Functions host, and a
test can call it with an order and check the receipt. **A Consumption workflow runs nowhere but in
Azure.** The first section measured what the laptop can check: the resource around the definition,
and nothing in it. A misspelt step and a misspelt function both compiled clean, so the earliest a
mistake in a workflow can be found is when it is deployed, and the latest is a run at six in the
morning, read afterwards in its history.

There is help, and it is partial. A definition can carry **static results**, kept under its key
`staticResults`: an action marked to return one of them gives a mock output instead of calling
anything, so a run can be tried without the shop's API. A Standard logic app has a local runtime,
run from Visual Studio Code with Microsoft's extension, which installs Azure Functions Core Tools,
.NET and Node.js for it; it can stop on a breakpoint inside `workflow.json`. This course uses
neither Visual Studio Code nor Core Tools, so that runtime is read, not run, here.

## Can a change be reviewed?

The definition is JSON, so it can live in git, and `daily-orders.bicep` is a file a pull request
can show. **Two things stay outside the file.** The designer is where most people edit a workflow,
and a change made there reaches git only if somebody exports it. The connection to Outlook was
authorised by a person signing in, and no diff records who, or when the token stops working.
Code has the same outside parts in principle, its secrets and its settings, but its logic is all in
the repository, and a reviewer can read a loop or a condition the way it runs.

## Loops and volume

**A workflow is billed and limited per step, and a loop multiplies steps.** Suppose the shop wanted
a line for each order rather than one CSV: a `foreach` over the orders, with three actions inside.
On a day of 2,000 orders, that is 2,000 × 3 + 1, so 6,001 executions in one run, where the
morning export needed six. The loop is also limited. By default 20 iterations run at once, at most
50, and a `foreach` takes up to 100,000 items in a stateful workflow. An `until` loop stops after 60
cycles or an hour unless told otherwise. Data operations such as `Select`, `Query` and `Table` do
a whole array in one action, which is why `daily-orders.bicep` builds its CSV with `Table` rather
than a loop.

A function that receives the same 2,000 orders reads them in one execution, and Python decides
how. When the work is a calculation over many records, code does it in one step that Logic Apps
would bill as thousands.

## Long-running work

A stateful Logic Apps run can last up to 90 days, and its saved state lets an interrupted run be
rebuilt after an outage. So does an orchestration in **lesson 17's Durable Functions**, written
in Python: an orchestrator that calls activities, fans out to many at once, waits for a timer or an
event, and rebuilds its place after a restart by replaying its history. The difference is not
durability. It is that one is a definition read in a designer and the other is code read in an
editor, tested by calling it, with every loop and condition in a language the team already knows.
When the steps are connectors and the decisions are few, the definition is shorter. When the steps
are the shop's own logic, the code is.

And when the job is not a sequence at all but a service that answers requests, it is neither: the
shop's own API is a container, and lessons 7 and 8 run it.

## The two can be mixed

A workflow does not have to do everything itself. Its **Function** action calls an Azure Function,
and *Execute JavaScript Code* runs a short snippet inline. A common division is that the workflow
holds the schedule, the connectors and the run history, and a function does the one step that needs
a loop or a library. Lesson 20's queues are the other common seam: a workflow posts a message, and
code takes it from there.

## The finance export

This lesson's own job comes out the other way.

| | the morning export |
| --- | --- |
| steps | a schedule, one HTTP call, a condition, a CSV, an email |
| executions | six a day |
| the hard part | sending mail from a company mailbox, which a connector already does |
| who reads it | finance, who can open the run history and see yesterday's CSV |
| what code would add | a function, its plan, a mail library, credentials to store, and somebody to deploy it |

**Nothing in that job is the shop's own logic.** It is plumbing between the shop's API and a
mailbox, run once a day. Written as a function, it is a timer trigger, an
HTTP client, a CSV writer and a mail library, plus a secret for the mailbox, all owned by three
developers whose time costs more than six executions a day. Written as a workflow, it is the file of
the first section and one connection, and the person who wants to know why Tuesday's email was
empty can find the answer without them.

The rule of thumb that falls out of this lesson, for lesson 21 to test against numbers: **reach for
Logic Apps when the steps are connectors and the runs are few, and for code when the steps are
yours, the data is large, or the logic needs tests.**
