---
title: The regression run
version: 1
---

The suite from section 03, run on boxoffice 1.1 in the order of the risks. **Restart the
application before you begin**, so that order numbers and seats match the transcripts, and keep a
second terminal for curl. Every request below can be made in the browser too, and the prose says
what to look at there.

## The second account

The discount table needs a customer who is not a member. Sign up as Caio Lima, `caio@example.org`, on the
Sign up page, with any password of 8 characters or more, and do not confirm the account: an account nobody has
confirmed is not a member, by R5. Then open the outbox and look for the e-mail to him.

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Caio+Lima&email=caio@example.org&password=ticket-1234' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to caio@example.org.</p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/outbox | grep -o 'To: [a-z@.]*'
To: caio@example.org
```

That is row D of the suite, both checks passing: the account exists and its confirmation e-mail
reached the outbox.

## The price rules

Eight bookings for Hamlet, one per rule of the discount table: Caio or Bia, two tickets or five,
with the Student box ticked or not. The command keeps only the discount from the order page; in the
browser it is in the line above the total, *Hamlet, 2 ticket(s), 0% off*.

```
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
0% off
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=5' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
15% off
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
10% off
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=5' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
15% off
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
0% off
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=5&student=on' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
15% off
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
10% off
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=5&student=on' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
15% off
```

Against R5, rule by rule. R5 says students pay half, the member discount is 10%, an order of five
or more gets 15%, and only the largest applies:

| rule | student | member | 5 or more | R5 says | 1.1 gave | verdict |
|---|---|---|---|---|---|---|
| 1 | no | no | no | 0% | 0% | pass |
| 2 | no | no | yes | 15% | 15% | pass |
| 3 | no | yes | no | 10% | 10% | pass |
| 4 | no | yes | yes | 15% | 15% | pass |
| 5 | yes | no | no | 50% | 0% | **fail** |
| 6 | yes | no | yes | 50% | 15% | **fail** |
| 7 | yes | yes | no | 50% | 10% | **fail** |
| 8 | yes | yes | yes | 50% | 15% | **fail** |

Four failures, and **they line up on one condition**: every rule with the Student box ticked
fails, and every rule without it passes. That pattern is information in its own right. Each of the
four, on its own, says "this student was charged the wrong price"; the four together say that 1.1
ignores the box, because in every case the discount is exactly the one the same customer gets
without it. When failures line up on one condition like this, that condition is the first thing the
report names.

Before writing anything, the run finishes. A regression run stopped at the first failure leaves the
rest of the suite unknown, and the next build then needs the whole run again anyway.

## Quantity, seats and states

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=0' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=1' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1009 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=6' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1010 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=7' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S3&quantity=two' http://127.0.0.1:8000/book
500
```

Zero and seven are refused, one and six make orders 1009 and 1010, all as R4 says. The last request
asks only for the status code, `500`: the error page for a tickets field that is not a number,
known since lesson 4 and listed in Rui's notes. In the browser it is the page full of Python.

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '[0-9]*</td><td><a href="/book?show=S3'
193</td><td><a href="/book?show=S3
ana@laptop:~/boxoffice$ curl -s -d 'id=1010&action=cancel' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now cancelled.</p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '[0-9]*</td><td><a href="/book?show=S3'
199</td><td><a href="/book?show=S3
```

The number before the link to S3 on the Shows page is The Little Prince's seats left. Orders 1009
and 1010 took seven of the 200, leaving 193; cancelling order 1010 gave its six back, 199. Row B
passes.

```
ana@laptop:~/boxoffice$ curl -s -d 'id=1009&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now paid.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1009&action=use' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now used.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1009&action=refund' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now refunded.</p>
```

Pay and use pass. The refund of a used order is accepted, which R6 does not allow: the second known
defect, from lesson 5, failing exactly as reported. The run records both known defects as *fails,
as reported* and files nothing new for them.

## Is it a regression?

Section 02 said a regression needs a before. Lesson 9 kept the before: `boxoffice-1.0.py`. Start it
in a **third** terminal on another port, so the two versions run side by side:

```
ana@laptop:~/boxoffice$ BOXOFFICE_PORT=8001 python3 boxoffice-1.0.py
boxoffice 1.0 on http://127.0.0.1:8001  (Ctrl-C stops it)
```

And the same request, rule 7, to each of them, 1.0 on 8001 and 1.1 on 8000:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8001/book | grep -o '[0-9]*% off'
50% off
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
10% off
```

