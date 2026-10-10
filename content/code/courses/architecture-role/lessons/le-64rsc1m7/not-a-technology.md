---
title: A technology is not an architecture
version: 1
---

Ask an engineer to describe a system's architecture and many will list its technologies: Python and
Django, PostgreSQL, RabbitMQ, Kubernetes. **A list of technologies says almost nothing about the
architecture.** It does not say what the elements are, how they relate, or what the system was built
to be good at. Two companies with exactly the same list can have opposite architectures, and two
with nothing in common can have the same one.

## The same tool, two architectures

Consider a message broker such as Kafka, which you met in `architecture` lesson 6. One team uses it
as a log of facts: Tracking publishes "position recorded", and any service that cares reads them in
its own time without Tracking knowing it exists. Another team uses the same broker as a slow remote
procedure call: a service publishes "please calculate a quote", waits for a reply on another topic,
and fails if none arrives in two seconds. The first is an event-driven design with loose coupling.
The second is a synchronous chain wearing a broker's clothes, with every weakness of the synchronous
version in lesson 1 and a new set of moving parts on top.

PostgreSQL is the same. One database per service, reachable only through that service, is one
architecture; one database shared by six services is another. Carreto runs PostgreSQL in both ways
today. **The name of the technology settles none of this**; the decisions about how it is used do.

## "Everyone is moving to microservices"

In Renata's second week, an engineer on the Shipper team sends a proposal to the engineering list.
Its title is *Moving Carreto to microservices*. It recommends splitting the monolith into about
twenty services, running them on Kubernetes, and putting Kafka between them. Its argument fits in
one paragraph: this is how modern companies build software, Netflix and Uber did it, and engineers
want to work with these tools.

Renata does not answer whether the proposal is right. She asks what problem it solves, and she asks
it of the people who would feel the problem. The answers are specific:

- deploying the monolith takes about 40 minutes, and a failing test from one team blocks everybody
  else's release;
- two teams changing the `loads` table in the same week have broken each other twice this year;
- the Shipper team waits for Matching to review changes that touch shared code.

Those are real problems, and none of them is "we do not have microservices". The first is about
deployability, the second about the data shared between teams, the third about ownership. **Each one
has several possible answers, and splitting into twenty services is only one of them — the most
expensive one.** A faster pipeline and tests that run per module would shrink the first. Giving the
`loads` data a single owner, which lesson 1 called the most expensive decision in the system, would
address the second. A modular monolith, with modules that may not reach into each other, would
address the third without adding a single network call.

The comparison with Netflix deserves its own sentence. **A company with thousands of engineers has
problems that a company with fifty does not**, and the solutions to them carry costs designed for an
organisation that can pay them. Carreto already runs 14 services with one small Platform team;
lesson 12 counts what each of those costs to keep, and the answer argues against adding six more
because they are fashionable.

## Résumé-driven choices

There is an uncomfortable reason why proposals like this one are written, and it is worth naming
because it is common and nobody admits to it. **Engineers like to work with technologies that make
their next job easier to get.** The informal name for choosing tools on that basis is *résumé-driven
development*. The engineer is not being dishonest; learning Kubernetes is genuinely valuable for
their career. The trouble is that the company pays for the learning with an architecture it did not
need and has to operate for years.

An architect's defence against it is not suspicion of new tools. It is a question asked every time:
**which quality attribute does this improve, by how much, and what does it cost?** A proposal that
can answer that is worth reading whatever it recommends. One that cannot is a wish.

## The order: quality attribute, structure, technology

A sound technology choice comes at the end of a chain, not the start:

1. **the quality attribute** the system needs, stated with a number, as lesson 6 teaches;
2. **the structural decision** that delivers it — a queue rather than a synchronous call, one owner
   for a table, a separate deployable for one part;
3. **the technology** that implements that structure well for this team.

Carreto's Tracking service is a good test case. The Driver app sends each truck's position every 30
seconds, and at the busiest hour of the week about 3,000 trucks are on the road. That is about 100
positions a second. A proposal to put Kafka in front of Tracking "for scale" falls apart on the
arithmetic: 100 small writes a second is comfortably within what a single PostgreSQL instance
handles. **The quality attribute does not demand the technology.** If the number were a hundred
times larger, the conversation would be different, and it would be a conversation about the number.

## When a technology is an architectural decision

None of this means technology choices never matter to an architect. Lesson 1's test applies to them
like any other decision: **a technology choice is architectural when it is expensive to reverse.**

- The database engine that holds Carreto's financial records is architectural: changing it means
  migrating years of data that has to stay correct to the cent.
- A cloud provider's proprietary queue, used directly from forty places in the code, is
  architectural: leaving it means touching all forty.
- The library Pricing uses to format dates is not: replacing it takes an afternoon.

The difference is not in how impressive the technology sounds. It is in the cost of changing your
mind. Lesson 5 is about making technology decisions on purpose — the criteria, the one-way and
two-way doors, and writing the decision down so that the next person can see why it was made.

## The signs of a technology-first proposal

Renata's reply to the microservices proposal is courteous and short. She thanks its author, lists
the three problems the teams described, and asks him to rewrite the proposal starting from them.
Over the next months she learns to spot the pattern early. **A proposal that starts from a
technology rather than a problem** has a few reliable signs:

- the technology is in the title, and the problem is not;
- the section describing the problem is shorter than the section describing the solution;
- no alternative is considered, not even doing nothing;
- the benefits are adjectives — "modern", "scalable", "robust" — with no number attached;
- the costs mention licences and machines but not people: who will operate it, and who will learn
  it.

None of these signs proves a proposal wrong. Each is a reason to ask for the problem first.
