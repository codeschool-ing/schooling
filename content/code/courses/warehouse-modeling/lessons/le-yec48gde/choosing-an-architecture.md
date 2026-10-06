---
title: Choosing an architecture, and arguing for it
version: 1
---

This lesson and the three before it have described several ways to organise the same warehouse: one central star,
a normalised core with dependent marts, independent marts, a lakehouse in medallion layers, a mesh of domain
products. They are not rungs on a ladder, and the newest is not the best. Each one answers a question about the
organisation as much as about the data.

- **How many teams produce data that others need?** One or two: a central warehouse is simpler, and a mesh would add
  a platform and a governance process to coordinate people who already sit together. Dozens: the central team becomes
  the bottleneck, and the mesh exists for that problem.
- **Can the teams that produce data take on publishing it?** Domain ownership asks product teams to run pipelines,
  keep contracts and answer for quality. A team that cannot staff that will publish something worse than a central
  team would have built.
- **Is there a platform to stand on?** Without shared storage, a catalogue and contract checks run by the platform,
  "domain ownership" is fifty independent marts with a new name.
- **What are the numbers that must agree?** Wherever two departments report the same measure to the same board, the
  definition must be conformed, whoever owns the pipeline. The bus matrix is the cheapest way to see where those are.

For Ponto Final the answer is short. One data person, seven shops, one website: **a central star, with dependent marts
as views**, and the two independent marts retired once their numbers are reconciled and named. A mesh would be a
platform with one customer.

::: track software-architecture
The argument is the one `architecture` lesson 2 has about microservices, and it is decided the same way. A mesh
splits the data platform along team boundaries, so it works where the teams are already split and costs where they
are not; Conway's law runs through both. Write the decision down as `architecture` lesson 20 records any other, with
the alternatives and the measurements: this lesson's three December numbers are exactly the evidence an architecture
decision record needs.
:::

::: track *
Whatever is chosen, write the decision down with what it was weighed against, and with the measurements. This
lesson's three December numbers are the kind of evidence that settles such an argument: they show what independent
marts cost, in centavos, rather than asserting it.
:::

The modelling stays put through all of it. **Every architecture in this lesson ends in facts and dimensions** that
somebody has to design with a grain, conformed keys and history, and that design is what lessons 2 to 6 taught. The
architecture decides who builds it and where it lives. Lesson 12 is about the part every one of them needs and most
skip: writing down what each column means.
