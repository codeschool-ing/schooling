---
title: Scope and risk
version: 1
---

**Scope is a list of what will be tested and a list of what will not**, and the second list is the
one that makes a plan honest. Every test effort leaves things out; a plan that says so lets the
people who own the product decide whether the omission is acceptable, and a plan that does not
leaves them to find out from a customer.

## Writing the scope

For boxoffice, the release being planned is version 1.0, and the scope starts from the
requirements in section 04 of this lesson. In scope:

- sign-up, confirmation and the confirmation e-mail (R2, R3);
- booking, prices and discounts (R4, R5);
- the life of an order, from reserved to used, cancelled or refunded (R6);
- error messages (R7);
- the pages on a phone and on a desktop, in the four browsers named (R8);
- keyboard and screen-reader use (R9).

Out of scope, each with its reason:

- **payment.** boxoffice records that an order is paid; the money itself is taken by the theatre's
  card machine at the counter, which is another system with another owner;
- **load.** The theatre sells at most 400 seats a week. Lesson 14 says how a load test is done,
  and for this release the plan decides it is not worth one;
- **the real mail server.** E-mails stop at the outbox in the test build (section 04), so whether
  they arrive in a real inbox is checked once in production, by a person, after the release.

An item out of scope is not an item forgotten. The difference is that somebody wrote it down, gave
a reason, and can be asked about it.

## Risk: what could go wrong, and how much it would matter

A **product risk** is something that could be wrong with the product and would cause harm if it
were. Each one has two dimensions, and they are judged separately because they come from different
people:

- **likelihood**: how probable it is that this part is wrong. The developers know most about it:
  new code, complicated code, code written in a hurry and code nobody has touched in years are all
  more likely to be wrong;
- **impact**: how much harm it would do if it were. The business knows most about it: money lost,
  customers turned away, a law broken.

Placed on a grid, the two together rank the risks, and the ranking says where the testing goes
first and deepest:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 330\" role=\"img\" data-fig=\"l01-risk-matrix\" aria-label=\"A three by three grid with likelihood up the side and impact along the bottom, each low, medium and high. A, price, sits at high likelihood and high impact. B, overselling, and C, refunds, sit at medium likelihood and high impact. D, confirmation e-mail, sits at low likelihood and medium impact. E, phone layout, sits at medium likelihood and low impact. The top right cells are marked test first, the middle band test next, the bottom left test last.\"><rect x=\"120.0\" y=\"20.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"20.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"284.0\" y=\"20.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"120.0\" y=\"102.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"102.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"284.0\" y=\"102.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"120.0\" y=\"184.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"184.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"284.0\" y=\"184.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"222.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">low</text><text x=\"158.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">low</text><text x=\"110.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">medium</text><text x=\"240.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">medium</text><text x=\"110.0\" y=\"58.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">high</text><text x=\"322.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">high</text><text x=\"240.0\" y=\"294.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">impact</text><text x=\"20.0\" y=\"91.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">likelihood</text><circle cx=\"322.0\" cy=\"58.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"322.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">A</text><circle cx=\"306.0\" cy=\"140.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"306.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B</text><circle cx=\"338.0\" cy=\"140.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"338.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">C</text><circle cx=\"240.0\" cy=\"222.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"240.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">D</text><circle cx=\"158.0\" cy=\"140.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"158.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">E</text><text x=\"396.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">A</text><text x=\"414.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">price</text><text x=\"396.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B</text><text x=\"414.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">overselling</text><text x=\"396.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">C</text><text x=\"414.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">refunds</text><text x=\"396.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">D</text><text x=\"414.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confirmation e-mail</text><text x=\"396.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">E</text><text x=\"414.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">phone layout</text><rect x=\"396.0\" y=\"178.0\" width=\"14.0\" height=\"14.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"418.0\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">test first, deepest</text><rect x=\"396.0\" y=\"204.0\" width=\"14.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"418.0\" y=\"211.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">test next</text><rect x=\"396.0\" y=\"230.0\" width=\"14.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"418.0\" y=\"237.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">test last, lightest</text></svg>", "caption": "The five risks of boxoffice on a likelihood and impact grid. The position of each letter is a judgement; the order the grid puts them in is what the plan uses."}
```

Five risks for boxoffice, placed the way a tester would place them after twenty minutes with the
theatre's manager and its one developer:

| | risk | likelihood | impact | why |
|---|---|---|---|---|
| A | a customer is charged the wrong price | high | high | three discounts with a rule about combining them, written last week |
| B | a show is sold beyond its seats | medium | high | an angry audience at the door, on a full night |
| C | a refund reaches an order that should not have one | medium | high | money paid back for a seat that was used |
| D | the confirmation e-mail never arrives | low | medium | the customer can still book, only without the member discount |
| E | the shows table is hard to read on a phone | medium | low | annoying, and nobody is charged anything for it |

**A ranking is an argument, not a measurement.** "High" and "medium" are judgements, and two
testers will place the same risk in neighbouring cells. That is acceptable, because what the grid
has to get right is the order, not the position: price errors before layout, refunds before
e-mail. Where the theatre's manager disagrees with an order, the plan has done its job by making
the disagreement visible before anything is built on it.

## What the ranking decides

The ranking turns into effort in two ways. **Depth**: risk A gets the techniques of lessons 4
and 5, where every combination of discounts is listed and checked; risk E gets a look on two
screen sizes. **Order**: the highest risks are tested first, so that if time runs out, what is
left untested is what matters least. That second point is the whole case for testing by risk. A
plan that runs out of time testing in the order the requirements happen to be written leaves the
price rule untested whenever it happens to be written last.

Risks are reviewed as the project moves. Every defect found is evidence about likelihood, so a part
that keeps failing moves up, and a part that has been stable for five releases may move down.
Lesson 10 uses the same ranking to choose what to run again after every change.
