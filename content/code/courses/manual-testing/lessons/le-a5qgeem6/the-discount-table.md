---
title: Running the discount table
version: 1
---

**A decision table becomes test cases one column at a time.** Each rule from section 02 of this
lesson is a case: set up the three conditions the column asks for, place one order, and compare
the discount and the total with what the column says. This section runs all eight on boxoffice and
finds the third defect of the course in the column that the requirement's hardest sentence
governs.

## Making each condition true or false

Each condition needs a way to be set, and it is worth deciding them before the first order, since a
case is only as good as its setup:

- **student**: the booking form has a checkbox, *Student (half price)*. Ticked is Y. From the
  terminal, it is the field `student=on` in the request; leaving the field out is N;
- **member**: R5 calls a confirmed account a member. The seeded account, `member@example.org`, is
  confirmed, so it is Y. For N you need an account that exists, since R4 lets nobody else book, and
  has not been confirmed: sign up a new one and ignore the e-mail it sends;
- **5 tickets or more**: 5 for Y and 2 for N, as section 02 chose.

Every order is for Hamlet, at R$ 80,00 a ticket, so the expected totals are easy to work out by
hand: the number of tickets, times 80, less the discount. Five tickets at full price are
R$ 400,00, two are R$ 160,00.

| rule | student | member | 5+ | expected discount | expected total |
|---|---|---|---|---|---|
| 1 | Y | Y | Y | 50% | R$ 200,00 |
| 2 | Y | Y | N | 50% | R$ 80,00 |
| 3 | Y | N | Y | 50% | R$ 200,00 |
| 4 | Y | N | N | 50% | R$ 80,00 |
| 5 | N | Y | Y | 15% | R$ 340,00 |
| 6 | N | Y | N | 10% | R$ 144,00 |
| 7 | N | N | Y | 15% | R$ 340,00 |
| 8 | N | N | N | 0% | R$ 160,00 |

The expected totals are written down before anything runs. A tester who works them out afterwards,
looking at what boxoffice charged, is checking that a number looks plausible, and a wrong discount
on a bill always looks plausible.

## Running it

Restart boxoffice, then create the non-member. In the browser, open **Sign up** and create an
account for `caio@example.org` with any name and a password of eight characters or more. From the
terminal:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Caio Lima&email=caio@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to caio@example.org.</p>
```

Now the eight orders. In the browser, each is a booking on the **Book** page with the e-mail, the
show, the quantity and the checkbox set as its column says; the order's page then shows a line like
*Hamlet, 5 ticket(s), 50% off:* with the total under it. In the terminal, `grep -A1 'off:'` prints
that line and the one after it, which holds the total. The orders run in the table's order, rule
1 first:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=5&student=on' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 5 ticket(s), 50% off:
<strong>R$ 200,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 2 ticket(s), 50% off:
<strong>R$ 80,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=5&student=on' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 5 ticket(s), 50% off:
<strong>R$ 200,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 2 ticket(s), 50% off:
<strong>R$ 80,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=5' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 5 ticket(s), 25% off:
<strong>R$ 300,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 2 ticket(s), 10% off:
<strong>R$ 144,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=5' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 5 ticket(s), 15% off:
<strong>R$ 340,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 2 ticket(s), 0% off:
<strong>R$ 160,00</strong></p>
```

Seven of the eight match the table. **Rule 5 does not**: a member buying five tickets got 25% off
and paid R$ 300,00, where R5 asks for 15% and R$ 340,00. The 25 is 10 and 15 added together,
exactly what "discounts do not add up" rules out. Every order like it costs the theatre R$ 40,00 on
a show at R$ 80,00, and it happens to the customers the theatre most wants: members who bring a
group.

## Why the table found it

Look at what the three-case plan from section 02 would have run. A student alone is rule 4, and it
passed. A member buying two tickets is rule 6, and it passed. Five tickets for a non-member is rule
7, and it passed. Each discount works on its own. **The defect lives only where two of them meet**,
and a plan that tests each condition separately never puts them together. The table did not need
anybody to guess that rule 5 was the dangerous one; it listed all eight, and rule 5 was among them.

Rules 1 and 3 are combinations too, a student who is also a member or buying five, and they passed:
half price won as R5 says it should. That is a result worth having. It says the problem is not
"discounts combine wrongly" in general, but specifically the member and quantity discounts, which
narrows it the way section 04 of lesson 4 narrowed the quantity limit:

| | |
|---|---|
| requirement | R5: discounts do not add up; the largest one applies |
| steps | as member@example.org, book 5 tickets for Hamlet, Student not ticked |
| expected | 15% off, R$ 340,00 |
| actual | 25% off, R$ 300,00 |
| narrowed | rules 1, 3, 6 and 7 pass: a student's 50% wins over both, and each of 10% and 15% is right alone |

Rui's fix to the discount is in release 1.1, which lesson 9 checks, and lesson 10 runs this same
table again on 1.1 to see whether the fix left everything else where it was. A table that is kept,
with its expected column, is a regression suite waiting to be run, and that is one more argument
for writing it down rather than holding it in your head.
