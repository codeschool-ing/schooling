---
title: A session on orders
version: 1
---

This is Ana's first exploratory session on boxoffice 1.1, run on the charter from section 03, with
the notes she kept. **Run it yourself alongside**: restart the application so the order numbers
match, keep the browser and a second terminal open, and try each step before you read what she
found. The terminal transcripts show the requests with curl, and all but one of them are a button or a
form in the browser; section 04's other door explains the exception.

| | |
|---|---|
| charter | Explore the life of an order, with every action from every state, in the browser and with curl, to discover what the application allows and says that R6 and R7 do not spell out |
| tester | Ana |
| build | boxoffice 1.1, restarted at the start of the session |
| time box | 60 minutes, a short session |
| heuristics | SFDPOT's Function and Time; another door |
| known | the refund of a used order (lesson 5) |

## Function: every action from every state

R6 names four states an order can reach after it is reserved and four actions. Ana's first move is
the simplest one the charter allows: book an order and press the button R6 says should not work
yet. A reserved order cannot be used at the door, because nobody has paid for it.

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=use' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is reserved cannot be useed.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now paid.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=use' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now used.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is used cannot be payed.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=cancel' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is used cannot be canceled.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=refund' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now refunded.</p>
```

R6 holds in every row above except one: use is refused while the order is reserved, pay and use
then work, pay and cancel are refused once it is used, and the refund of a used order is accepted,
which is the defect lesson 5 already reported. Ana writes *known, seen again* beside that one and
moves on.

What the rows above say is another matter. **The refusals are worded wrongly**: *cannot be useed*,
*cannot be payed*. Nothing in R6 or R7 mentions spelling, and no script written from them would
have looked; it was the first thing on screen. Her note: *refusal message = "cannot be " + action
+ "ed"? useed, payed, canceled. Check with a state whose name I know.*

So she tries the one state whose name the application spells for her, by cancelling a fresh order
and then trying to pay it:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=1' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1002 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=cancel' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now cancelled.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is cancelled cannot be payed.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=dance' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is cancelled cannot be danceed.</p>
```

*An order that is cancelled cannot be payed.* The same sentence spells the state `cancelled`, with
two l's, and builds the action word from `pay`. **That is the mechanism showing**: the state names
are written out, and the action words are made by gluing `ed` onto whatever action arrived. The last
request is the other door from section 04: a browser shows four buttons, but curl can send any word,
and `dance` comes back as *danceed*. A customer never sees that one. It is evidence for the report,
not a second defect: it proves the sentence is assembled from whatever word arrives, which tells Rui
where to look and why every refused action is affected, whichever one a customer pressed.

Ana's note, written as a finding rather than a guess: *Defect: every refused action's message reads
`cannot be <action>ed`: useed, payed, canceled. R7 asks for a sentence saying what is wrong; these
are sentences, and two of them are not English. Seen from reserved, used and cancelled.*

## Time: what happens once the show has started

SFDPOT's T is the letter most sessions skip, and R6 has a time in it: a paid order can be refunded
**before the show starts**. Ana has tested refunds at two in the afternoon, eight hours before The
Seagull starts. The question the charter asks is what happens after it starts.

`BOXOFFICE_NOW` sets the application's clock, and lesson 1 said what it is for. Written without an
offset it is read as the machine's own local time, so the same command works anywhere. Ana stops
the application and starts it again at half past eight in the evening:

```
ana@laptop:~/boxoffice$ BOXOFFICE_NOW=2026-10-10T20:30 python3 boxoffice.py
boxoffice 1.1 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Booking for this show has closed.</p><form method="post" action="/book">
```

That is correct: R4 closes booking an hour before the show, and The Seagull starts at 20:00. But it
leaves Ana with nothing to refund, because a restart empties the application, and an order for
tonight can only be made before 19:00. **A fixed clock cannot move with an order in hand.** She
writes it as an obstacle, *the application cannot move its clock while it keeps its orders*. Then
she sets the question up the slow way, on the real clock. At ten to seven in the evening, without
`BOXOFFICE_NOW`, she starts boxoffice, books two tickets for The Seagull and pays.

```
ana@laptop:~/boxoffice$ python3 boxoffice.py
boxoffice 1.1 on http://127.0.0.1:8000  (Ctrl-C stops it)
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now paid.</p>
```

Then she leaves it running, works on something else, and comes back at a minute past eight, after
the show has started. **This transcript skips that hour**: for the course's recording, the clock of
the running application was moved from 18:50 to 20:01 from outside, by a small wrapper that
boxoffice does not offer and you do not need. It is the control the debrief in section 06 asks Rui
for. On your machine the hour is a real one.

```
ana@laptop:~/boxoffice$ curl -s -d 'id=1001&action=refund' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now refunded.</p>
```

**The refund is accepted at 20:01, a minute after The Seagull began**, where R6 allows refunds only
before the show starts. Her note:
*Defect: a paid order for S1 is refunded after S1 has started (booked and paid 18:50, refunded
20:01, one running application). R6: refund before the show starts.*

To do the same, you need an evening. Start boxoffice without `BOXOFFICE_NOW` some time before 19:00,
book and pay for The Seagull, leave the application running, and press Refund on the order page
after 20:00. The first part, with the clock fixed at 20:30, takes a minute at any time of day: stop
the application and start it with `BOXOFFICE_NOW=2026-10-10T20:30 python3 boxoffice.py`, using any
date you like, since the shows are always placed around the date the clock says. On Windows set the
variable first, `set BOXOFFICE_NOW=2026-10-10T20:30` in Command Prompt or
`$env:BOXOFFICE_NOW="2026-10-10T20:30"` in PowerShell; neither was run for this course.

## What the session leaves behind

| | |
|---|---|
| on charter | about 45 minutes; the other 15 went to the setup of the evening |
| pairs tried | 9 of the 20 action and state pairs |
| defects | refused actions read `cannot be <action>ed`; a refund is accepted after the show starts |
| known, seen again | the refund of a used order |
| issues | the application cannot move its clock while it keeps its orders |
| opportunities | the seat count after a late refund; booking at 18:59 and 19:00 exactly |

Nine of twenty pairs is honest coverage and it is written down as such: enough to see the pattern
in the messages, and not enough to say that every pair behaves. The debrief in section 06 decides
what happens to the other eleven.
