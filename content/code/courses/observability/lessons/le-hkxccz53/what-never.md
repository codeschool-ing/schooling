---
title: What must never be written
version: 1
---

A log is the most widely read thing a system produces. It is copied to a shipper, a store, a backup
and often a vendor; it is read by every developer debugging and every operator on call; it is kept
for days or months; and nobody reviews it line by line. **Anything written to a log should be
assumed readable by everybody with access to any of those places, for as long as the longest
retention.** From that, the list writes itself:

| never in a log | because |
|---|---|
| passwords, even wrong ones | a wrong password is usually a right password with a typo |
| tokens, session cookies, API keys, `Authorization` headers | whoever reads the line can act as their owner until the token expires |
| full card numbers and security codes | the card industry's own rules (PCI DSS) forbid storing them in places like this |
| documents and identifiers of a person: CPF, RG, passport | personal data that identifies somebody directly |
| health, religion, union membership, ethnic origin, sex life | *sensitive* personal data in the LGPD, with stricter rules still |
| the body of a request or response, in full | it carries all of the above sooner or later |

The LGPD, Brazil's general data protection law, is the frame that matters for the people this
course is written for. It does not forbid logging personal data; it requires a purpose, the minimum
necessary for that purpose, security proportionate to the risk, and the ability to answer a person
who asks what is held about them or asks for it to be deleted. **A log full of personal data fails
all four at once**: its purpose was debugging, it holds everything, it is read by many, and the next
sections show how hard it is to take back.

What a log should carry instead is **an identifier that means nothing outside the system**: an order
id, an account's internal id, a trace id. Those let an investigation find everything it needs in the
system that owns the data, under that system's access controls, without the log becoming a second,
unguarded copy.
