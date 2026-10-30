---
title: Deciding on purpose, and writing it down
version: 1
---

Lock-in that hurts is almost never the lock-in somebody chose. It is the one nobody noticed: the
Service Bus client called from forty files because it was convenient, the three-year savings plan
signed for a service that was rewritten in its second year. **The difference between a decision
and an accident is a record**, made when the choice is made, that says what was accepted, how to
get out of each part of it, and what would reopen it.

## An architecture decision record

The usual form is an *architecture decision record*, a short file kept in the repository beside
the code it decides, numbered, and never edited after it is accepted. A decision that changes gets a new record that supersedes the old one. Most teams write them in Markdown. This one is YAML, so
a script can read its fields as well as a person, and it records the choice lesson 21 made for the
shop:

```schooling-example
{"language": "yaml", "file": "decisions/0007-order-api-on-container-apps.yaml", "parts": [{"code": "id: 7\ntitle: The order API runs on Container Apps, in brazilsouth\nstatus: accepted\ndate: 2026-10-30\ndeciders: [the three developers of the shop]\n", "note": "The record's identity: a number, a title that states the decision rather than the topic, the date and who decided. **`status` is what makes it a record rather than a wish**: `proposed`, `accepted`, and one day `superseded by 12`."}, {"code": "context: >\n  The order API has run on one virtual machine for three years. Its\n  busiest week peaks at 80 requests a second and averages 26.5. A\n  nightly report takes six minutes; the month's finance export takes\n  five. The team knows containers and has never run a function in\n  production (lesson 21).\n", "note": "Why a decision was needed at all, in the numbers that made it: the traffic, the two jobs and the team. Somebody reading this in two years needs to know what was true then, because it will not be true then."}, {"code": "decision: >\n  Container Apps, a minimum of two replicas, from the image shop:1.0.\n  The report is a scheduled job and the export an event-driven job fed\n  by a Service Bus queue. Orders move to a database and report files to\n  an Azure Files share.\n", "note": "What was decided, in a paragraph. Not the comparison, which lives in lesson 21's program and its output, but what came of it."}, {"code": "lock-in accepted:\n  - kind: API\n    what: the Container App, its two jobs and their scale rules, in Bicep\n    exit: the image runs unchanged; rewrite the app and jobs, 3 days\n  - kind: API\n    what: the Service Bus queue that feeds the export\n    exit: AMQP 1.0 behind send_export_request(); move the broker, 2 days\n  - kind: identity\n    what: one managed identity, roles on the queue, database and share\n    exit: a credential per connection on the next platform, 3 days\n  - kind: data\n    what: the orders database and the report share, about 300 GB\n    exit: copy, keep in step, cut over; 2 days and the transfer\n  - kind: operations\n    what: Bicep, Azure Monitor, and what three people know\n    exit: 19 days, 12 of them learning\n  - kind: contract\n    what: none; no reservation or savings plan before 2027-05-01\n", "note": "**The part most decisions leave out.** Each kind of lock-in from section 02, exactly what was accepted, and an exit plan for each: the first step on the day of leaving and what it costs, from section 04's estimate. The days are the example's invented figures. A lock-in written here is a choice; one discovered later is an accident."}, {"code": "lock-in refused:\n  - an azure library outside the two modules that use Service Bus\n  - bindings, Durable Functions or Logic Apps in the order path\n  - a commitment signed before six months of steady traffic\n", "note": "What the team decided not to accept. This is where section 03's seams are written down, so that a reviewer can point at a pull request that crosses one, and where a later change of mind needs a record of its own."}, {"code": "revisit when:\n  - traffic stays near three times today's for a month\n  - real rates leave Container Apps less than 20% cheaper\n  - a second app spends the free grants this decision counted on\nreview: 2027-04-30\n", "note": "The conditions that reopen the decision, the three lesson 21 named, each something a dashboard can show; and a date on which somebody reads the record again even if none of them has fired."}]}
```

**This file was not run**; it is a document. Its effort figures are section 04's invented ones and
its traffic is lesson 21's profile, which is the point: every claim in it can be traced to
something somebody can repeat.

## An exit plan for every line

The `exit:` beside each accepted lock-in is what makes the record useful on a bad day. It does not
plan the move. It names the first step and its size, so that the day somebody asks "what if we
had to leave?" the answer is already in the repository and nobody has to reconstruct it from
memory.

Each one also says what keeps it cheap. The Container App's exit is short because the image runs
unchanged, the queue's because the client sits behind `send_export_request()`, and the identity's
because the record lists the connections one by one. **An exit plan is only as good as the seam
it relies on**, and the `lock-in refused` lines are those seams, written as rules a pull request
can break. A reviewer who sees `from azure.servicebus import ServiceBusClient` in the order
handler can point at the line it crosses.

## What makes one useful two years later

A record nobody reads is a diary. Four habits keep this one alive:

- **it lives with the code**, in `decisions/`, so a pull request that crosses a refused seam can
  link to the line it crosses;
- **its triggers are measurable**. "If it gets expensive" is not a trigger; "traffic near three
  times today's for a month" is, and an Azure Monitor alert of the kind `azure-operations` teaches
  can watch the request count;
- **it has a review date**, because a trigger nobody watches does not fire. Six months is a
  reasonable default for a service that is still finding its traffic, and it is also when the
  record says a commitment may first be considered;
- **it is superseded, not rewritten.** When the shop moves the report somewhere else one day,
  record 12 says so and points at record 7. The history of why is worth more than a tidy current
  state.

## When one is worth writing

Not every choice needs a record. **Write one when the decision would be expensive to reverse**,
which is exactly when it carries lock-in: a compute platform, a database, an identity model, a
commitment of a year or more, a seam the team agrees not to cross. A choice of library inside one
module does not need one, because the module can be replaced in an afternoon. A useful test is the
question a new colleague asks in their first month: why is it like this? If the answer lives only
in somebody's head, it leaves when they do, and the next person decides again, with less
information, what was already decided once.

## Lock-in accepted on purpose

Read the record's lock-in lines again and notice what they do not say. They do not say the shop
avoided lock-in: it accepted four kinds, with an exit and a price beside each, and wrote down that
it signed nothing for the fifth. **Accepting
lock-in is the normal result of using a cloud well**, because every managed service is bought
partly with the cost of leaving it. The bindings of lesson 15 and the identity of lesson 13 are
worth having. What the record adds is that the price was looked at, compared with what it bought,
and written where the next person will find it.

That is also the answer to the question every lesson of this course has circled: which compute?
Not one service for everything, and not the cheapest line of a table, but the one whose traffic,
running cost, migration effort and lock-in a team can state in a file like this one, and still
defend when the file is two years old.
