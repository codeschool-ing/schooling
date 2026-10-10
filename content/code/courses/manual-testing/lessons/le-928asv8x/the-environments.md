---
title: Development, test, staging and production
version: 1
---

The usual picture of a test environment is a server: the machine the application runs on while
somebody tests it. **An environment is everything the application runs on and talks to**, and the
machine is only the first item. The version of Python, the operating system and its settings, the
clock and its time zone, the data in memory, the mail server, the variables the program was started
with, and the browser on the other end all belong to it. Change any one of them and you are testing
in a different environment, whether or not anybody gave it a new name.

Lesson 1's plan already had a row for this. Its question "who, and with what?" named the machines,
the browsers, the data and the accounts, and it listed the outbox as the thing that stands in for a
mail server. This lesson is about why that row matters.

## The four, and what each one is for

Most teams keep four environments, and the names are close to universal even when the machines
behind them are not:

| environment | who uses it | the build | the data | e-mail |
|---|---|---|---|---|
| **development** | one developer, on their own computer | whatever they are writing, minute by minute | whatever they typed | rarely sent at all |
| **test** | the testers | a known build, installed on purpose | prepared test data, reset at will | caught, never delivered |
| **staging** | testers and the client, before a release | the release candidate | shaped like production, anonymised | caught, or sent to a few internal inboxes |
| **production** | the real customers | the released version | real | delivered to real people |

**Development** changes too often to test in: by the time a defect is written up, the code it
describes has moved. **Test** is the environment this course has been using all along. Your copy of
boxoffice is a known build, `/health` names it, a restart resets it, and the outbox keeps every
e-mail from leaving the machine. **Staging** exists for one reason: to be as close to production as
anything can be without being production. Same operating system, same configuration, same version
of everything, data with the same shape, and the same settings on the machine. A pass in staging is
worth something exactly to the degree that staging resembles production.

**Production is not a test environment**, with one exception. After a release a
tester runs a short smoke check there (lesson 8), with an account kept for the purpose, because some
things exist nowhere else: the real mail server, the real domain, the real card machine. Lesson 1's
plan left "the real mail server" out of scope for exactly that reason, to be checked once in
production, by a person. Everything else is tested before, because a defect found in production has
already reached a customer.

## Why four and not one

Each step along the row removes a difference from production. That is the whole point of having
more than one, and it explains the failures you meet when a team skips a step.

A defect that depends on a difference shows only in the environments that have that difference.
The commonest ones are dull: a different version of the language, a setting nobody copied across, a
time zone, a locale that writes `1.234,50` where another writes `1,234.50`, an account that exists
in one database and not in another. **None of them is visible in the code**, because the code is the
same file in every environment. boxoffice shows how much depends on the variables a program starts
with: `BOXOFFICE_PORT` moves it to another port, `BOXOFFICE_NOW` moves its clock, and
`BOXOFFICE_SEED` changes every confirmation link it sends. One file, three settings, and each
setting is part of the environment.

## The theatre's environments

For boxoffice the arrangement is small enough to hold in your head. Rui writes the code on his
laptop, which is development. You run each build on yours, which is test. The theatre runs the real
ticket office on a rented Linux server in a data centre, which is production, and before a release
Rui installs the candidate on a second rented server of the same kind, which is staging.

**Both rented servers keep their clocks in UTC**, the way rented servers very often come. Rui's
laptop and yours are set to São Paulo time, like everybody's in the building. Nobody chose that
difference and nobody wrote it down, because nobody thought a clock was part of the application.
The next section is what it costs.

## Parity, and its price

The word teams use for "staging resembles production" is **parity**, and it is never perfect.
Production has real customers' data and staging must not (lesson 20 is about anonymising it).
Production sends real e-mail and staging must not (lesson 22). Production may run on ten machines
and staging on one. Each of those gaps is a decision, and the right place to record it is the test
plan, next to the reason, so that a defect hiding in one of them is a known risk rather than a
surprise.

The gaps nobody decided are the dangerous ones. A test plan cannot list a difference that nobody
noticed, and that is why a tester's first question about a defect that "only happens there" is
always the same: **what is different there?**
