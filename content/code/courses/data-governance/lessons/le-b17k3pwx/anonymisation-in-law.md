---
title: What the law calls anonymous
version: 1
---

Brazil's LGPD gives anonymisation a definition with two halves, and both matter for a data team.

**Article 5, III** defines anonymised data as data about a person *who cannot be identified,
considering the use of reasonable technical means available at the time of the processing.*
**Article 5, XI** defines anonymisation as the use of those means *by which data loses the
possibility of association, direct or indirect, with an individual.*

**Article 12** draws the consequence: anonymised data is **not personal data** for the purposes of
the law — *unless* the anonymisation is reversed using only the controller's own means, *or* it can
be reversed with reasonable effort. What counts as reasonable, its first paragraph says, has to
consider objective factors such as the cost and time needed to reverse it, given the technology
available.

Three things follow, and each one has a section of this lesson behind it.

**Anonymity is a property you measure, not a label you apply.** "Reasonable means available at the
time" is a test of what somebody could actually do. The MD5 pseudonyms of section 8 fail it in a
second; the release by birth date, sex and CEP fails it for 5,988 of 6,012 people. A team that
claims a dataset is anonymous should be able to show the measurement.

**It can stop being true.** "At the time of the processing" means a dataset anonymous today can become
personal data when a new dataset is published that it can be joined to, or when cheaper computation
makes an old reversal reasonable. Releases are re-examined, not certified once.

**Pseudonymised is not anonymised.** The definition in article 13, §4 — association is lost *except
with additional information kept separately by the controller* — describes exactly the data Ipê holds
the key to. Article 12, §2 adds that data used to build the behavioural profile of an identified
person can be treated as personal data too, which is where an analytics export of a pseudonym and
every purchase sits.

## What this means in practice

| what the team has | what the law sees | what still applies |
|---|---|---|
| masked or tokenised data | personal data | everything |
| pseudonymised data, key held by Ipê | personal data | everything; lower risk is an argument in a risk assessment (lesson 7) |
| counts with small cells suppressed, measured | very likely anonymous | nothing for the published counts, while the measurement holds |
| "anonymous" rows nobody measured | personal data until shown otherwise | everything, plus a false statement in a privacy notice |

The safe default is the last line's opposite: **treat everything as personal data until a
measurement says it is not**, and keep the measurement with the release.
