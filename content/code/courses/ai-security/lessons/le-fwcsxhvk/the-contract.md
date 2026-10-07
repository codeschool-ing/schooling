---
title: What the contract with the provider has to settle
version: 1
---

Minimising the outbox decides what the provider receives. **What happens to it afterwards is
decided by the provider's terms**, and nothing in Tarefa's code can reach it. That makes the
contract, usually a data processing agreement attached to the terms of service, a security control
in the same sense as the tool. Six questions, each of which has an answer on paper before the
first ticket is sent:

| question | why it matters under the LGPD |
|---|---|
| Are the prompts and replies used to train or improve the provider's models? | if yes, the provider is deciding a purpose of its own and is no longer only an operator (art. 39) |
| How long does the provider keep them, and is an arrangement with no retention available? | Tarefa's retention policy does not reach them, and lesson 11's sweep stops at Tarefa's own disks |
| Where are they processed, and under which mechanism of art. 33? | an international transfer needs one, usually the ANPD's standard contractual clauses |
| Which other companies does the provider pass them to? | the data subjects have a right to know who receives their data |
| How fast does the provider report a security incident to Tarefa? | Tarefa has its own deadline towards the ANPD, and it starts when Tarefa learns of the incident |
| What happens to the data when the contract ends? | deletion or return, and how either is confirmed |

The answers differ between providers and between plans of the same provider, and they change. Read
them for the account Tarefa actually uses rather than for the product's marketing page.

## The data subjects' rights reach the model call

Art. 18 gives Marcos and Juliana a list of rights against Tarefa as controller. Three of them land
directly on this feature:

- **Access and information about sharing** (art. 18, II and VII). Juliana may ask what Tarefa holds
  about her and with whom it shared it. *"A model provider, under contract, for summarising support
  tickets"* is part of the true answer, and the privacy notice should already say so.
- **Deletion of unnecessary data** (art. 18, IV). A request that reaches Tarefa reaches every
  store Tarefa controls: the ticket, the logs of lesson 11, and the vault. The outbox copy at the
  provider is covered by the contract's retention terms, which is one reason to prefer short ones.
- **Correction** (art. 18, III). A summary that got Juliana's reason wrong, saved in the ticket, is
  data about her like any other.

A right that a system cannot honour is a defect in the design. The vault is a small instance of the
problem: it is the one file that turns the outbox back into names, so it must be deleted whenever
the ticket is, or a deleted ticket can still be reassembled.

## When something leaks

Art. 48 requires the controller to notify the ANPD and the data subjects of a security incident that
may cause them relevant risk or damage, and Resolution CD/ANPD nº 15 of 2024 sets the deadline at
three working days. An incident at the provider is Tarefa's incident too, because Tarefa is the
controller, and the only way Tarefa can meet three working days is if the contract makes the
provider tell it quickly. That is why the incident row of the table is not a formality.

Minimisation pays off here a second time. A leak of the outbox in this lesson exposes a ticket
number, a job title, an amount and three messages with placeholders in them. The notification still
has to be assessed, since the law asks about risk to people rather than about field names, but the
assessment is about something much smaller.

## The paperwork that goes with the feature

Two documents exist for this kind of decision. The **record of processing** (art. 37) says what Tarefa
does with personal data, on which basis and for what purpose: the summary feature is a new entry.
The **data protection impact report**, RIPD in the law's Portuguese (art. 38), is what the ANPD may
ask for, and it is where the choices in this lesson are written down with their reasons: the purpose
list, the hold on sensitive data, the provider's terms. Writing it before the feature ships costs an
afternoon. Reconstructing it after an incident means explaining decisions that nobody wrote down.

What not doing any of this costs is in art. 52: sanctions that go up to 2% of the company's revenue
in Brazil, limited to R$ 50 million per infraction, along with others that can hurt more, such as
publicising the infraction and suspending the processing.
