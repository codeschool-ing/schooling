---
title: What an incident is, and how bad
version: 1
---

**An incident is an unplanned event that hurts the service's users, or will soon, and needs a
coordinated response.** The last three words are the definition's working part. A failing disk on one
replica that the next deploy will replace is a ticket; checkouts failing for every customer is an
incident, because several people will have to act together, quickly, and somebody has to make that
happen.

**Declare early.** Declaring costs a message in a channel and a few minutes of somebody's attention;
not declaring costs the hour in which three people investigate the same thing without knowing it, and
nobody tells support what to say. A declared incident that turns out to be small is closed with a
sentence. The habit that hurts is waiting to be sure.

Severity says how bad, and it is defined by **impact on users**, never by the cause or by how hard the
fix looks. The shop's levels:

| severity | impact | response |
|---|---|---|
| SEV-1 | most customers cannot buy, or data is being lost or exposed | everybody needed, now, at any hour; leadership informed |
| SEV-2 | a large share of customers affected, or one important path broken | on-call plus whoever they need, now; status page updated |
| SEV-3 | a minor feature broken, or a small share affected, with a workaround | on-call, during working hours |

Three rules keep the levels useful. **The severity can change**, up or down, as the picture becomes
clear, and changing it is not an admission of anything. **When in doubt, pick the higher one**: an
over-staffed incident costs an hour of a few people; an under-staffed one costs customers. And the
definitions are **written down in advance**, so the person deciding at three in the morning is
reading a table, not inventing one.

The error budget of lesson 15 connects directly: a burn rate that would empty the month in two days
is SEV-2 at least, whatever it turns out to be caused by.
