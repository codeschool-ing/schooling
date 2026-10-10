---
title: Duplicates and rejections
version: 1
---

Two of the three new reports in section 03's triage never reached a developer. That is not waste:
**a duplicate caught at triage costs a minute, and a duplicate missed costs two people fixing one
defect**, or one person fixing it and the other report sitting open for months because nobody
remembers that it was already done. A rejection caught at triage saves a developer from changing
code that was right. Both exits need the same skill, which is telling a symptom from a cause.

## A duplicate is the same cause, not the same words

This week's report says that paying a paid order answers *"cannot be payed"*. Lesson 11's report is
titled by *"cannot be useed"*. Different words, different buttons. Before deciding, Ana reproduces both on a
fresh 1.1:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1002 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now paid.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is paid cannot be payed.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=use' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now used.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=use' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is used cannot be useed.</p>
```

(The order is 1002 because the retest in section 02 of this lesson made 1001 on the same run.)

The two messages are built the same way: the name of the action with *ed* glued on. *Paid* and
*used* come out as *payed* and *useed*. One sentence in the program makes every refusal, so **one fix mends both, and one retest checks both**. That is the
test for a duplicate: would fixing the first report fix the second? Here it would, so the new report
is closed as a duplicate and linked to lesson 11's. Lesson 11's session already met *payed* too, so
the original's steps cover both, and nothing needs copying across.

The opposite case looks more alike and is not. *A used order can be refunded* and *a refund is
accepted after the show has started* are both about refunds, both on the same page, both answered
*"Order is now refunded."* But R6 states two separate conditions, paid and before the show, and
boxoffice checks neither. A fix for the first, refusing used orders, leaves the second wide open: a
paid order can still be refunded after its show has begun, which is what lesson 11 found. **Two causes, two
reports**, even though one developer will probably fix both on the same afternoon.

Most duplicates are prevented rather than caught. **Search before you file**, with the words a
reader would use: the page, the message, the field. The title rules of lesson 15 exist partly for
this search, because a title like "error on order page" matches nothing useful and everything else.

## Rejected: the program is right

The second new report says a member booking five tickets gets 15% off and should get 25%. Ana
reproduces it:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=5' http://127.0.0.1:8000/book | grep -A1 'ticket(s)'
<p>The Little Prince, 5 ticket(s), 15% off:
<strong>R$ 127,50</strong></p>
```

The behaviour is exactly what the report says, and it is correct. R5 gives a member 10% and an
order of five or more 15%, and says **discounts do not add up: the largest one applies**. Five
tickets at R$ 30,00 are R$ 150,00, and 15% off is R$ 127,50. The reporter added the two discounts,
which is what 1.0 did and what lesson 5 reported as a defect. The report is rejected, *works as
designed*, and the reason quotes R5.

**A rejection is a sentence, never a bare state.** "Rejected" alone tells the reporter they were
wrong and not why, and they will file it again next month in different words. "Rejected: R5, the
largest discount applies; 1.0 added them, and lesson 5's report of that was fixed in 1.1" tells them, and tells
the next person who searches.

**And sometimes the reporter is right that something is wrong, just not the program.** If two
careful people read R5 two ways, the requirement is ambiguous, and that is a defect too, in a
document instead of the code. Lesson 6 called finding it verification. The response is a change to
R5's wording, agreed with the manager, so the next reader cannot misread it.

The third report, that the outbox shows every customer's e-mail, is rejected for a different
reason. The outbox exists only in the test build, as lesson 1 said when it introduced it; in
production the e-mails leave for real inboxes and no such page exists. The rejection says that, and
points at the line of the test plan that checks the real mail once, in production.

## Cannot reproduce

The exit that needs most care is the one where nobody at triage can see the defect. **"Cannot
reproduce" is a request for information, not a verdict.** It means the report and the reader's
environment differ somewhere: a version, a browser, an account in a particular state, the data
already on the machine. The report goes back to its writer with what was tried, and the writer runs it again with
lesson 15's first question in mind: which version, from what state? Only when the writer cannot
reproduce it either does it close, and even then it closes with the attempts listed, so that the
day it happens again somebody can compare.
