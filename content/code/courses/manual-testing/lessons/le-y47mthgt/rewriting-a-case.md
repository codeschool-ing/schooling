---
title: Rewriting a case until it stands alone
version: 1
---

Rewriting a vague case is tempting to do by patching: add a number here, a name there, until the
questions stop. That leaves the case's shape as it was, and the shape was part of the problem.
**A rewrite starts by deciding the one thing the case checks**, and the rest of the case is built
to check that and nothing else. This section rewrites Ana's draft from section 02 that way, then
runs the result exactly as written.

## One thing, said in the title

*Booking works* is a title that covers every booking boxoffice will ever make, and a case cannot
check all of them. Asked what she actually meant, Ana's answer was narrower: that a member who
books gets the member's price. That is one thing, and it becomes the title, with the show and the
quantity in it so that a reader of the list knows which booking this is.

The draft also hid a second case. The Student box halves the price, and a case about the member
discount has to leave it unticked, so the student price becomes a case of its own. **Splitting a
vague case into two or three clear ones is the usual result of rewriting**, and it is cheaper than
it looks: each of the new cases is short.

## The rewrite

The questions of section 02 were answered in the case, never in a message to the person running
it. Here is the result:

| field | TC-BOOK-04 |
|---|---|
| title | A confirmed member booking three tickets for The Little Prince pays 10% less |
| requirement | R4, R5 |
| precondition | boxoffice 1.0 has just been started: if it is running, stop it with Ctrl-C and start it again with `python3 boxoffice.py`. A fresh start has the confirmed account `member@example.org` and 200 seats left for The Little Prince. |
| test data | e-mail `member@example.org`; show The Little Prince; 3 tickets; Student unticked |
| steps | 1. In the browser, open `http://127.0.0.1:8000/book`. 2. In the E-mail field, type `member@example.org`. 3. In the Show list, choose The Little Prince. 4. In the field that reads Tickets (1 to 6), type `3`. 5. Leave the box Student (half price) unticked. 6. Press Book. 7. Follow the link Shows at the foot of the page. |
| expected result | After step 6: an Order page says the order is reserved, for The Little Prince, 3 ticket(s), 10% off, R$ 81,00, and State: reserved. After step 7: the row for The Little Prince reads 197 under Seats left. |

The total was worked out from the requirements before the run, as lesson 2 section 02 asks. R5
prices a ticket at the show's price, R$ 30,00 for The Little Prince, so three are R$ 90,00. A
confirmed member gets 10% off, which leaves R$ 81,00. Three tickets out of 200 leave 197.

Three tickets is a deliberate choice of data. It is inside R4's range of 1 to 6, so booking is
allowed, and below the five tickets at which R5's group discount starts, so the only discount that
can apply is the member's. A case whose data could trigger two rules at once would not say which
one it checked.

## Checking it against the questions

Every question from section 02 now has a line that answers it:

| question | answered by |
|---|---|
| 1 log in where? | step 2: there is no log-in, the booking form takes an e-mail |
| 2 which member? | the test data: `member@example.org` |
| 3 which show? | the test data and step 3: The Little Prince |
| 4 how many is some? | the test data and step 4: 3 |
| 5 is Student ticked? | step 5: unticked |
| 6 which total is correct? | the expected result: R$ 81,00 |
| 7 what is success? | the expected result: State: reserved, and 197 seats |
| 8 from what state? | the precondition, and how to reach it |

## Running it as written

A rewritten case is run once by its writer, following the words alone, before anybody else sees
it. Ana restarted boxoffice and took the steps one at a time, reading each from the case rather than
from memory. The browser showed an Order page and then the Shows page; the same requests, sent with
curl, are the evidence:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=3' http://127.0.0.1:8000/book | grep -A3 'class="msg"'
<p class="msg">Order 1001 reserved.</p>
<p>The Little Prince, 3 ticket(s), 10% off:
<strong>R$ 81,00</strong></p>
<p>State: <strong>reserved</strong></p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<tr><td>[^<]*</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'
<tr><td>The Seagull</td><td>2026-10-10 20:00</td><td>R$ 60,00</td><td>120</td>
<tr><td>Hamlet</td><td>2026-10-17 20:00</td><td>R$ 80,00</td><td>80</td>
<tr><td>The Little Prince</td><td>2026-10-18 16:00</td><td>R$ 30,00</td><td>197</td>
```

Every part of the expected result is there: reserved, three tickets, 10% off, R$ 81,00, and 197
seats left. TC-BOOK-04 passes.

The run is also the first check of the case itself. Reading each step from the page, rather than
from memory, is the closest a writer can get to being a stranger. It catches a missing step or a
control named wrongly, and it cannot catch a word the writer understands without noticing. Section
06 is about the check that can.

## What it cost

The draft was four short lines, and the rewrite is a table of six rows with seven steps. That is
the usual ratio, and it is worth paying once. **A case is written once and run many times**, by
people who were not there when it was written: on every release, after every fix, by every new
tester. Each of those runs either costs a question or risks a guess, and the extra lines are
paid for after the second run.
