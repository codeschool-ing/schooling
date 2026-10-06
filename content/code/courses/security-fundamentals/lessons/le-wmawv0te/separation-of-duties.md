---
title: Separation of duties
version: 1
---

Least privilege limits what one account can do. **Separation of duties** limits what one person can
do alone, by splitting a sensitive task so that it needs two people to complete it.

The classic case is money. If the same person can create a new supplier, approve an invoice from it
and send the payment, a fraud needs one dishonest person, or one stolen password. Split those three
steps between two people and the same fraud needs both of them, which is much less likely, or two
stolen passwords, which is twice the work and twice the chance of being noticed.

At the shop:

| task | step one | step two |
|---|---|---|
| paying a supplier | finance enters the invoice | one of the owners approves the payment |
| changing a firewall rule | ana writes it | somebody else reviews it before it is loaded |
| adding an administrator | ana creates the account | the owners approve the request in writing |
| changing a customer's bank details for a refund | support records the request | finance confirms with the customer by phone |

The last row is where a lot of real fraud happens. "Please update our bank account" from an email
that looks like a supplier's is one of the most common scams against small businesses, and the
defence is not technical at all: a second person, a known phone number, a call before the money
moves.

### Related ideas

**Dual control**, or the **two-person rule**, is the strongest form: both people must act together
for the task to happen at all, like two keys turned at once. Banks use it for vaults; the IT
version is a change that cannot be deployed until a second person approves it in the system.

**Maker and checker** is the everyday form: one person prepares, another verifies. A pull request
that cannot be merged without a review is maker-checker built into a tool.

**Job rotation** and **mandatory vacations** come from the same reasoning in reverse. Some frauds
need the fraudster present every day to keep them hidden, and are discovered within days of
somebody else doing the job.

### What it costs a small shop

With nine people, strict separation is not always possible: sometimes there is only one person who
can do a task. Then the separation becomes **detective rather than preventive**, a compensating
control in lesson 4's terms. ana loads firewall changes herself, and every change goes into a log
the owners read once a week. The second person arrives after the fact rather than before, which is
weaker and still far better than nobody.
