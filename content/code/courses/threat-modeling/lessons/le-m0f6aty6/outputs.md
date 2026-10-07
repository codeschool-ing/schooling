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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l06-minimise\" aria-label=\"Two outputs, each carrying one item more than it needs. The charge sent to the gateway carries the amount, the booking id, the name and the CPF; the CPF is the item it does not need. The reminder sent to the SMS provider carries the phone, the first name, the time and the clinic; the clinic’s name is the item that discloses treatment, T08.\"><text x=\"20.0\" y=\"35.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">charge to the gateway</text><rect x=\"20.0\" y=\"50.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">amount</text><rect x=\"170.0\" y=\"50.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">booking id</text><rect x=\"320.0\" y=\"50.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">name</text><rect x=\"470.0\" y=\"50.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"540.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">CPF</text><text x=\"620.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">not needed</text><text x=\"20.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">reminder to the SMS provider</text><rect x=\"20.0\" y=\"145.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">phone</text><rect x=\"170.0\" y=\"145.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">first name</text><rect x=\"320.0\" y=\"145.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">time</text><rect x=\"470.0\" y=\"145.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"540.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">clinic (T08)</text><text x=\"620.0\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">not needed</text><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">send the least that does the job</text></svg>", "caption": "Every item beyond what the job needs is surface that buys nothing, and in a clinic it is usually personal data."}
```
