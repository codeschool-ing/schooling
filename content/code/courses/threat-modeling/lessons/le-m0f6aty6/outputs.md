---
title: Outputs
version: 1
---

Inputs get the attention because attacks arrive through them. **Outputs are where data leaves, and
a leak is an output nobody intended.** Mapping them asks, for every flow out of Vereda's systems,
what it carries, who receives it, and whether it carries more than it needs.

| output | carries | received by | carries more than it needs? |
|---|---|---|---|
| pages to the patient | the patient's own bookings, payments, exams | the patient's browser | not if T07's ownership check holds |
| charges to the gateway | amount, booking id, name, CPF | the gateway | the CPF (lesson 5, linking) |
| reminders to the SMS provider | phone, first name, time, clinic | the provider, then the phone | the clinic's name (T08) |
| error messages | whatever the framework prints on a failure | the browser that caused it | often: a stack trace names files, versions and queries |
| logs | request details, sometimes bodies | the log service, and whoever reads it | e-mail addresses and booking ids in every line |
| e-mails sent by the portal | confirmations, password resets | the patient's mail provider | a reset link is a credential in transit |

### Three outputs that are not on the DFD

**Error messages.** A failure that prints a stack trace to the browser is an exit point carrying
the internal layout of the system to whoever caused the error, deliberately or not. The
`secure-code` course (lesson 15) is about what must never appear in one; the map's job is to
notice that the output exists.

**Logs.** The portal logs every request, and a request's body includes the patient's e-mail at
sign-in. Logs are kept longer than most data, read by more people, and often shipped to a vendor.
They are an output with a long tail.

**Timing and existence.** A sign-in form that answers "no such account" faster than "wrong
password" tells a stranger whether a person has an account at Vereda, which is, for a
physiotherapy clinic, the fact that they are a patient. That is an output too, carried by the
difference between two responses rather than by either one.

### Minimising

The rule for outputs is short: **send the least that does the job.** A reminder needs a time; a
charge needs an amount and a reference; an error page needs an apology and an id the support team
can look up. Everything beyond that is surface that buys nothing.
