---
title: Data mesh
version: 1
---

Everything so far assumes one team builds the warehouse. In a company of Ponto Final's size that is true and
sensible. In a company with fifty product teams, each running its own systems, the central data team becomes the
queue every question waits in: it has to understand every source, and the people who understand each source sit
in other teams, busy with other work.

**Data mesh** is a proposal for that company. Zhamak Dehghani set it out in 2019, in an article on Martin Fowler's
site, and later in a book, *Data Mesh* (O'Reilly, 2022). It rests on four principles:

- **Domain ownership.** The team that runs a part of the business owns the data that part produces, the analytical
  data included. The orders team publishes orders; nobody downstream reverse-engineers them from an extract.
- **Data as a product.** What a domain publishes is treated as a product with users: documented, reliable,
  versioned, with somebody answerable for it. The next section is about what that means in practice.
- **A self-serve platform.** Storage, pipelines, a catalogue, access control and monitoring are provided by a platform
  team, so that each domain can publish a data product without becoming a data infrastructure team itself.
- **Federated computational governance.** The rules every product must follow, such as naming, the conformed
  dimensions, the classification of personal data, are agreed jointly and **enforced by code in the platform**,
  not by a review meeting.

Set beside this course, the mesh is less of a break than it sounds. The bus matrix of the previous section is
federated governance on one page: the shared dimensions are the part everyone agrees on, and each row can be
owned by a different team. What the mesh changes is **who builds each row**: the domain, rather than a central
team that has to learn every domain in turn.

What it does not change is the modelling. A domain publishing sales still has to declare a grain, choose its
dimensions, and keep a customer's history; the mesh moves that work, it does not remove it. The fourth principle
exists because without it fifty teams would produce fifty independent marts, and section 4 showed where that
leads.
