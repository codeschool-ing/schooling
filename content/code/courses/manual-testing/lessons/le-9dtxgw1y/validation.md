---
title: Validation, when the need is not written down
version: 1
---

Validation is often treated as the client's job, done once at the end, when the theatre's manager
tries the finished product and says yes or no. That afternoon matters, and lesson 12 is about it.
It is also the most expensive moment to learn that the product is the wrong one, because by then
everything has been built. **Validation is a question asked throughout a project, and a tester can
start asking it as soon as there is a requirement and a person who has the need.**

The difficulty is the one section 02 of this lesson named: the thing to compare the product with is
not on paper. So validation works by bringing the product, or a picture of it, into contact with
the need.

## Ways of asking

Five ways cover most projects, roughly in the order a project meets them:

- *a walkthrough of a real case*: sit with the manager and follow one real customer through the
  requirements, step by step, out loud;
- *a sketch or prototype*: show the booking page on paper before it is built, and ask the box
  office staff what is missing;
- *watching somebody use it*: one regular of the theatre books a ticket while you watch and say
  nothing, and you write down every hesitation;
- *acceptance testing*: the client tries the product against their own criteria before it goes
  live, which is lesson 12;
- *a pilot*: one show is sold through the new system while the old way still works, and afterwards
  somebody looks at what customers did and what they complained about.

Each of them puts a person with the need in front of something concrete. **A requirement read in
a meeting rarely provokes an objection; a page that refuses a booking the manager makes every week
does.**

## A journey instead of a requirement

A tester working alone cannot validate, but can prepare the evidence that makes validation quick.
The tool is the scenario, a real kind of customer trying to do a real thing from start to finish,
rather than one requirement at a time. A requirement-by-requirement pass asks whether R4's limit
works. A journey asks whether the people the theatre sells to can buy what they came for.

The Little Prince plays on Sunday at 16:00, with 200 seats, and it is a children's play. One kind
of customer the theatre will certainly meet is a teacher booking her class. Ana tries it: the
member's account, The Little Prince, thirty tickets.

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=30' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
```

In the browser, the Book page answers with the same sentence above the form. As verification,
this passes twice: R4 says 1 to 6 tickets per order, and R7 asks for a sentence rather than an
error page. Lesson 4 found that the limit also refuses six, which is a separate defect against R4
and changes nothing here. As a journey, it fails at the first step: the teacher can book her class
in five orders of six, if she thinks of it, or she can phone, if the theatre answers on Sundays.

## A finding with no expected result

What Ana has is not a failed test, because no requirement says what should have happened. It is a
question about the requirement, and it comes with what the person who decides needs to decide it:

- *the journey*: a teacher books thirty seats for one show;
- *what happens*: R4 refuses every order above six, with the captured sentence;
- *who it affects*: every group above six, and The Little Prince more than the others;
- *what it might mean*: the limit could be deliberate, to stop one buyer taking a whole show, or
  an oversight; only the theatre knows which.

**A validation finding offers readings, not a verdict**, which is what the last line is for.
The limit of six may exist for a good reason that nobody wrote down, and if so the answer is a
sentence in R4 explaining it and perhaps a note on the page telling groups to phone. Ana's job is
to make sure the question was asked by somebody who could answer it, and section 05 of this lesson
says where she sends it.

## Validation is not taste

One trap is particular to testers. Having used the product more than anyone, a tester holds strong
views about how it should behave, and it is easy to call a preference a need. The difference is
evidence. "I would put the price before the date" is a preference. "Three of the five regulars
who booked while I watched scrolled past the price and asked what the tickets cost" is a finding
about the need, and it can be argued with.
