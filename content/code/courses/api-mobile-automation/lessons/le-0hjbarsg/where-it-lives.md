---
title: Where a tester still meets it
version: 1
---

**SOAP is old and it is not gone.** Nobody starting a public API today chooses it, and a course
that taught only new APIs would leave you unprepared for the systems that move money and taxes.
Those were built in the 2000s, when SOAP was the standard way for two companies' programs to talk,
and they still work. Replacing a working integration that a regulator has approved costs more than
keeping it, so it is kept.

## Three places it lives

- **Government.** In Brazil, every electronic invoice for goods, the **NF-e**, is sent to the state
  tax office's web services as a SOAP message, and the invoice inside it is XML signed with a
  digital certificate. eSocial, the federal system where employers report their labour and tax
  obligations, takes signed XML through SOAP web services too, so any company with employees sends
  SOAP messages whether its developers know it or not.
- **Banks and insurers.** Payment networks, credit checks and policy systems often sit behind a
  SOAP interface that the bank's own mobile app never sees. The app speaks JSON to the bank's
  backend, and the backend speaks SOAP to the core system.
- **Large companies inside.** Airlines, telecoms and retailers connected their systems through SOAP
  for two decades. A new mobile app at one of them is often a JSON layer on top of those services.

That last pattern is where a junior tester is most likely to meet SOAP: **behind an API you are
testing, rather than in front of you.** boxoffice could work the same way. A theatre in São Paulo
sells a service, and each ticket would need an invoice from the city's invoice web service, which
boxoffice would call after the payment. The phone never sees that call; the order fails or succeeds
because of it.

## What that means for a test

Two things are different about testing a service like the NF-e's, and both shape this lesson.

**You cannot call the real one from your laptop.** It needs a company registration and a digital
certificate, and a mistake in production issues a real fiscal document. The NF-e services run a
second environment, *homologação*, where an invoice has no fiscal value, precisely so that
integrations can be tested. Even that needs the certificate. So section 04 gives you a stand-in of
your own, with the same shape: one address, one operation, a WSDL and faults.

**The interesting tests are about the fault.** A service that issues invoices when everything is
right is the easy half. What does it answer when the tax id is short, when a field is missing, when
the operation name is wrong? Does it blame the client or itself? And what does the caller do with
each answer? The first questions are this lesson's; the last one, a dependency failing on purpose,
is what lesson 11 builds a mock server for.
