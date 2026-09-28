---
title: What they open first, in your field
version: 1
---

Across every field one rule holds: **a reviewer opens whatever is closest to the work they would give
you on your first week.** What that is differs a great deal from one field to the next. Below is the
part for your track; the choice beside it shows the others.

::: track frontend
**Front-end.** The live link, first, and often on a phone. Then the browser's developer tools: does it
load quickly, is the layout still sane at 320 pixels, can the form be used with the keyboard alone?
Only then the code, and there they look at how state flows and whether the loading, empty and error
states exist at all. A good project is **an interface to real data with every state designed**, not a
copy of a famous site that works only on the happy path.
:::

::: track mobile
**Mobile.** They will rarely install your app, so the first thing is **a short video on a real device**
and a way to try it if they want: a store listing, a test build, an APK. Then the screens: what happens
offline, how permissions are asked, whether it follows the platform's conventions. In the code they
look at state and navigation. A good project **does one job well on a phone**, with no network half the
time.
:::

::: track backend
**Back-end.** The README's API section, with example requests and the answers they get, errors
included. Then the tests, and whether the rule most likely to break has one. Then how it would run:
configuration, a migration, a health check. A good project is **a service with a real rule**, such as
something that cannot happen twice, and a clear account of what it refuses and why. loanbook is this.
:::

::: track ai
**AI engineering.** Not the chat screen. They look for **the evaluation**: a set of test inputs, what
counts as a good answer, and the results written down, before and after a change. Then cost and
latency, measured rather than guessed, and what the application does when the model's answer is
wrong or malformed. A good project **uses a model for one task and can show how often it gets it
right**.
:::

::: track prompt
**Prompt engineering.** The prompts, versioned like code, and **the test set they were measured on**.
A reviewer wants to see two versions of a prompt compared on the same inputs, the failures listed
rather than hidden, and the guardrail that handles the cases the prompt gets wrong. A good project
**takes one real task and documents how its prompt was improved**, with the numbers.
:::

::: track data
**Data engineering.** The pipeline, and the README's diagram of it. Then the questions that separate
a script from a pipeline: what happens when it runs twice, what happens when the source sends
something malformed, where the data-quality checks are. A good project **moves a real public dataset
on a schedule into something queryable**, and survives being run again.
:::

::: track data-science
**Data science.** The result first: a rendered report or notebook that states a question and answers
it. Then the method behind it: a baseline to beat, how the model was validated, what the numbers do
not show. A notebook of two hundred unexplained cells is read as a draft. A good project **answers one
specific question with honest limits**, and runs again from a clean environment.
:::

::: track bi
**Business intelligence.** The dashboard, through a public link or clear screenshots. Then the
definitions: what exactly each metric counts, where the data comes from, and which decision the
dashboard is meant to support. A good project **answers a question somebody in a business would ask**,
with metrics defined in writing and one page, not twelve.
:::

::: track devops
**DevOps and SRE.** The pipeline file, and what it does from a commit to something running. Then how
the running thing is watched: a health check, a metric, an alert that fires. A recording of a deploy,
and better still of a failed one rolled back, says more than a diagram. A good project **deploys a
small workload repeatably and notices when it breaks**.
:::

::: track devsecops
**DevSecOps.** The pipeline, and specifically its security gates: dependency scanning, secret
scanning, static analysis, and what the build does when one of them finds something. They look for
**a finding that was triaged**: fixed, or accepted with a written reason. A good project **puts
security checks in a real pipeline and shows one finding handled end to end**.
:::

::: track cloud-engineering
**Cloud engineering.** The infrastructure as code, and an architecture diagram that matches it. Then
the notes around it: what it would cost to run, and how it is torn down. A reviewer checks that
nothing is created by hand. A good project **builds a small architecture from code, documents its
cost, and destroys cleanly**, so it never becomes a bill.
:::

::: track it-support
**IT support.** Documentation, first: a runbook somebody else could follow, with screenshots. Then
evidence that the environment behind it works: users and permissions set up, a backup, and above all
**a restore that was tested**. A good project **is a small office environment you built in a lab and
documented well enough that a colleague could rebuild it**.
:::

::: track networks-infra
**Networks and infrastructure.** The topology diagram, and the configurations under version control.
Then the tests: reachability between segments, what happens when a link goes down. A good project **is
a lab network built from configuration files, with a diagram and a test that proves it fails over**,
all reproducible by someone else.
:::

::: track dba
**Database administration.** The write-up of an investigation: a slow query, the plan before and
after, the index or rewrite that fixed it, measured. Then the procedures: a backup, and a restore
that was actually performed. A good project **is a real schema under realistic data, with one
performance problem found and fixed on the record**.
:::

::: track qa
**QA.** The bug reports, first: clear steps, expected and actual result, evidence. Then the test
suite and a CI run of it, and the test plan that explains why those cases and not others. A good
project **tests somebody else's real application or API, finds real defects and reports them well**.
:::

::: track security
**Security.** A written assessment: scope, method, findings with severity and evidence, and what to
do about each. Everything is done **only against systems you are authorised to test**, such as a
deliberately vulnerable practice application in your own lab, and the report says so on its first
page. A good project **reads like a report a client could act on**.
:::

::: track *
**Whatever the field**, find out what it opens by asking two people who work in it, and by reading its
job adverts the way the next section describes. Then build the thing closest to a first week's task.
:::
