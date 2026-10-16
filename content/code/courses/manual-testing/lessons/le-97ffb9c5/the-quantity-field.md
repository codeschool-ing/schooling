---
title: The quantity field
version: 1
---

**R4 is the requirement with a number in it that the theatre cares about most**: "1 to 6 tickets
per order". It decides how many seats one person can take off sale at a time, and lesson 1 put the
price of an order, which depends on the quantity, at the top of its risk grid. This section draws
the field's partitions, chooses its boundary values, runs them, and finds the first defect of the
course.

## Partitions and boundaries for R4

The quantity is a whole number of tickets, so its partitions are three ranges, the same shape as
R2's lengths:

- **0 or fewer**, invalid: nobody books no tickets, and a negative number is not a quantity;
- **1 to 6**, valid: the order is reserved;
- **7 or more**, invalid: refused with a sentence saying how many are allowed.

There is a fourth partition, input that is not a whole number at all, and section 05 of this lesson
gives it a section of its own. The two lines between the three ranges give four boundary values, 0
and 1, 6 and 7, and one representative from the middle of the valid range, 3, makes five cases:

| case | value | partition | expected (R4, R7) |
|---|---|---|---|
| Q1 | 0 | 0 or fewer | refused, with a sentence |
| Q2 | 1 | 1 to 6, lower edge | order reserved |
| Q3 | 3 | 1 to 6, middle | order reserved |
| Q4 | 6 | 1 to 6, upper edge | order reserved |
| Q5 | 7 | 7 or more | refused, with a sentence |

Everything else in each case is valid and fixed: the member's account, `member@example.org`, which
R4 requires, and Hamlet, a week away, so neither the closing time nor the seats left can interfere.
Each case changes one thing, the quantity.

## Running the five

Restart boxoffice first, so its seats and orders are the ones lesson 1 describes. In the browser,
open **Book**, type `member@example.org` in the e-mail field, choose **Hamlet**, type the quantity
in the field marked *Tickets (1 to 6)* and press **Book**. A booking that worked opens a page
headed with the order's number; one that was refused comes back to the form with a sentence above
it. From the terminal, each case is one request, and `grep msg` keeps the line with that sentence:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=0' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=1' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=3' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1002 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=6' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=7' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
```

Four of the five behave: 0 and 7 are refused with a sentence, 1 and 3 reserve orders 1001 and 1002.
**Q4 fails.** Six tickets is inside the range R4 allows and boxoffice refuses it, with a sentence
that contradicts the refusal: "You can book 1 to 6 tickets." A customer who wants six tickets for
a family is told they may have six, and cannot have them.

Notice which cases found it. The middle value, 3, was booked. A tester who partitioned the field and
stopped there would have reported R4 as working. Q5 behaved too: 7 was refused, as it should be. The
defect sits exactly on the upper boundary, in the one value two-value analysis puts on the valid
side of that line, and nowhere else.

## Saying exactly where the line is

**A failed boundary case raises a question before it is written up: where is the line really?**
"6 is refused" could mean the limit is 5, or that something about 6 is special, or that every
number above some value fails. One more case answers it. Five tickets, on a server where orders
1001 and 1002 already exist:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=5' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1003 reserved.</p>
```

Five is booked and six is not, so boxoffice draws its upper line between 5 and 6 where R4 draws it
between 6 and 7. That is the classic boundary defect: the line exists, and it is off by one. The
sentence a tester writes now is precise enough for a developer to go straight to the comparison
that draws it, without reading a word of the program:

| | |
|---|---|
| requirement | R4: 1 to 6 tickets per order |
| steps | as member@example.org, book Hamlet with a quantity of 6 |
| expected | the order is reserved |
| actual | refused: "You can book 1 to 6 tickets." |
| narrowed | 5 is reserved; 7 is refused; the upper limit is 5, not 6 |

That table is a case result, not yet a defect report. Lesson 15 turns results like it into reports
a stranger can replay, and Rui's fix arrives in release 1.1, which lesson 9 checks.

The defect also changes the plan for the next lesson. R5 gives 15% off "an order of 5 or more
tickets", and with six refused, five is the only quantity in R4's range that reaches that discount.
Lesson 5 uses five for exactly that reason, and a tester who had not run Q4 would discover the
limit halfway through building a different table.
