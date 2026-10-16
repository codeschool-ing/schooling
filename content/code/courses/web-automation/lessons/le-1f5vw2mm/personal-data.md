---
title: Test data is never somebody's real data
version: 1
---

**The data in a test suite is generated, never copied from production.** It is tempting to do the
opposite. Production has realistic names, addresses with accents and apostrophes, orders with
strange histories, everything a generated customer lacks. The usual request is *a copy of
yesterday's database for the test environment*, and a tester who asks for it means well. It is
still the wrong request, for three reasons that do not depend on how careful anybody is.

## Why a copy is a leak waiting to happen

**Test data travels.** Everything this course has produced so far shows where. A failed
Playwright test leaves an error context in `test-results/`, the page as it was; lesson 16 adds
screenshots, videos and traces, which record every request and every field typed. A build server
keeps those as artefacts, attached to a run that a whole team can open, and a defect report quotes
them. A real customer's name in a test is a real customer's name in each of those places, kept for
as long as anybody keeps them.

**Test environments are less protected than production**, on purpose: more people can read them,
logins are shared, and nobody pages anybody at night when one is exposed. The protections put
around production data stop at the copy.

**And the law does not distinguish.** In Brazil the LGPD, the general data protection law (Lei
13.709/2018), governs any processing of personal data, and copying a database is processing.
Testing an application is not one of the purposes its customers agreed to when they gave their
data, and the obligations that come with the data, keeping it to what is necessary, keeping it
safe, deleting it on request, follow it into the test environment. Europe's GDPR says the same, and
so do the laws of most countries that have one. Whether a particular copy could ever be lawful is
a question for whoever answers for data protection at your company, and the tester's default
answer is not to make it.

Where a team truly needs production-shaped data, the answer is **anonymisation**: replacing what
identifies a person, in a way that cannot be reversed, before the data leaves production. Doing it
properly is harder than replacing the name column, because a birth date, a postcode and a job title
together often identify one person. That is `manual-testing` lesson 20's subject, and it is not
repeated here.

## What generated data looks like

Everything this lesson created was generated: `maria-` and a random tail, `joao-` and a random tail.
That is enough for most automated tests, and when a test needs more realism, generate that too:

- **names with the hard characters**: `Conceição`, `D'Ávila`, `Nguyễn`, a name of one letter and a
  name of eighty. A form that breaks on an apostrophe breaks for real customers, and a generated
  list can hold every awkward case on purpose, where a copy holds them by chance;
- **e-mail addresses at domains reserved for examples**: `example.com`, `example.org` and
  `example.net` are set aside by the internet's standards bodies and deliver to nobody. A test that
  sends a welcome e-mail to `maria-3f1c7a02@example.com` cannot reach a stranger's inbox; one that
  uses a plausible address at a real provider may;
- **documents that are clearly fake.** A CPF has check digits, so a form validates it, and a
  generator that produces valid ones can produce somebody's real number. Prefer the values the
  development team publishes for tests, or a validation switched off in the test environment; never
  a number that came from a person.

Libraries exist that generate realistic names, addresses and companies in many languages; Faker,
in its JavaScript form `@faker-js/faker`, is the common one. It was not installed for this course,
because a prefix and a UUID did everything these tests needed, and every dependency is one more
thing to keep up to date. If a test needs varied realistic data, it is a reasonable choice; fix its
seed with `faker.seed()` so a failing run can be reproduced with the same data.

## The tester's rule

When you meet real personal data in a test environment, or in a fixture somebody committed, the
right move is the same as for a defect: report it to whoever owns the environment, and do not copy
it further, including into the report. A sentence such as *the users table in staging holds what
look like real customers' names and CPFs* is enough, and pasting one of them as proof makes one
more copy.
