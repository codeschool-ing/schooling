---
title: Testing the order's states
version: 1
---

**This section runs R6's state table on boxoffice**: the three paths that cover every valid
transition, a few of the sixteen dashes, and then the dash that harm put first in section 04 of
this lesson. It finds the fourth defect of the course, and it finds it in a cell of the table that
no ordinary customer journey passes through.

## Moving an order in the browser and in the terminal

Every order has a page of its own, at `/order?id=` and its number, and the page that opens after a
booking is that page. Under the price it shows *State:* and the order's current state, and below it
four buttons, Pay, Cancel, Use and Refund, all four always there whatever the state. Pressing one
is the event. The page that comes back carries a sentence at the top saying what happened, and the
state under the price.

From the terminal, pressing a button is a request to `/order` with the order's number and the
action, and `grep msg` keeps the sentence.

## The valid transitions

Restart boxoffice, so the orders start again at 1001. Then the three paths: order 1001 is paid and
used, order 1002 is cancelled, order 1003 is paid and refunded. Each path starts with a booking of
two tickets for Hamlet as the member:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now paid.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=use' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now used.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1002 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=cancel' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now cancelled.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1003 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1003&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now paid.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1003&action=refund' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now refunded.</p>
```

All four transitions behave, and every state after each step is the one the table predicts. That
is three passing cases, and the expected result of each was written in section 04's table before
any of them ran.

## Three dashes

With orders now sitting in four different states, the invalid cases are cheap to reach. One more
booking gives a fresh reserved order, 1004; refunding it is the dash in the reserved row. Order
1002 is cancelled and order 1003 refunded; cancelling either is a dash in a final state's row:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1004 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1004&action=refund' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is reserved cannot be refunded.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=cancel' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is cancelled cannot be canceled.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1003&action=cancel' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is refunded cannot be canceled.</p>
```

All three are refused with a sentence and leave the order where it was, which is what the dashes
say. Three of sixteen is a sample, and a sample is a choice to record: the case list should say
which cells ran.

## The dash that matters

Section 04 put refunding a used order first among the dashes, because if it worked it would do two
kinds of harm at once: money returned for a ticket somebody has already used, and the seats given
back. The case needs its own fresh start, so the seat count is clean: restart boxoffice, book two
tickets, pay, use, and read Hamlet's seats left on the home page before and after the refund. In the
browser the Shows table has a column for it. In the terminal, `grep -o` cuts Hamlet's row out of
the table:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now paid.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=use' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now used.</p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<td>Hamlet</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'
<td>Hamlet</td><td>2026-10-17 20:00</td><td>R$ 80,00</td><td>78</td>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=refund' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now refunded.</p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<td>Hamlet</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'
<td>Hamlet</td><td>2026-10-17 20:00</td><td>R$ 80,00</td><td>80</td>
```

**The refund is accepted.** A used order becomes refunded, with the same sentence a valid refund
gets, and Hamlet's seats go from 78 back to 80. R6 allows a refund only from paid, and the state
table has a dash in the used row's refund column. boxoffice treats used as if it were paid.

Read as the theatre would, both halves of the harm are real. The customer who used two tickets and
then pressed Refund gets the money back for a show they were let in to. And the two seats they sat
in go back on sale, so on a sold-out night the box office can sell the same two seats a second time
to people who will find them taken.

| | |
|---|---|
| requirement | R6: a paid order can be used, or refunded before the show starts |
| steps | book 2 tickets for Hamlet as the member; pay; use; refund |
| expected | refused with a sentence; the order stays used; seats left stay 78 |
| actual | "Order is now refunded."; seats left go back to 80 |
| narrowed | refund from paid works as it should; refund from reserved is refused |

## What the table bought

The happy path, book, pay, use, passed. So did the other two valid paths. A tester who stopped at
the transitions on the diagram would have reported R6 as working, and the defect would have been
found by the first customer who noticed that the Refund button still worked on tickets already
used at the door. It was found here because the state table turned the forbidden moves into a list, and the
harm of each one put this cell at the top of it.

Twelve dashes were not run in this section. Section 06 of this lesson asks about some of them, and
the rest are worth running on your own machine: each one is a button and a sentence to read, and one
of the sixteen has already shown that a dash is a claim boxoffice does not always keep.
