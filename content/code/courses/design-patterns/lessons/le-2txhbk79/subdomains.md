---
title: "Subdomains: core, supporting and generic"
version: 1
---

**A business is several smaller businesses, and they do not deserve the same care.** DDD calls each
one a *subdomain* and sorts them into three kinds: the **core**, which is why the organisation exists
and where it differs from everybody else; the **supporting** ones, which it needs and nobody sells;
and the **generic** ones, which every organisation has and somebody already does well. The point of
the sort is where to spend the best people and the most design.

The mistake this prevents is treating the whole system as equally important. A team that applies
every pattern of lessons 11 and 12 to the screen that resets a password has spent its care where it
earns nothing. A team that builds its lending rules as quickly as its password screen has saved time
in the one place it could not afford to.

## The library's subdomains

| subdomain | kind | why | what to do with it |
|---|---|---|---|
| lending: loans, holds, renewals, fines | core | the rules the librarians argue about and tune; why members come to this library | build it in-house, with the full care of lessons 11 and 12 |
| catalogue: describing titles, subjects, search | supporting | needed and library-specific, but the same work every library does | build it simply, or adapt a tool; import records instead of typing them |
| acquisitions: ordering copies from suppliers | supporting | a few orders a month, a spreadsheet's worth of rules | a small module, or a form and a spreadsheet |
| sign-in, card and Pix payments, e-mail and SMS | generic | every organisation has them, and specialists do them better | buy or use a service; write only the glue |

**The core is small, and what defines it is difference.** Lending is a few hundred lines
in this course, fewer than the catalogue would need for a decent search. It is the core because a
rule change there, a longer loan for students or a grace day before fines start, is a decision the
library makes about itself. Nobody makes a decision like that about how a password is hashed.

The same reasoning tells you what not to build. Taking payment for a fine involves card networks,
Pix, refunds, chargebacks and regulation. A library that writes its own payment handling has spent
its effort on a generic subdomain, and will still do it worse than a provider that does nothing
else. **Generic means somebody else's core**: for the payment provider, payments are the core.

## Subdomains move

The sort is a judgement about the business today. Suppose the library decides that what will make
it different is recommendations: telling each member what to read next, based on what neighbours
borrowed. Recommendations were not on the table at all; now they are core, and they get the care. A
subdomain can also fall: if the city offers every library a shared catalogue, the catalogue becomes
generic overnight and the right move is to adopt it.

## Problem and solution

A subdomain is part of the **problem**: it exists whether or not anyone writes software. The next
section introduces the **solution** side, the bounded context, which is a boundary in the code.
They often line up one to one, and the library's do, but they are different things. One subdomain
can be split across two models, and one legacy system can cover three subdomains in one tangled
model. Keeping the two words apart is what lets you say what is wrong with such a system.
