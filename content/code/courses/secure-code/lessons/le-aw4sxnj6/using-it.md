---
title: Using ASVS in a project
version: 1
---

A standard of 345 requirements is used one level and one section at a time. Here is the routine
that fits a team the size of Vereda's, one developer and a part-time operations person.

### 1. Choose the level, and write it down

Level 2, for the reasons in the first section: the portal holds health data. Record the choice in
the repository, with who decided and when. It is the promise the rest of the work measures itself
against.

### 2. Turn the level into a checklist that lives in the repository

Export the requirements of the chosen level from the CSV into a file the team keeps beside the code, one line per requirement, with a status: `met`, `not met` or `not applicable`. For each one that is met, the line says **where the evidence is**: a test name, a configuration file, a lesson-19 check.
A requirement marked met with no evidence is a belief, not a status.

### 3. Work through it by section, in order of risk

Not alphabetically. Start where a failure would expose other people's data: authorisation (V8),
sessions (V7), validation and encoding (V1, V2). The five questions of lesson 18 are a reasonable
order.

### 4. Make each requirement a test where you can

V2.2.2, that client-side validation is never relied upon, became lesson 3's tests that post
straight to the route. V7.4.1, that a terminated session cannot be used, is a test that signs out
and replays the old cookie. Some requirements are about documentation or process and become a
document instead; most of the level 1 and level 2 requirements about code can become tests.

### 5. Keep it current

A checklist goes stale the way pins do. Review it when a feature lands in a section it covers, and
when a new version of ASVS is released: 5.0.1 is the next planned, and the project's own repository
says so.

::: track devsecops
In your track, `threat-modeling` comes next, and it works on this same portal from the other end:
before the code exists, it asks what can go wrong, and ASVS is one of the sources it maps threats
to. After it, `secure-pipeline` puts lesson 19's checks into a pipeline.
:::

::: track security
In your track, `networks-security` comes next. The application is one layer of what is defended;
the network around it is the next.
:::

::: track *
The `threat-modeling` course works on this same portal from the other end: before the code exists,
it asks what can go wrong, and ASVS is one of the sources it maps threats to.
:::
