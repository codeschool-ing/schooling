---
title: Where it breaks, and on whose side
version: 1
---

**Most cloud incidents start above the line, in a setting the customer chose. A few start below it,
and those you cannot prevent, only detect.** Both halves of that sentence change what a security
engineer spends time on.

## The customer's side, most of the time

In 2019 Gartner predicted that **through 2025, 99% of cloud security failures would be the
customer's fault**. It was a forecast and not a count, and nobody published the tally afterwards, so
treat the number as an opinion from people who see many incidents. The direction is what holds up:
the failures that fill the news are the ones this course has a lesson for.

| what went wrong | which row | lesson |
|---|---|---|
| a bucket answering anybody on the internet | data, and who can reach it | 9 |
| a key copied into a repository or a laptop, and still valid | identity and access | 7 |
| a user or role allowed far more than its job | identity and access | 6 |
| a network rule open to the world on an administrative port | virtual network | 8 |
| a machine never patched | operating system | 3 |

**Capital One, 2019**, is the case usually cited, and it sits entirely on the customer's side. A web
application firewall the bank ran on its own machine in AWS was misconfigured. Through it, an
outsider obtained the temporary credentials of the role that machine carried, and that role could read
storage holding the data of about 100 million credit card applicants in the United States and some 6
million in Canada. Two of the bank's own settings combined: a firewall that could be talked into making
requests for strangers, and a role allowed to read far more than the firewall needed. The provider's
half did what it promised throughout. Lesson 6 is about the second setting, and its idea is the one
that would have limited the damage.

## The provider's side, sometimes

The line does not make the provider infallible, and the clearest recent case is Microsoft's. In
**2023**, an intruder used a stolen Microsoft signing key to forge sign-in tokens and read e-mail
held in Exchange Online by about twenty-five organisations, United States government agencies among
them. No customer setting caused it, and no customer setting could have prevented it: the key, the
signing service and the token checks were all below the line.

**What found it was above the line.** The US State Department noticed mail being read in a pattern
that did not fit its own users, in audit records it had chosen to collect, and reported it to
Microsoft. That is the most a customer can do about a failure in the provider's half, and it is a
real thing to do: **you cannot fix the provider's half, but your own logs are often how anybody
learns that it broke.** Lesson 15 is about keeping those records.

## What follows for your time

Spend it in proportion. The provider's half gets a reading of its report, a contract that says how
it will tell you about an incident, and logs of your own that would show its failure. Your half gets
everything else: the inventory, the settings, the permissions, the proof, because that is where the
evidence says the incidents start.
