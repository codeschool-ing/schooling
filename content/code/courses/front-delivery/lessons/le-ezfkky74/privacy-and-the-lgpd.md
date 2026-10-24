---
title: Privacy, and the LGPD
version: 1
---

**An error report is data about the person whose browser sent it, and in Brazil the LGPD, the Lei Geral
de Proteção de Dados (law 13.709 of 2018), says what is owed to them.** Personal data, in the law, is any
information about an identified or identifiable person. A report with an e-mail address in it is personal
data plainly. A report with none can still be, once it is put beside the address it came from: the
collector receives every request's IP address whether it keeps it or not.

This section is the defender's side of that, for a developer who decides what a page sends. It is not
legal advice, and a product that collects reports from real users should have its privacy notice
reviewed by somebody who gives it.

## The principles, applied to a report

Article 6 of the LGPD lists the principles every processing of personal data follows. Four of them
decide most of what an error report should be:

- **Purpose** (*finalidade*): the reports exist to find and fix faults, and are used for nothing else, not
  for analytics and not to follow a person around the product.
- **Necessity** (*necessidade*): only what that purpose needs. That is the previous section's rule:
  `pathname` and not `href`, no field values, no user id. A report that would need to know who the person
  is, to contact them, is a support request, and asks first.
- **Transparency** (*transparência*): the privacy notice says that error reports are collected, what is in
  them, who receives them and for how long they are kept.
- **Security** (*segurança*): the reports are kept where only the team can read them, the collector refuses
  what it does not expect, and the source maps stay private.

## A legal basis, and a time limit

Every processing needs one of the legal bases in article 7. For reports kept to keep a service working,
**legitimate interest** is the one usually considered, and it requires weighing the team's interest
against the person's expectations and rights, and writing that weighing down. Consent is the other way,
and a page that asks for it must work just as well when the answer is no.

Reports should also be deleted once they stop being useful. A rule such as *ninety days, then the file is
deleted* is easy to state in the notice and easy to follow; the collector in this lesson keeps everything
forever, which is fine on one laptop and wrong anywhere else.

## Where the reports go

A hosted service is a company receiving the reports on the team's behalf: in the law's terms, an
*operador*, a processor, acting for the *controlador*, the team. Its servers are often outside Brazil,
and **sending personal data abroad is an international transfer**, which article 33 allows only in the
cases it lists, such as to a country the ANPD, the national authority, has recognised, or under contract
clauses it has approved. Services offer settings for this: the region where data is stored, scrubbing of
known kinds of personal data before it is kept, and switches that stop the SDK from sending IP addresses
and cookies at all. The next section shows the last of these in Sentry's configuration.

**The simplest protection is the previous section's: a report that carries nothing about the person is
hardly theirs to worry about.**
