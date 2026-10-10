---
title: Exceptions, adoption and retiring a standard
version: 1
---

There are two common ways to get exceptions wrong, and they point in opposite directions. A standard
with no way to ask for an exception does not stop exceptions: they still happen, in code nobody
mentions, and the standard loses its authority the first time somebody notices. A standard with an
easy, informal exception, granted in a corridor, becomes a suggestion. **The way between is to treat
an exception as a small decision with a reason, a date and an owner**, and to read the list of them
as evidence about the standard.

## Asking

The exception printed by the checker in the previous section started as a request from Bruno Farias.
Payments needed the photo of the delivery proof to attach it to the shipper's invoice. Tracking's
`api.py` did not offer it; Tracking's `models.py` had it in a class called `DeliveryProof`. Tracking
had the change on its plan for February, and doing it sooner would have pushed back the live
position feed promised to shippers.

Carreto's request is five questions, answered in a short ticket that the owner of the standard
reads:

1. Which standard, by its wording in the list.
2. What you want to do instead, as precisely as a diff: `invoice.py` imports
   `carreto.tracking.models`.
3. Why the standard cannot be met now, and what meeting it would cost.
4. Until when, as a date, and what happens on that date.
5. Who closes it: a person, not a team.

Bruno's answers fitted in eight lines. The cost of meeting the standard now was a delay to somebody
else's commitment; the date was 31 March 2027, a month after Tracking's planned change; and the
person closing it was Ícaro Nunes, the junior developer on Payments who had written `invoice.py`.
Putting a junior name on the follow-up was deliberate: Ícaro would talk to Tracking about what the
new `api.py` function should look like, which is a better lesson in boundaries than reading the
standard.

## Granting

The owner of the standard decides, and for the import rule that is Renata. She asks three
questions of her own:

- Is the damage contained? One file reads one class and writes nothing back. If Tracking renames
  `DeliveryProof`, one import breaks in a place everybody can see, which is very different from the
  payout job breaking silently on a Friday.
- Is there a real date? "When Tracking has time" is not a date. A month after a change already
  on Tracking's plan is.
- Is there a person? An exception owned by "Payments" is owned by nobody when the date arrives.

Granted, the exception goes **where the check reads it**: the `EXCEPTIONS` entry in
`check_imports.py`, added in a pull request that links to the ticket. That placement matters more
than it looks. An exception recorded in a spreadsheet beside the code can expire while the code goes
on doing the excepted thing; an exception recorded in the check expires by itself, because on the
day after its date the build goes red. **Nobody has to remember an exception the build remembers.**

Carreto set two limits on top: **an exception lasts at most six months, and it can be renewed once.**
After a year, either the code meets the standard or the standard changes. An exception renewed four
times is not an exception. It is a second standard that nobody wrote down.

## What the list of exceptions tells you

In the first six months after the nine standards were published, the owners received 11
requests. They granted 8 and refused 3; each refusal came with a cheaper way to meet the
standard, such as reading a value through an existing `api.py` function the requester had not found.

Of the 8 granted, 4 were closed before their date by fixing the code, 2 were renewed once, 1 is
Bruno's and still open, and 1 changed a standard. That last one was a nightly job in Payments that reconciles payouts
with the bank partner's statement. It asked to be let off `/healthz` and `/metrics`, and the reason
was good: a job that runs for twenty minutes at 2 a.m. and then exits has no requests to report on
and nothing for a health check to probe. The request showed that the standard had been written with
web services in mind. Paula rewrote it as two rules, one for services and one for scheduled jobs,
which report how each run ended to the job monitor.

**Several exceptions against one standard are a finding about the standard, not about the teams.**
The rule was written against a picture of the system, and the requests are the places where the
picture was wrong. An owner who refuses all of them protects the wording and loses the people.

## Measuring adoption

A standard has been adopted when the code follows it, not when it has been announced. The measure is
the same check that enforces it, run across everything and counted, plus the exceptions still open.
At the six-month review Renata's table had a row per standard; four of them looked like this:

| standard | complying | open exceptions | six months earlier |
|---|---|---|---|
| `/healthz` and `/metrics` (services) | 14 of 14 services | 0 | 9 of 14 |
| no personal data in log lines | 13 of 14 services | 1 | not measured |
| deployed by the shared pipeline | 13 of 14 services | 1 | 11 of 14 |
| imports through `api` modules (the monolith) | 6 left in the baseline | 1 | 23 in the baseline |

Two things in that table are worth copying. **The last column is what makes it a measurement**:
without a starting point, 13 of 14 could be progress or decline. And the row that says "not
measured" six months earlier is honest about when the log scanner was switched on, rather than
pretending the number had always been known.

Measure the cost of a check as well as its coverage. A check that fails a build for the wrong reason
teaches people to rerun the build without reading the message, and after a few false alarms it
stops being read even when it is right. Carreto counted the builds each check failed and how many of
those failures were wrong; the log scanner's first version flagged every eleven-digit number as a
CPF, including order references, and was fixed in its second week.

## Retiring a standard

Standards pile up if nothing takes them away. That is how the wiki page reached 61. **A standard
should go when its reason has gone**, and the reason column from the first section of this lesson is
what makes that question quick to answer.

Before the nine, Carreto had a rule from 2019: every HTTP call between services goes through an
internal client library, `carreto-http`. Its reason was good at the time: the library added retries
and a request id to every call. By 2026 the service template configured retries and tracing for
every service, the library's only maintainer had left, and teams were keeping an unmaintained
dependency to satisfy a rule whose purpose was being served elsewhere.

Retiring it took three steps, and none of them was deleting a line from a page:

1. Announce a date, and say what replaces the rule: the template's retry and tracing settings.
2. Remove the check on that date, so that no build fails for a rule that no longer exists.
3. Mark the ADR that introduced it as superseded (lesson 5), pointing at the new one, so that
   somebody who finds `carreto-http` in an old service can tell why it is there and that it can go.

Before removing a rule whose reason is not written down, find out why it was made. That is
G. K. Chesterton's fence: a fence across a road whose purpose you cannot see is not proof that it
has none. The reason column exists so that this investigation takes a minute instead of an
afternoon.

Carreto now reviews the list every six months. Each owner says, for each of their standards, keep,
change or retire, and the answer goes in the same ADR log as every other decision. **The list stays
at nine because something leaves whenever something arrives**, and that turnover is the sign that
the standards still describe the system people are building.
