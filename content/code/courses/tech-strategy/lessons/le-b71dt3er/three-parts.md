---
title: The three parts of a no
version: 1
---

Without a strategy, a no is the tech lead's opinion against the head of product's, and the louder
or more senior of the two wins. With one, **the reason for the no is a decision the company has
already taken**, and the lead's job is to show how the request meets it. Three parts carry that:
an alternative that fits the guiding policy, the cost in the strategy's terms, and the date the
answer changes.

## What the strategy adds to the conversation

`architect-communication` lesson 8 gave a good no five parts: the need said back, the no in one
sentence, the reason in the asker's unit, an alternative, and what would change the answer. Use
them; this section does not teach them again. What it adds is where the content of three of those
parts comes from once a strategy exists.

| part of the no (`architect-communication` lesson 8) | without a strategy | with one |
|---|---|---|
| the reason | "the team is busy" | the guiding policy, and the action the request would delay |
| the alternative | whatever the team can spare | something that serves the need and stays inside the policy |
| what would change the answer | "maybe later" | a date, or a condition, taken from the strategy's own plan |

The difference shows in what the asker can do next. "The team is busy" invites them to argue about
how busy. **A reason that cites the policy sends the argument to the right place**: if Júlia thinks
group bookings matter more than protecting the on-sale, that is a disagreement with the strategy,
and it belongs with Helena Prates, who owns it.

## The alternative fits the policy

An alternative has two jobs. It has to serve the need behind the request, and it has to do so
without crossing the guiding policy. **An alternative that fails the second test is the same
request, smaller.** "A simpler version of group holds" still adds holds to the reservation path,
so it meets the same objection with less to offer.

Mateus asked what the festival actually needed, and the answer was that groups of friends want to
sit together. That need does not require a new kind of hold. Venues already set seats aside
through Box Office, the application they use at the door: a venue can reserve a block for a group
and sell it with a group code, and each friend then buys an ordinary ticket. Nothing new touches the
hold path, and checkout does not change.

It is worse than the feature. The festival has to set the blocks up by hand, and a group cannot
pick its own seats on the map. **A good alternative is honest about what it gives up**, because the
asker will find out anyway, and an alternative oversold today is a reason not to trust the next one.

## The cost, in two currencies

The first currency is the one the previous section computed: about 90 hours, a quarter of one
Checkout sprint, R$ 13,500 at R$ 150 an hour. State it plainly, with the arithmetic, so the asker
can check it.

The second currency is the strategy's own. The 90 hours come out of Checkout's move onto the new
hold interface, which the lock removal is waiting for; every sprint the lock removal slips, the
seat-hold debt charges another 31 hours of interest, R$ 4,650 (lesson 5). And the feature itself
would put new holds on a path that has not yet survived an on-sale's load test. **The second
currency is what makes the no a strategic answer** rather than a scheduling one: it says what the
company would be giving up, in the terms the company chose.

Name who can overrule it. If the festival matters enough, somebody with authority over both the
product roadmap and the technical strategy can decide to take the cost. At Coreto that is a
conversation between Júlia and Helena, with the numbers on the table, and `people-leadership`
lesson 22 is about having it without turning it into a fight between two teams.

## The date says when the answer changes

"Later" gives the asker nothing to plan with. A date does, and a strategy usually has one to offer,
because its actions have dates. **The lock removal was planned for two quarters from 1 March, so it
ends at the end of August.** Group bookings could enter planning for the first Checkout sprint of
September — provided the load test, by then, replays an on-sale with group holds in it and the
path survives.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Four boxes left to right. 1 March: the Reservations team starts. March to August: two quarters removing the row locks. The condition: the load test passes an on-sale replay with group holds. September: the first sprint in which group bookings can start.\"><defs><marker id=\"notyet-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"150\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">1 March</text><text x=\"95\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the Reservations</text><text x=\"95\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">team starts</text><path d=\"M172 90 L188 90\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#notyet-ah)\"></path><rect x=\"190\" y=\"40\" width=\"190\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"285\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">March to August</text><text x=\"285\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">two quarters removing</text><text x=\"285\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the row locks</text><path d=\"M382 90 L398 90\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#notyet-ah)\"></path><rect x=\"400\" y=\"40\" width=\"160\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"480\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">the condition</text><text x=\"480\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the load test passes</text><text x=\"480\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">an on-sale replay</text><text x=\"480\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">with group holds</text><path d=\"M562 90 L578 90\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#notyet-ah)\"></path><rect x=\"580\" y=\"40\" width=\"120\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"640\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">September</text><text x=\"640\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">first sprint in</text><text x=\"640\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">which group</text><text x=\"640\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">bookings can start</text><text x=\"20\" y=\"180\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the date comes from the strategy's own plan; the condition says what has to be true on that date</text></svg>", "caption": "Where Mateus's date comes from. The first two boxes are lesson 1's actions with their dates; the dashed box is the condition that turns the date into a yes."}
```

Notice that the date is not a promise to build. It is the earliest point at which the objection
goes away, and it is attached to something the asker can watch happen. The next section is about
that attachment, and about what to say when no date can be given at all.

## Mateus's reply

Mateus did not answer in the corridor. He wrote to Júlia the next morning, and copied Davi, who
owns the strategy:

> Júlia — about group bookings for the festival.
>
> We can't build group holds this quarter. They add new holds to the reservation path, and our
> strategy says nothing ships there until the load test shows the path survives an on-sale.
>
> What we can do now: the festival reserves blocks for groups through Box Office and sells them
> with a group code. Each friend buys an ordinary ticket, nothing changes in checkout, and the
> groups sit together. They can't choose their own seats on the map, which is the part we're
> giving up.
>
> What a yes would cost: about 90 hours, a quarter of one Checkout sprint (R$ 13,500). Those hours
> come out of our move onto the new hold interface, which the lock removal waits for, and every
> sprint the lock removal slips costs another 31 hours of interest on the seat-hold debt
> (R$ 4,650).
>
> When the answer changes: the lock removal is planned to finish at the end of August. If the load
> test then passes an on-sale replay with group holds, group bookings can go into our first sprint
> of September.
>
> If the festival can't wait for that, it's a decision for you and Helena, and I'll bring these
> numbers to that conversation.

Every sentence of it can be checked by somebody who was not in the room. That is what makes it
safe to forward, and a no about a client's request is always forwarded.