Same customer, same show, same tickets, same box ticked: 50% on 1.0, 10% on 1.1. **The student
discount worked on 1.0 and does not on 1.1**, so it is a regression, brought in by this release. In
the browser it is the same comparison with two tabs, `127.0.0.1:8001` and `127.0.0.1:8000`. Stop the
1.0 copy with Ctrl-C when you are done.

## Where it came from, and how far to say so

Ana found this by behaviour alone, and the report rests on behaviour: the steps, the 50% R5 and 1.0
both give, and the 10% that 1.1 gives. That is enough for Rui to act on, and the format of the
report is lesson 15's subject.

She can say one more thing, because the release was three edits she applied herself. Lesson 9
section 03 shows the new `discount`: its one line of work names the member and the number of
tickets, and the word `student` appears only in its first line, where the function receives it.
The old version began with the student rule. **A tester may point at a likely cause, labelled as a
pointer rather than a diagnosis**. "The 1.1 rewrite of `discount` may have dropped the student
rule" lets Rui confirm or correct it in a minute, and the report stays true if the cause turns out
to be somewhere else.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" data-fig=\"l10-discount-rules\" aria-label=\"The eight rules of the discount table as columns. Rows say whether the customer is a student, a member, and booking five or more, then what R5 says and what 1.1 gave. Rules 5 to 8, every rule with a student, are outlined as failures: R5 says 50% and 1.1 gave 0, 15, 10 and 15. Below, a row of marks shows that the sanity check of lesson 9 looked at rules 3 and 4 only, and the regression run of lesson 10 at all eight.\"><text x=\"164.0\" y=\"32.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rule</text><rect x=\"181.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"210.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"210.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"210.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"210.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">0%</text><text x=\"210.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">0%</text><circle cx=\"210.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"245.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"274.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"274.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"274.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"274.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes</text><text x=\"274.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">15%</text><text x=\"274.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">15%</text><circle cx=\"274.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"309.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"338.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"338.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"338.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes</text><text x=\"338.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"338.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">10%</text><text x=\"338.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">10%</text><circle cx=\"338.0\" cy=\"206.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"338.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"373.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"402.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"402.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"402.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes</text><text x=\"402.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes</text><text x=\"402.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">15%</text><text x=\"402.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">15%</text><circle cx=\"402.0\" cy=\"206.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"402.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"437.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"466.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"466.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes</text><text x=\"466.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"466.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"466.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">50%</text><text x=\"466.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">0%</text><circle cx=\"466.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"501.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"530.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"530.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes</text><text x=\"530.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"530.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes</text><text x=\"530.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">50%</text><text x=\"530.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">15%</text><circle cx=\"530.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"565.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"594.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">7</text><text x=\"594.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes</text><text x=\"594.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes</text><text x=\"594.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><text x=\"594.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">50%</text><text x=\"594.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">10%</text><circle cx=\"594.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"629.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"658.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">8</text><text x=\"658.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes</text><text x=\"658.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes</text><text x=\"658.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yes</text><text x=\"658.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">50%</text><text x=\"658.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">15%</text><circle cx=\"658.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"164.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">student</text><text x=\"164.0\" y=\"86.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">member</text><text x=\"164.0\" y=\"112.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5 or more</text><text x=\"164.0\" y=\"142.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">R5 says</text><text x=\"164.0\" y=\"168.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1.1 gave</text><text x=\"164.0\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">lesson 9, sanity</text><text x=\"164.0\" y=\"232.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lesson 10, regression</text></svg>", "caption": "The discount table on 1.1. The four failing rules are exactly the four with a student, and the sanity check had looked at two rules with none."}
```

The sanity check of lesson 9 passed, and it was right to pass: it was asked whether two fixes
worked, and they did. It looked at rules 3 and 4. The rewrite touched all eight, and the four it
broke are the ones nobody had reason to look at while checking a fix for members. That is the gap
between sanity and regression, measured on one release.
