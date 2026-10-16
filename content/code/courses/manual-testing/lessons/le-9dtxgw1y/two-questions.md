---
title: Two questions about one program
version: 1
---

Verification and validation are often used as two words for one thing, checking, with one of them
picked because it sounds more formal. They are two different questions, and the difference decides
who can answer each. **Verification asks whether the product matches what was specified: are we
building it right? Validation asks whether what was specified is what the people who use it need:
are we building the right thing?** Barry Boehm put them that way in 1979, and the two short
questions have outlived most of what was written around them.

ISO 9000 says the same in longer words. Verification is confirmation, with objective evidence, that
*specified requirements* have been fulfilled; validation is the same confirmation for *the
requirements of a particular intended use*. The first phrase points at a document. The second
points at a person doing something.

## What each one compares with

Every test compares the product with something. What differs between the two is the something.

Verification compares boxoffice with R1 to R9. The question has an answer on paper: R5 gives a
member 10% off, so a member booking two tickets for Hamlet, at R$ 80,00 each, should pay
R$ 144,00. With boxoffice running, in a second terminal:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -A2 msg
<p class="msg">Order 1001 reserved.</p>
<p>Hamlet, 2 ticket(s), 10% off:
<strong>R$ 144,00</strong></p>
```

In the browser it is the Book page with the member's address, Hamlet and 2 in the tickets field,
and the order page that follows says the same: 10% off, R$ 144,00. **That is a verification**, and
its mark is that somebody who has never met the theatre's manager could run it and decide the
result, because everything the decision needs is written down.

Validation compares boxoffice with something that is not written down in full: what the theatre
and its audience need. Is 10% the discount that turns an occasional visitor into a member? Does a
member see the discount before deciding to buy, or only on the order page afterwards? Nothing in R1
to R9 answers either, and a tester cannot answer them alone. **Validation needs the people who
have the need**, or evidence of what they do.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" data-fig=\"l06-two-questions\" aria-label=\"Three boxes in a row: the need, meaning the theatre, its staff and its audience; the requirements, R1 to R9; and the product, boxoffice 1.0. The requirements are written from the need and the product is built from the requirements. A review checks the requirements and runs nothing. Verification compares the product with the requirements and asks whether it is built right. Validation compares the product with the need and asks whether it is the right thing.\"><defs><marker id=\"mt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"mt-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"70.0\" width=\"180.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"90.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the need</text><text x=\"110.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the theatre, its staff,</text><text x=\"110.0\" y=\"119.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">its audience</text><rect x=\"260.0\" y=\"70.0\" width=\"180.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"97.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the requirements</text><text x=\"350.0\" y=\"112.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">R1 to R9</text><rect x=\"500.0\" y=\"70.0\" width=\"180.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"97.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the product</text><text x=\"590.0\" y=\"112.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">boxoffice 1.0</text><path d=\"M204.0 105.0 L256.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><text x=\"230.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">written from</text><path d=\"M444.0 105.0 L496.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><text x=\"470.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">built from</text><path d=\"M310.0 66 C310.0 26 390.0 26 390.0 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-phosphor)\"></path><text x=\"350.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">review: nothing runs</text><path d=\"M590.0 144 L590.0 170 L350.0 170 L350.0 144\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-phosphor)\"></path><text x=\"470.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">verification: are we building it right?</text><path d=\"M620.0 144 L620.0 220 L110.0 220 L110.0 144\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"365.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">validation: are we building the right thing?</text></svg>", "caption": "What each activity compares. Verification and the review never leave the written requirements; validation is the only one that reaches past them to the need."}
```

## The two can disagree

The cases worth a lesson are the ones where only one of them passes.

A product can **pass verification and fail validation**. boxoffice refuses a school that wants
thirty seats for The Little Prince, exactly as R4 says it should, and the school takes its
students to another theatre. Every case passes and the theatre loses its biggest Sunday audience.
Section 04 of this lesson runs that booking.

A product can **fail verification and pass validation**. A developer departs from a requirement
because the requirement was wrong, the users are happier for it, and the requirement still says
the old thing. That is a finding too, because the next tester who reads R1 to R9 will report the
same departure as a defect, and section 05 says what to do with it.

## Who can answer which

| | verification | validation |
|---|---|---|
| asks | are we building it right? | are we building the right thing? |
| compares the product with | the specification: R1 to R9 | the need: the theatre, its staff, its audience |
| who can decide the result | anybody holding the specification | the people who have the need |
| a failure is | a defect in the product | a requirement that is wrong, or one nobody wrote |
| done with | reviews, test cases, the techniques of lessons 2 to 5 | walkthroughs, prototypes, acceptance, watching people use it |

Most of a tester's day is in the left column, and that is how it should be: a written requirement
is the one thing two people can agree to test against. The right column is where a tester adds
something nobody else on the team is placed to add, because the tester is the person who has just
used the product the way a customer would.

## Where they sit in a project

`qa-fundamentals` lesson 9 draws the V model, where each level of specification on the left has a
level of testing on the right that mirrors it. Read with these two words, every pair across the V
is a verification: a level of testing checks the product against the document opposite it. The
question the V cannot ask itself is whether the document at the top was right, and the level
closest to that question is acceptance testing, at the top right, which is lesson 12.

**Neither one is a phase that comes after coding.** Verification starts before there is any code,
by checking documents against each other and against themselves, and that is the next section.
Validation starts before there is any code as well, the day somebody shows the theatre's manager a
sketch of the booking page and asks whether that is how the box office works.
