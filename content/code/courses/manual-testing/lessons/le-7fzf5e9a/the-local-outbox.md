---
title: The outbox as a mail catcher
version: 1
---

A test environment that sends e-mail for real is a hazard: one run with a copy of production data
and a few thousand customers receive a link they never asked for. **So a test build catches its
mail.** The application still composes every message and still believes it sent it, but the message
stops at a place the tester can read and goes no further. Tools that do this are called **mail
catchers**, and boxoffice has one built in: the outbox, at `/outbox`, newest message first. Lesson 1
said it was there and that this lesson would say why.

The addresses in this course help in the same direction. Every one ends in `example.org`, a domain
reserved for examples and documentation, so even a message that escaped would have nowhere to go.
Test data that uses real-looking addresses at real domains is how a stranger ends up with a
confirmation link.

## Sign up, read, confirm

Start boxoffice fresh. In the browser, open Sign up from the links at the bottom of any page, and
create an account for Caio Lima, `caio@example.org`, with any password of 8 to 64 characters. From
the second terminal the same request is:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Caio+Lima&email=caio@example.org&password=ticket-office-9' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to caio@example.org.</p>
```

Now open the Outbox link. The page shows one message, and it is the e-mail as the customer would
have received it:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/outbox | grep -A 4 '<article>'
<article><h2>Confirm your account</h2><p>To: caio@example.org · 2026-10-10 14:00</p><pre>Hello Caio Lima,

Confirm your account within 24 hours:
http://127.0.0.1:8000/confirm?token=nbm7nh5xugmf6rdv
</pre></article>
```

Read it the way case 9 asks: the right address, the right name, and a link to the address boxoffice
answers on. **Your token will be different**, a new random string on every run; the course's
transcripts come from a build started so that its tokens repeat. The link is plain text on the page,
so copy it into the address bar and open it:

```
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=nbm7nh5xugmf6rdv' | grep msg
<p class="msg">Your account is confirmed.</p>
```

That is case 1. Open the same link a second time, which is case 6:

```
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=nbm7nh5xugmf6rdv' | grep msg
<p class="msg">Your account is confirmed.</p>
```

The link still works after doing its job. **This is not a defect report**: R3 never says a link is
single use, so there is nothing to compare the result with. It goes on your list of questions for
the theatre, with the observation attached. Case 2, a token nobody issued, is refused as it should
be:

```
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=nosuchtoken' | grep msg
<p class="msg">This link is not valid.</p>
```

## Ask again, and try the old link

Cases 4 and 5 need a second link. boxoffice has no page with a form for it: asking for a new link
is a form post to `/resend` with the address, so in this course it is sent with curl. On Windows,
leave off the `| grep msg` at the end and look for the same sentence in the answer.

Create a second account, for Dora Reis, so that the first one's history does not get in the way:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Dora+Reis&email=dora@example.org&password=ticket-office-9' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to dora@example.org.</p>
```

Do not open her link. Ask for another one instead, as somebody would whose first e-mail had gone
missing:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=dora@example.org' http://127.0.0.1:8000/resend | grep msg
<p class="msg">If that account exists, we sent a new link.</p>
```

The outbox now holds three messages, newest first. Here are just the recipients and the links:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/outbox | grep -oE 'To: [^ ]+|http://[^ ]+token=[a-z0-9]+'
To: dora@example.org
http://127.0.0.1:8000/confirm?token=je8xc3gqcheyuvsv
To: dora@example.org
http://127.0.0.1:8000/confirm?token=8mp9vq2ccu5dkrb8
To: caio@example.org
http://127.0.0.1:8000/confirm?token=nbm7nh5xugmf6rdv
```

Dora's first link is the second one in the list. By R3 it stopped working when she asked for a new
one. Open it:

```
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=8mp9vq2ccu5dkrb8' | grep msg
<p class="msg">Your account is confirmed.</p>
```

**The old link confirmed the account.** R3 says it should have answered "This link is not valid."
That is defect 10, and it is worth more than it looks. The reason somebody asks for a second link is
often that the first went somewhere they do not control, an old address, a shared inbox, a mistyped
domain; a first link that keeps working for its full 24 hours keeps that door open after the person
believed they had shut it. The report needs the steps above, the expected and actual results
side by side, and the environment block from lesson 21.

Case 7 behaves as it should. An address with no account gets exactly the sentence Dora's got, so the
form tells nobody who has an account:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=nobody@example.org' http://127.0.0.1:8000/resend | grep msg
<p class="msg">If that account exists, we sent a new link.</p>
```

## Expiry, and a test that cannot fail

Case 3 asks for a link older than 24 hours, and `BOXOFFICE_NOW` looks like the way to get one: stop
boxoffice, start it a day and an hour later, and open Dora's old link.

```
ana@laptop:~/boxoffice$ BOXOFFICE_NOW=2026-10-11T15:00:00-03:00 python3 boxoffice.py
boxoffice 1.1 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

```
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=8mp9vq2ccu5dkrb8' | grep msg
<p class="msg">This link is not valid.</p>
```

It looks like a pass. Before believing it, run the **control**: the same steps with the clock where
it was, so that only the time differs.

```
ana@laptop:~/boxoffice$ BOXOFFICE_NOW=2026-10-10T14:00:00-03:00 python3 boxoffice.py
boxoffice 1.1 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

```
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=8mp9vq2ccu5dkrb8' | grep msg
<p class="msg">This link is not valid.</p>
```

The same answer with no time passing at all. **The restart wiped every link**, because boxoffice
keeps everything in memory, so the first run was refused for that reason and said nothing about
expiry. A test that gives the same result whether the behaviour is right or wrong is not a test. And
`BOXOFFICE_NOW` is read when the program starts, so it cannot move the clock of a server that is
already holding a link.

Two honest ways remain. One is the real clock: start boxoffice with no `BOXOFFICE_NOW`, sign up two
accounts and leave it running, then open the first one's link after 23 hours and the second one's
after 25. It takes a day and it is a
real test. The other is to ask Rui for a clock that can be moved while the program runs, which is
a request for testability, and lesson 13 named the idea: a fake clock the test controls. Neither was
run for this course. Until one of them is, case 3 is **not tested**, and the test report says so
with the reason, which is worth more than a pass that measured nothing.
