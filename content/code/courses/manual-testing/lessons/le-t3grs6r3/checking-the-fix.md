---
title: Checking the fix
version: 1
---

The build is on disk. The sanity check of 1.1 is six commands long, and the first two of them have
nothing to do with either fix: **before checking a change, make sure you are looking at the build
that contains it**. A sanity check run on the old build fails for a reason that has nothing to do
with the fix, and one run on a half-saved file can pass for the same kind of reason.

## Which build is this?

Start the application again in its terminal:

```
ana@laptop:~/boxoffice$ python3 boxoffice.py
boxoffice 1.1 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

And from the second terminal, the first line of lesson 8's smoke list:

```
ana@laptop:~/boxoffice$ curl http://127.0.0.1:8000/health
ok boxoffice 1.1
```

Both say 1.1, so edit 1 went in and the server that answers is the one you just started. In the
browser the same fact is at the foot of every page, `boxoffice 1.1`. Run the rest of lesson 8's
smoke list now too; it takes a few minutes, and sanity starts only when it passes. If the version
still reads 1.0, the file was not saved or an old copy of the server is still running, and the
`Address already in use` of lesson 1 section 05 is the usual sign of the second.

## The first fix: six tickets

The defect report from lesson 4 is the script. Its steps, on the Book page: e-mail
`member@example.org`, show Hamlet, 6 in the Tickets field, press Book. In 1.0 the page answered
*You can book 1 to 6 tickets*. Now:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=6' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=7' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
```

The first request is the retest, and it passes: six tickets make order 1001. The second is the
neighbour on the far side of the boundary, and it passes too, because R4 says six at most and seven
is still refused with the same sentence. In the browser, the first one opens the page of order
1001 and the second stays on the Book page with the message above the form.

## The second fix: a member booking five

Lesson 5's report: the member books five tickets for Hamlet and gets 25% off, where R5 says the
largest single discount applies, which is 15%. Five tickets at R$ 80,00 are R$ 400,00, and 15% off
that is R$ 340,00. The command keeps the line with the discount and the line after it, which holds
the total:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=5' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 5 ticket(s), 15% off:
<strong>R$ 340,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=4' http://127.0.0.1:8000/book | grep -A1 'off:'
<p>Hamlet, 4 ticket(s), 10% off:
<strong>R$ 288,00</strong></p>
```

The retest passes: 15% and R$ 340,00, both the expected values. The neighbour is the member
booking four, where only the member discount applies: 10% of R$ 320,00 off leaves R$ 288,00, and
that is what came back. In the browser, each request opens an order page with the same line,
the discount and then the total in bold.

## The result

| check | expected | 1.1 | verdict |
|---|---|---|---|
| version | 1.1 | `ok boxoffice 1.1` | pass |
| member, Hamlet, 6 tickets | an order | order 1001 reserved | pass |
| member, Hamlet, 7 tickets | refused, R4 | *You can book 1 to 6 tickets.* | pass |
| member, Hamlet, 5 tickets | 15%, R$ 340,00 | 15%, R$ 340,00 | pass |
| member, Hamlet, 4 tickets | 10%, R$ 288,00 | 10%, R$ 288,00 | pass |

**Sanity has passed, and the two defects can be marked as verified.** Lesson 16 names that step in
a defect's life; what matters here is that Ana writes the build number beside the result, *verified
on 1.1*, because a fix is a fact about one build and the next build may lose it.

Had either retest failed, the build would go back to Rui now, with the request that failed and
what it answered, and nobody would spend the afternoon on a regression run of a build that was
going to be replaced. That is the whole reason sanity runs first.

What these six commands do not say is anything about the rest of boxoffice. Edit 2 rewrote the
function that decides every price the theatre charges, and the sanity check looked at two of its
answers: a member booking five, a member booking four. Every other combination of discounts goes
through the same three new lines and has not been tried on 1.1 by anyone. **That is the next
question, and it has a name of its own**: lesson 10 asks it with a regression run on this same
build. Leave `boxoffice-1.0.py` where it is, because that run needs it.
