---
title: Leaving the group out does not remove the bias
version: 1
---

**Region was never one of the model's inputs.** The six it used were recency, orders in 90 days,
tenure, two channel columns and the plan. And still it treats the North differently, because recency
and the order count carry the region inside them: a slow rhythm is, in Panela's data, nearly a
signature of the North.

An input that carries a group's identity without naming it is a **proxy**. Proxies are everywhere,
and they are why the most common first response to bias, removing the sensitive column, rarely works.
Some familiar ones:

- **a postcode** carries income, and in many cities race;
- **a first name** carries gender, and often age;
- **the device** a customer uses carries income;
- **the time of day** a person shops carries the kind of job they have.

A model looking for patterns will find the group through its proxies whenever the group's outcomes
differ, and it will do so silently, with no column anybody can point to.

Leaving the group out has a second cost, and it is the less obvious one. **An analyst who drops
region from the data cannot run the audit of the previous section.** The column that must not decide
anything is the same column needed to check that nothing is decided by it. The usual practice is to
keep it beside the model, out of its inputs and in every evaluation.

Whether a group column may be an input at all is a separate question, with legal answers that vary by
country and by kind of decision. In Brazil the LGPD treats data revealing racial or ethnic origin,
religion, health and a few others as sensitive, with stricter rules for using it. Region is not on
that list, but the reasoning carries over: a decision that treats people differently because of where
they live needs a reason somebody is willing to defend.
