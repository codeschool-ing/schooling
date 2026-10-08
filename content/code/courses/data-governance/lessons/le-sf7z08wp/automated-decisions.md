---
title: Decisions no person made
version: 1
---

Three laws now have something to say when a machine decides something about a person.

**GDPR, article 22.** A person has the right **not to be subject to a decision based solely on
automated processing**, including profiling, which produces legal effects on them or similarly
significantly affects them. It is allowed only when necessary for a contract, authorised by law, or
based on explicit consent — and in the first and last case, the controller must provide at least the
right to obtain **human intervention**, to express a point of view and to contest the decision.
Articles 13 to 15 add the right to **meaningful information about the logic involved**.

**LGPD, article 20.** Lesson 7: the right to ask for a **review** of a decision taken solely on
automated processing, and for information on its criteria. Since the 2019 reform the law does not say
the review must be human.

**AI Act, article 86.** A person affected by a decision a deployer took on the basis of a high-risk
system's output, with legal or similarly significant effects, may ask for **a clear and meaningful
explanation of the role of the system** in the decision and of its main elements. It is tied to the
high-risk systems of Annex III.

## Where the three differ

The GDPR starts from a prohibition with exceptions; the LGPD starts from a permission with a right to
review. The GDPR's exceptions require a human who can intervene; the LGPD, after 2019, does not. And
the AI Act's right is about a narrower set of systems, but asks for something the other two do not
quite: what part *the system* played, which is a different question from what the criteria were.

For Ipê's `fraud-score`, cancelling an order on the model's word alone is a decision with a
significant effect. In Lisbon, article 22 makes Ipê offer a person who can look at it again. In São
Paulo, article 20 makes Ipê review it on request and explain the criteria. The simplest design that
meets both is the GDPR's: **a person reviews every cancellation before it is final** — which also
happens to be the design where a wrong model is noticed first.

## What it asks of the data

Explaining a decision months later needs the decision **recorded as it was made**: which model version,
which inputs, what score, what threshold, what the outcome was, and who reviewed it. That is an
append-only table of decisions, the same shape as lesson 7's consent events and lesson 10's audit
trail. A model that is retrained every week and whose old versions are deleted cannot explain anything
it did last month.
