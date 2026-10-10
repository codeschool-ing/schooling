---
title: Principles, standards and guidelines
version: 1
---

A standards document is easy to picture as a long list that makes everybody's code look the same.
**A standard is a decision made once so that nobody has to make it again**, and it is worth exactly
what it prevents. A list of sixty of them prevents nothing, because nobody can hold sixty rules in
their head while writing code on a Thursday afternoon.

Renata found Carreto's list in her second month as architect. A wiki page called *Engineering
standards*, last edited in 2020, carried **61 rules**. She asked the seven tech leads to write down,
from memory, the standards their teams followed. Nobody named more than five, and no two lists
agreed. Some of the 61 described a Jenkins server switched off two years earlier. One said that every
new service was written in Flask, while three of the newest were FastAPI and nobody had been told
they were breaking a rule. The page was not a standard. It was a record of what somebody had once
hoped.

## Three words, three strengths

The page mixed three kinds of statement that do different jobs, and separating them was the first
thing Renata did.

| | what it is | how strong | Carreto example |
|---|---|---|---|
| **principle** | a direction to reason from when no rule covers the case | not checkable by itself | Money moves through Payments and nowhere else. |
| **standard** | a rule with a yes-or-no answer | **must** | A team's package imports another team's package only through its `api` module. |
| **guideline** | advice that leaves room for judgement | **should** | Prefer PostgreSQL for new storage. |

The words *must* and *should* carry the same weight they have in RFC 2119, the 1997 document
that fixed how internet standards use MUST, SHOULD and MAY. A **must** has no "unless": breaking
one needs an exception that somebody grants, which is the subject of the last section of this lesson. A
**should** expects the reader to follow it and accepts a different choice with a reason written down
beside it, in a pull request or an ADR (lesson 5).

**A principle is where standards come from, and it is not a standard itself.** "Money moves through
Payments" cannot be checked line by line, but it produces rules that can: Shipper does not write to
the payouts table, and nothing outside Payments calls the bank partner. When a case comes up that no
standard covers, the principle is what people argue from.

The test that sorts one from another is a single question: **can a machine, or any reviewer, answer
yes or no?** "Code should be clean" fails it, so it is at most a guideline, and a weak one. "No CPF
number appears in a log line" passes it, so it can be a standard. A rule that fails the test but is
written with *must* produces arguments in review, because two reviewers read it two ways.

## Few, each with a reason and an owner

Renata cut the page to three piles. 38 rules were deleted: they described tools that no longer
existed, repeated something the language or the framework already enforced, or nobody could say why
they were there. 14 became guidelines. **9 stayed standards.** Nine is a number a tech lead can
recite, and that is the point of it.

Every one of the nine carries the same four facts: the rule, the reason, the owner and how it is
checked.

| standard | reason | owner | checked by |
|---|---|---|---|
| A team's package imports another team's package only through its `api` module | the payout failure of March 2026 | Renata Okubo | a script in CI |
| Every service exposes `/healthz` and `/metrics` | on-call cannot see a service that has neither | Paula Reis | the deploy pipeline |
| No CPF, phone number or bank details in a log line | LGPD; logs are kept for 90 days and read by many people | Paula Reis | a log scanner in staging |
| Money is an integer number of centavos, never a float | rounding took cents off driver payouts in 2021 | Bruno Farias | a type check on amount fields |
| A quote is checked against the ANTT floor only by Pricing's service | two copies of the floor table disagreed for a week | the Pricing tech lead | a contract test |
| Every service is deployed by the shared pipeline | the pipeline is where the other checks run | Paula Reis | only the pipeline holds production credentials |
| Secrets live in the secrets manager, never in the repository | a token was committed and found by a stranger | Paula Reis | a secret scanner in CI |
| A change to a public API is backwards compatible or versioned | the Driver app cannot be updated on every phone at once | Renata Okubo | a schema comparison in CI |
| A decision that crosses team boundaries has an ADR | lesson 5 | Renata Okubo | the architecture forum |

**The reason is the column that keeps a standard honest.** It is what lets a tech lead judge whether
an exception makes sense, and it is what tells somebody in 2029 whether the rule is still needed. A
rule whose reason nobody can state is a rule nobody can defend in a review, and it gets ignored the
first time it is inconvenient.

**The owner is a person, not "architecture".** Renata owns three of the nine. Paula owns four
because Platform runs the pipeline and the logs; Bruno owns the money rule because Payments is where
a wrong centavo hurts. The owner answers questions about the standard, decides exceptions to it and
proposes retiring it. An architect who owns every standard has made herself the bottleneck that
lesson 17 calls the gatekeeper. Her job is to keep the list short and coherent, not to hold every
line of it.

The first row has a story. In March 2026 the Matching team split a module called `offers.py` in two.
Nothing in Matching's own code broke. But Payments' payout job had been importing a function
straight out of `offers.py`, because it was the quickest way to find out which driver had accepted a
load, and on the Friday after the change the payout run failed. **312 drivers were paid on Monday
instead of Friday.** Nobody in Matching knew Payments depended on that file, and nothing could have
told them. The next section builds the check that would have.

## Where standards come from

A standard written from taste starts an argument. One written from evidence ends one. Carreto's nine
came from three places, and the same three are worth looking for anywhere:

- an incident whose cause was a structural choice, like the payout failure;
- a review comment made three times. When the same remark appears on three pull requests from
  three teams, it is a candidate standard, and writing it down saves the fourth reviewer the effort;
- an obligation from outside: the LGPD for the log rule, the ANTT floor for the quote rule.

How a standard gets adopted follows lesson 3's advice process. Renata drafts it with its reason and
how it will be checked, asks the tech leads who will live with it and Paula, who will run the check,
and records the decision and the advice she received in an ADR. A standard nobody was asked about
is one everybody feels free to work around.

## The paved road

A standard that takes effort to follow is followed by careful people and skipped by people in a
hurry, which on a bad week is everybody. **The cheapest way to get a standard obeyed is to make
obeying it the default.**

Paula's team maintains a service template. A service started from it already exposes `/healthz` and
`/metrics`, masks CPF numbers in its logs, reads its secrets from the secrets manager, and is wired
into the shared pipeline, with the schema comparison for its public API already in its CI. **Five of
the nine standards are met on the first day, by somebody who has read none of them.** Netflix called
this a paved road and Spotify a golden path; `tech-strategy` lesson 14 covers how a platform team
builds one and keeps it maintained.

Leaving the road is allowed. A team that does not start from the template takes on what the template
would have given it, and still owes the nine. That changes what a standard is in practice: less a
rule people remember, more a road that leads somewhere useful, plus a short list of what you must
still do if you step off it.
