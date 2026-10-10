---
title: A platform team is a product team whose customers are engineers
version: 1
---

Most platform teams begin as the team that owns the shared things nobody else wants: the build
machines, the deploy scripts, the database requests. Work reaches them as tickets and they are
judged by how fast the queue empties. **A team run that way cannot tell whether anything it builds
is good**, because nobody using it had a choice, and usage that was never optional measures nothing.

The other arrangement treats the platform as a product. It has customers — the engineers of the
other teams — and it succeeds when they pick it up because it makes their week easier. It can also
fail the way a product fails, by being ignored, and that failure is information a ticket queue
never produces.

## Where the idea comes from

Matthew Skelton and Manuel Pais give it a vocabulary in *Team Topologies* (2019). They describe
four kinds of team, and a platform team only makes sense beside the other three:

| team type | what it does | at Coreto |
|---|---|---|
| stream-aligned | delivers a flow of change straight to users | Checkout, Catalogue, Box Office, Mobile, Payments |
| enabling | helps another team pick up a skill, then steps back | none yet |
| complicated-subsystem | owns a part that needs rare expertise | the Reservations team lesson 1 created comes close |
| platform | provides internal services that let stream-aligned teams deliver on their own | Platform |

The purpose of the platform team, in their words, is to **reduce the cognitive load of the
stream-aligned teams**: the amount a team has to hold in its head to ship a change. Mateus Araújo's
Checkout team should be thinking about how a buyer pays for a seat. Every hour they spend learning
how the logging agent is configured, or why a deploy still needs manual steps, is an hour taken from
the thing only they can do.

The book also names the way a platform team should usually be consumed: **as a service**, through
something the other team can use without a meeting. A request that needs a conversation every time
is collaboration, which is right for a few weeks while something new is being shaped and expensive
as a permanent arrangement.

## The thinnest viable platform

The same book warns against the opposite failure: a platform team that builds a large internal
system before anybody has used any of it. Its answer is the **thinnest viable platform** — the
smallest set of services, documentation and tools that speeds the other teams up. Skelton and Pais
point out that it can be as thin as a page of documentation listing the agreed way to do something.

The word that matters is *viable*. A page that says "this is how a new service gets logs, alerts
and a pipeline at Coreto" is a platform if teams follow it and it saves them time. It can grow into
a template, then into a tool, each step taken because the previous one was used and showed where
the next pain is.

## What changed at Coreto

Rafaela Nunes took over the Platform team when it was still a queue. Teams asked for a database, a
DNS entry or a production deploy in a chat channel and waited. The team was busy all the time, and
nobody outside it could have said what it was for beyond answering requests.

She changed three things, and each one is what makes a platform team a product team:

1. **She found out what hurt before deciding what to build.** Rafaela spent her first sprint with the
   six other teams asking where their time went, the same move Davi made in lesson 1 when he read the
   incident log instead of collecting wishes.
2. **She made the result optional.** Whatever Platform built would have to win its users, which
   meant usage would say whether it worked.
3. **She measured adoption and asked the teams that did not adopt.** A team that stayed away was a
   customer with a reason, and the reason was the next item on her list.

The answer to the first question surprised the team. The teams did not want more infrastructure.
They wanted to stop spending the first days of every new service wiring up a pipeline, logs and
alerts by copying another team's configuration and fixing what did not fit. That is the
subject of the next section.

## Platform work inside the strategy

The platform team also has a place in the strategy, and lesson 1 already gave it one. The second
action of Coreto's strategy asks Platform to build a load test that replays an on-sale's traffic.
**That is a platform product with a named customer**: the Reservations team, who need it to measure
every change to the seat-hold code. It is judged the same way as everything else Platform builds —
by whether Reservations runs it before each change because it is the easiest way to know, rather
than because a rule says so.

| | platform as a queue | platform as a product |
|---|---|---|
| what gets built | whatever the loudest ticket asks for | what removes the most time from the other teams |
| how it reaches teams | a request and a wait | a service they use without asking |
| how success is measured | tickets closed | teams that chose it, and what they stopped doing |
| a team that goes elsewhere | a rule-breaker | a customer telling you something |
