---
title: States and transitions
version: 1
---

**Some behaviour depends on what has already happened.** The same button, Refund, should work on
one order and be refused on another, and nothing typed into a form tells the two apart: the
difference is the order's history. Lesson 4's techniques look at inputs, and the decision table in
section 02 of this lesson looks at combinations of conditions that are all true at one moment.
Neither sees time. **State transition testing** is the technique for things that move through a
life, and in boxoffice that is an order.

The common way to test an order is to follow it along the path a customer usually takes: book it,
pay for it, use it at the door. Every step works, and the order is called tested. That path is one
of several the requirement allows, and it never asks the question this technique exists for: what
happens when somebody does a thing the order's current state does not allow?

## States, events, transitions

R6 describes the order's life in four sentences, and a model of it has four parts:

- a **state** is a condition the order stays in until something happens to it: reserved, paid,
  used, cancelled, refunded. Five states;
- an **event** is what happens: in boxoffice, the four buttons on an order's page, Pay, Cancel, Use
  and Refund;
- a **transition** is an event that moves the order from one state to another. "A reserved order
  can be paid" is the transition reserved to paid, on the event pay;
- a **guard** is a condition a transition needs besides the event. R6's refund has one: "before the
  show starts".

A new order starts in reserved, the **initial state**. Cancelled, refunded and used have no
transitions out of them, so an order that reaches one stays there; those are **final states**. The
diagram draws the whole of R6 on one page, and one more thing besides: the action two of the
transitions carry, giving the seats back.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" data-fig=\"l05-order-states\" aria-label=\"A state diagram of an order. A new order enters reserved. From reserved, pay leads to paid and cancel leads to cancelled, giving the seats back. From paid, use leads to used, and refund, guarded by before the show starts, leads to refunded, giving the seats back. Used, cancelled and refunded have double borders: they are final states, with no way out.\"><defs><marker id=\"mt-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"80.0\" y=\"120.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">reserved</text><rect x=\"320.0\" y=\"120.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">paid</text><rect x=\"566.0\" y=\"26.0\" width=\"138.0\" height=\"48.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"570.0\" y=\"30.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">used</text><rect x=\"566.0\" y=\"206.0\" width=\"138.0\" height=\"48.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"570.0\" y=\"210.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">refunded</text><rect x=\"316.0\" y=\"241.0\" width=\"138.0\" height=\"48.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"320.0\" y=\"245.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"265.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">cancelled</text><circle cx=\"24.0\" cy=\"140.0\" r=\"6\" fill=\"var(--paper)\"></circle><path d=\"M30.0 140.0 L78.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><text x=\"24.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">new order</text><path d=\"M210.0 140.0 L318.0 140.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper)\"></path><text x=\"264.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pay</text><path d=\"M145.0 160.0 L316.0 262.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper)\"></path><text x=\"222.0\" y=\"228.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cancel</text><text x=\"222.0\" y=\"243.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">/ seats back</text><path d=\"M450.0 128.0 L566.0 58.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper)\"></path><text x=\"498.0\" y=\"82.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">use</text><path d=\"M450.0 152.0 L566.0 222.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper)\"></path><text x=\"500.0\" y=\"196.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">refund</text><text x=\"500.0\" y=\"211.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">/ seats back</text><text x=\"500.0\" y=\"226.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">[before the show starts]</text><rect x=\"560.0\" y=\"281.0\" width=\"22.0\" height=\"14.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"563.0\" y=\"284.0\" width=\"16.0\" height=\"8.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"590.0\" y=\"288.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">double border: final state</text></svg>", "caption": "R6 as a state machine: five states, four transitions, one guard and the action two of the transitions carry. What the diagram does not draw, a button pressed in a state with no arrow for it, is the other half of the testing."}
```

## The table behind the diagram

A diagram shows the transitions that exist. It does not show the ones that do not, and those are
half of the testing. A **state table** does: one row per state, one column per event, and in each
cell the state that event leads to, or a dash where the event should be refused. For R6:

| state | pay | cancel | use | refund |
|---|---|---|---|---|
| reserved | paid | cancelled | – | – |
| paid | – | – | used | refunded |
| used | – | – | – | – |
| cancelled | – | – | – | – |
| refunded | – | – | – | – |

Five states by four events make 20 cells. Four of them are transitions; **sixteen are dashes**, and
every dash is a test case the diagram never drew: press that button on an order in that state, and
expect a refusal with a sentence (R7) and the order left as it was.

## How many cases

The usual minimum for state transition testing is to make **every valid transition happen at least
once**. Transitions chain, so this rarely needs one case per transition. For R6, three paths from
a fresh order cover all four:

1. reserved, pay, paid, use, used;
2. reserved, cancel, cancelled;
3. reserved, pay, paid, refund, refunded.

Each case checks the state after every step, and the action too where the transition has one.
Cancelling and refunding give the seats back, so those cases read the seats left before and after.
A state that changes correctly while the seats stay taken is a failed case, and so is the opposite.

The dashes are where judgement comes in. Sixteen invalid cases are not many for boxoffice, and all
sixteen can be run in a few minutes. On a larger machine there may be hundreds, and the order to
run them in comes from harm, the same way lesson 1 ranked risks: which forbidden move would cost the
most if it worked? For an order, the moves that hand money back or put seats back on sale come
first. Refund on a used order is both.

The guard needs one more thing. Testing "before the show starts" means placing a refund on either
side of the show's time, and that needs the application's clock moved, which lesson 13 does with a
fake clock. This lesson tests the transitions without the guard, and says so: a plan that leaves a
condition untested should name it, the way lesson 1's scope names what it leaves out.
