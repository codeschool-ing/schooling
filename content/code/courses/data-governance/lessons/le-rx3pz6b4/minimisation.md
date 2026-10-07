---
title: Holding less
version: 1
---

Every control in this course costs something to run, and every one of them can fail. The data that
never fails to be protected is the data a company does not hold. **Article 6, III** of the LGPD
makes that a principle — **necessity**: processing limited to the minimum needed for its purposes,
with data that is pertinent, proportionate and not excessive.

Minimisation is not a single decision; it is a question asked of every column, in three forms.

**Do we need to collect it?** Ipê asks for a date of birth at sign-up. What for? To refuse sales a
minor cannot make, and to check an age on a prescription. Both need *whether the customer is an
adult* and, at most, the age — not the day they were born. A form that asks "are you 18 or over?" and
a year would serve both, and lesson 5's measurement says the exact date is one third of what makes
5,988 customers unique.

**Do we need to keep it in this form?** The CPF was needed to find customers and to read back to them.
Lesson 5 replaced it with an HMAC and a ciphertext, which serve both uses, and dropped the column. The
same question applied to `cep` asks whether a delivery address is needed after the delivery; to
`tickets.body`, whether the text is needed once the ticket is closed.

**Do we need to keep it at all?** That is retention, lesson 10's subject: a purpose has an end, and
data held after it is data held without one.

## Who decides

A data team cannot decide what the business needs. It can do three things nobody else will:

- **say what each column costs** — its class, who can read it, what it would expose in a breach — in
  the classification table, where the cost is visible;
- **show what is actually used.** A column no query has read in a year is a column somebody should be
  asked about; lesson 9's catalogue and lineage make that question answerable;
- **make the minimal design the easy one** — a form field that is not there, a view that already has
  the age band, a pipeline that drops what the next step does not use.
