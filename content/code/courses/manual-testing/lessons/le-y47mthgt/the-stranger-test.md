---
title: The stranger test
version: 1
---

A case is usually judged by whether it checks the right thing, and that is necessary. It is not
enough. A case that checks the right thing and can only be run by the person who wrote it is a
note to self with a table around it. **A case is finished when somebody who has never seen the
application, and cannot ask you anything, can run it and reach the verdict you would.** This
lesson calls that the stranger test, and it is the standard every case in this course is written
to.

## Who the stranger is

The stranger is not hypothetical. Cases are written to be run by somebody else, and that somebody
turns up in four forms:

- **a colleague** who joins the team in March and is given the cases on their first day;
- **the developer**, Rui, reproducing a failure at eleven at night while you are asleep;
- **you, six months from now**, who has forgotten what *the usual account* meant;
- **a script.** The automation courses that follow this one in the `qa` track turn manual cases
  into programs, and a program does exactly what the case says, asks nothing, and guesses
  nothing.

For this course the stranger has a precise description. They can use a browser and a terminal.
They have the case, and boxoffice running at `http://127.0.0.1:8000`. They have never seen
boxoffice, have not read R1 to R9, and cannot reach the person who wrote the case. **Every case is
written for that person**, and a case that needs anything they do not have is unfinished.

## A case that fails the test

Here is a case Ana wrote on her first morning, before lesson 2's shape had become a habit. It is
not careless. Everything in it was clear to her when she wrote it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-questions\" aria-label=\"A first draft of a test case with four rows. Title: Booking works. Precondition: logged in as a member. Steps: book some tickets for a show and check the total. Expected: booking successful and the price is correct. Numbered markers beside the rows point to eight questions a stranger has to ask. Beside the precondition: 1, log in where, there is no log-in page; 2, which member account; 8, starting from what state. Beside the steps: 3, which show; 4, how many is some; 5, is Student ticked or not. Beside the expected result: 6, which total is correct; 7, what does successful look like.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">TC-BOOK-04, first draft</text><rect x=\"20.0\" y=\"38.0\" width=\"340.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"51.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">title</text><text x=\"124.0\" y=\"51.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Booking works</text><rect x=\"20.0\" y=\"74.0\" width=\"340.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">precondition</text><text x=\"124.0\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Logged in as a member</text><circle cx=\"378.0\" cy=\"87.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"378.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">1</text><circle cx=\"402.0\" cy=\"87.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"402.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">2</text><circle cx=\"426.0\" cy=\"87.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"426.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">8</text><rect x=\"20.0\" y=\"110.0\" width=\"340.0\" height=\"41.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"130.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">steps</text><text x=\"124.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Book some tickets for a show</text><text x=\"124.0\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">and check the total.</text><circle cx=\"378.0\" cy=\"130.5\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"378.0\" y=\"130.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">3</text><circle cx=\"402.0\" cy=\"130.5\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"402.0\" y=\"130.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">4</text><circle cx=\"426.0\" cy=\"130.5\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"426.0\" y=\"130.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">5</text><rect x=\"20.0\" y=\"161.0\" width=\"340.0\" height=\"41.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"181.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">expected</text><text x=\"124.0\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Booking successful and</text><text x=\"124.0\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the price is correct.</text><circle cx=\"378.0\" cy=\"181.5\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"378.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">6</text><circle cx=\"402.0\" cy=\"181.5\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"402.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">7</text><text x=\"456.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">what the stranger has to ask</text><circle cx=\"466.0\" cy=\"52.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"484.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Log in where? There is no log-in page.</text><circle cx=\"466.0\" cy=\"82.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">2</text><text x=\"484.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Which member account?</text><circle cx=\"466.0\" cy=\"112.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">3</text><text x=\"484.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Which show?</text><circle cx=\"466.0\" cy=\"142.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">4</text><text x=\"484.0\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">How many is some?</text><circle cx=\"466.0\" cy=\"172.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">5</text><text x=\"484.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Is Student ticked or not?</text><circle cx=\"466.0\" cy=\"202.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">6</text><text x=\"484.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Which total is correct?</text><circle cx=\"466.0\" cy=\"232.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">7</text><text x=\"484.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">What does successful look like?</text><circle cx=\"466.0\" cy=\"262.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">8</text><text x=\"484.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Starting from what state?</text></svg>", "caption": "Ana's first draft, read by somebody who has never seen boxoffice. Four lines raise eight questions, and the expected result raises the two that decide the verdict."}
```

Now run it as the stranger, line by line, and write down every question it forces.

**The precondition** says *logged in as a member*. The stranger looks for a sign-in page, and
boxoffice has none: booking asks for an e-mail address and nothing else (1). Whose address? The
stranger does not know that `member@example.org` exists, and *a member* could be any account (2).
And from what state? Has anything been booked already, is the application freshly started (8)?

**The steps** say *book some tickets for a show*. Which show, out of three (3)? How many is
*some* (4)? The booking form also has a box marked Student (half price), which the case does not
mention, and ticking it halves the price (5).

**The expected result** says *the price is correct*. Correct according to what (6)? The stranger
has never read R5 and cannot work out that a member pays 10% less. *Booking successful* is no help
either, because no page of boxoffice says those words (7). The page that appears says an order is
reserved. Is that success? Probably. The case does not say.

Eight questions from four lines.

## What happens to each question

A question in a case ends one of two ways. **The stranger asks**, which costs your time, and only
works when you are there to answer; at eleven at night you are not. Or **the stranger guesses**,
and the case runs. That second outcome is the dangerous one, because it looks like success. The
case gets a verdict, but it is the verdict of a different test from the one you meant: their show,
their quantity, their idea of a correct price.

Question 6 shows how far that goes. A stranger who cannot work out the correct total cannot check
it, so they look at whatever total appears and decide whether it looks reasonable. Say they book
three tickets for The Little Prince and the page says R$ 81,00. That looks reasonable. So would
R$ 90,00, which is what the same three tickets cost without the member discount. The case passes
either way. **A case whose expected result the runner cannot work out checks
nothing**, and nothing in its run log says so.

## The rest of this lesson

The eight questions fall into three families, and the next three sections take one each. Section 03
is about the vague words, *some*, *correct*, *successful*, and what replaces them. Section 04 is
about the data and the state, the two inputs a case has besides its steps, which the draft left
out entirely. Section 05 rewrites this case until the stranger has nothing to ask, and runs the
result. Section 06 says how you find out whether you succeeded, because that is the part nobody
can mark for you.
