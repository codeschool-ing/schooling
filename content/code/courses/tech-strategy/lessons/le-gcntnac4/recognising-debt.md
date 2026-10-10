---
title: Telling debt from everything else
version: 1
---

Ask an engineering team for its technical debt and you will often get a tracker label with a long
list under it: a bug from last year, a library two versions behind, a module somebody finds ugly, a
feature product never prioritised. **A list like that cannot be priced, because most of it is not
debt.** Before a debt can be classified, as the previous section did, or priced, as lesson 5 does,
it has to be told apart from the other things that borrow its name.

## Two questions

A piece of the system is technical debt, in the sense this course uses, when the answer to both of
these is yes.

1. Can you name a better design now? Not "this is bad", but "if we held seats with a short-lived
   reservation record instead of a row lock, the queue would disappear". If nobody can say what the
   better design is, there is nothing yet to repay.
2. Does the current design cost something each time somebody changes this area? A longer
   change, an extra review, a workaround, an incident. That is interest, and without it there is
   nothing to gain by paying.

The two answers sort everything on the long list into four groups.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 345\" role=\"img\" aria-label=\"A two-by-two grid. Across the top: can you name a better design now, yes or no. Down the side: does each change cost something, yes or no. Yes and yes, highlighted: debt with interest, register it, lesson 5 prices it; Coreto's four debts. No better design but a cost: the problem itself, better tests and documentation; half-price ticket rules. A better design but no cost: debt that charges nothing, leave it; the venue set-up screens. No and no: working code, nothing to do.\"><text x=\"455\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Can you name a better design now?</text><text x=\"325.0\" y=\"60\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">yes</text><text x=\"585.0\" y=\"60\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">no</text><text x=\"85\" y=\"187\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Does each</text><text x=\"85\" y=\"203\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">change cost</text><text x=\"85\" y=\"219\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">something?</text><text x=\"172\" y=\"142.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">yes</text><text x=\"172\" y=\"272.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">no</text><rect x=\"200\" y=\"78\" width=\"250\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"325.0\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">debt with interest</text><text x=\"325.0\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">register it; lesson 5 prices it</text><text x=\"325.0\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Coreto’s four debts</text><rect x=\"460\" y=\"78\" width=\"250\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585.0\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">the problem itself</text><text x=\"585.0\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">better tests and documentation</text><text x=\"585.0\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">half-price ticket rules</text><rect x=\"200\" y=\"208\" width=\"250\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"325.0\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">debt that charges nothing</text><text x=\"325.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">leave it, and look again later</text><text x=\"325.0\" y=\"298\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the venue set-up screens</text><rect x=\"460\" y=\"208\" width=\"250\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585.0\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">working code</text><text x=\"585.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">nothing to do</text></svg>", "caption": "The two questions that separate debt from everything else on a debt list. Only the top-left box goes in the register."}
```

**Yes and yes is debt with interest**, and it goes in the register. Coreto's four all qualify: each
has a design the team can describe, and each charges something every time a team works near it.

**A better design but no cost is debt that charges nothing.** Coreto's admin screens for setting up
a new venue are built in a style nobody would choose today, and they are changed so rarely that the
style costs almost nothing. Paying that principal would buy nothing back. Leave it, and look again
if the screens start changing often.

**A cost but no better design is the problem itself.** Brazil's half-price ticket rules for
students and others differ between states and change with the law, so every change to Coreto's
pricing code is slow and needs care. Nobody can name a design that makes the law simple. That
difficulty belongs to the domain; calling it debt sends a team looking for a refactoring that does
not exist.

**No and no** is ordinary working code, whatever anybody thinks of its style.

## What borrows the name

Five things turn up on debt lists most often and are something else.

| on the list | what it really is | where it goes |
|---|---|---|
| a bug | behaviour that is wrong | the bug queue, fixed like any other |
| a missing feature | product work nobody prioritised | the product roadmap |
| code in a style somebody dislikes | a preference | nowhere, unless it also charges interest |
| a dependency past its supported life | a risk with a date on it | keeping the lights on, as in lesson 2; lesson 6 covers a foundation going away |
| a hard domain | the problem itself | better tests and documentation, not a refactoring |

**A bug is the commonest impostor.** "Checkout shows the wrong fee for half-price tickets" is a bug
even if the code around it is messy. Fixing it does not repay anything, and putting it on the debt
list makes the list look longer than the debt is.

## Where to look for real debt

Interest leaves traces, and you can find debt by following them rather than by reading code.

- Changes in one area take longer than similar changes elsewhere. Adding a field to the seat
  hold took Checkout far longer than adding a field anywhere else in checkout.
- One change needs edits in many places. Every new venue layout at Coreto needs a change inside
  the PDF generator, as well as the layout itself.
- The same kind of incident comes back. On-sale after on-sale, the incident review named lock
  waits on the reservation tables.
- People route around it. Engineers re-run the end-to-end suite until it turns green, and some
  have stopped reading its failures at all.
- Everything waits for one person. Each schema change in `coreto-core` waited for the one Data
  engineer who knew which reports read which tables from the replica.

Each trace points at an area. The two questions then decide whether what is in that area is debt.

## Writing it down

The result is a **debt register**: one row per debt, short enough that people read it. Davi's for
Coreto had four rows:

| debt | where | box | what it costs each time | who knows it best |
|---|---|---|---|---|
| seat-hold locking | reservation module | prudent, inadvertent | on-sale incidents; slow, risky changes to holds | Reservations team |
| PDF ticket generator | ticketing | prudent, deliberate | a code change for every new ticket layout | Box Office |
| flaky end-to-end suite | test pipeline | reckless, deliberate | re-runs on every merge; failures nobody trusts | Platform |
| reporting replica | Data | reckless, inadvertent | broken reports after schema changes; a reviewer on each change | Data team |

The cost column is in words, on purpose. **Lesson 5 turns it into hours a sprint and reais**, and
that is where the four rows stop being equally serious.

Two habits keep a register useful. The first is to **keep it short**: four debts that the teams agree on beat a
hundred tickets that nobody reads, and a debt earns its row by passing both questions. The second is to keep the
evidence beside each row, a link to the incidents or the slow changes, so that the row can be
challenged and defended. A register is the input to a budget argument, and an input that cannot be
checked will not survive one.
