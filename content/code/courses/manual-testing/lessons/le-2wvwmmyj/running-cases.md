---
title: Running the cases, and recording what happened
version: 1
---

Running a case looks like the easy half: follow the steps, look at the screen. The part that
takes discipline is the record. **A run that leaves no record cannot be told apart from a run that
never happened**, and the record is what a developer, a manager or you next week reads instead of
asking. This section runs the seven cases against boxoffice 1.0, in one sitting, and writes down
what each one did.

## Before the first case

Write down what is being tested. A verdict belongs to one version of the application in one
environment, and a pass on 1.0 says nothing about 1.1. Start boxoffice fresh, as lesson 1 section
04 shows, and ask it which version it is:

```
ana@laptop:~/boxoffice$ curl http://127.0.0.1:8000/health
ok boxoffice 1.0
```

In the browser the version is at the foot of every page, `boxoffice 1.0`.

**Then check the order the cases run in.** TC-CONFIRM-01 needs TC-SIGNUP-01 to have run, and
TC-BOOK-03 needs TC-CONFIRM-01, so those three go in that order. The others only need the state
their preconditions name, and one fresh start gives all of them. The run below takes them in the
order section 04 lists them, against one server that is not restarted in between.

The transcripts are the same steps sent with curl, kept as evidence. In the browser you fill in the
forms the steps describe; the line to compare is the message in the middle of the page.

## Sign-up

TC-SIGNUP-01 fills in the sign-up form with Ana's details. The browser shows a page called Account
created:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana+Lima&email=ana@example.org&password=boxoffice-2026' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to ana@example.org.</p>
```

The first half of its expected result holds, and the second half is in the Outbox, which the next
case checks too. TC-SIGNUP-02 fills in the same form with the member's address, and gets the form
back with a sentence at the top. Then the Outbox is counted:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana+Lima&email=member@example.org&password=boxoffice-2026' http://127.0.0.1:8000/signup | grep msg
<p class="msg">There is already an account with that e-mail.</p><form method="post" action="/signup">
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/outbox | grep -c '<article>'
1
```

One e-mail in the Outbox settles two expected results at once: TC-SIGNUP-01 sent one, and
TC-SIGNUP-02 sent none. In the browser, the Outbox page shows a single e-mail, Confirm your
account, to `ana@example.org`.

## Confirmation

TC-CONFIRM-01 opens the Outbox and follows the link in that e-mail:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/outbox | grep -E 'h2|token'
<article><h2>Confirm your account</h2><p>To: ana@example.org · 2026-10-10 14:00</p><pre>Hello Ana Lima,
http://127.0.0.1:8000/confirm?token=nbm7nh5xugmf6rdv
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=nbm7nh5xugmf6rdv' | grep msg
<p class="msg">Your account is confirmed.</p>
```

Your link ends in a different token from Ana's; the case names the e-mail, not the token, so it
does not matter. TC-CONFIRM-02 opens a link nobody sent:

```
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=nottherealone' | grep msg
<p class="msg">This link is not valid.</p>
```

## Booking

TC-BOOK-01 books two Hamlet tickets as the member, and then looks at the Shows page:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -A3 'class="msg"'
<p class="msg">Order 1001 reserved.</p>
<p>Hamlet, 2 ticket(s), 10% off:
<strong>R$ 144,00</strong></p>
<p>State: <strong>reserved</strong></p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<tr><td>[^<]*</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'
<tr><td>The Seagull</td><td>2026-10-10 20:00</td><td>R$ 60,00</td><td>120</td>
<tr><td>Hamlet</td><td>2026-10-17 20:00</td><td>R$ 80,00</td><td>78</td>
<tr><td>The Little Prince</td><td>2026-10-18 16:00</td><td>R$ 30,00</td><td>200</td>
```

In the browser that is an Order page with the total in bold, and on the Shows page Hamlet's last
column reads 78. TC-BOOK-02 tries the same booking with an address nobody signed up with:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=nobody@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Sign up before you book.</p><form method="post" action="/book">
```

TC-BOOK-03 books as Ana, whose account TC-CONFIRM-01 confirmed, and the Shows page is read once
more:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=ana@example.org&show=S3&quantity=2' http://127.0.0.1:8000/book | grep -A3 'class="msg"'
<p class="msg">Order 1002 reserved.</p>
<p>The Little Prince, 2 ticket(s), 10% off:
<strong>R$ 54,00</strong></p>
<p>State: <strong>reserved</strong></p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<tr><td>[^<]*</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'
<tr><td>The Seagull</td><td>2026-10-10 20:00</td><td>R$ 60,00</td><td>120</td>
<tr><td>Hamlet</td><td>2026-10-17 20:00</td><td>R$ 80,00</td><td>78</td>
<tr><td>The Little Prince</td><td>2026-10-18 16:00</td><td>R$ 30,00</td><td>198</td>
```

That one reading closes two cases. The Little Prince went from 200 to 198 for TC-BOOK-03, and
Hamlet still reads 78, so TC-BOOK-02's refused booking took no seats.

## The record

Every case gets one of four statuses:

- **passed**: the actual result matched the expected result, all of it;
- **failed**: some part of it did not match;
- **blocked**: the case could not run, because something it depends on failed or is missing. Had
  TC-SIGNUP-01 failed, TC-CONFIRM-01 and TC-BOOK-03 would be blocked, not failed, because nothing
  about confirmation would have been checked;
- **not run**: nobody got to it.

**Blocked and failed are kept apart on purpose.** Counting a blocked case as failed reports three
defects where there is one, and counting it as passed reports a feature as working that nobody
looked at. Here is Ana's record of the run:

| case | status | note |
|---|---|---|
| TC-SIGNUP-01 | passed | |
| TC-SIGNUP-02 | passed | "There is already an account with that e-mail." |
| TC-CONFIRM-01 | passed | |
| TC-CONFIRM-02 | passed | |
| TC-BOOK-01 | passed | order 1001 |
| TC-BOOK-02 | passed | "Sign up before you book." |
| TC-BOOK-03 | passed | order 1002 |

Above it she wrote the date, 2026-10-10, the build, `boxoffice 1.0`, and the environment: her
laptop, with the steps sent from curl. The notes keep what the case left open on purpose, such as
the exact wording of a refusal and the order numbers, so a question about this run next week has an
answer.

## When a case fails, ask about the case first

Ana's first draft of TC-BOOK-01 expected R$ 160,00, and the run said R$ 144,00. That is a failure,
and it is not yet a defect. **The first question about a failure is whether the case is right**,
and the requirement answers it: R5 gives a member 10% off, two Hamlet tickets are R$ 160,00, and
10% off that is R$ 144,00. The application was right and the case had forgotten the discount, so
the case was corrected and run again.

The question has to be settled against the requirement, never against the screen. Changing the
expected result to match whatever appeared would make the case pass, and every defect it was
written to catch would pass with it. A failure that survives the question is a defect, and lesson
15 is about reporting one.
