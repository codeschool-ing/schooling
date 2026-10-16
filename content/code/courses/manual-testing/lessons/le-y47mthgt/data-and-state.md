---
title: The data and the state, written down
version: 1
---

A case has two inputs besides its steps, and they are the ones writers forget, because neither
appears on the screen while the steps are being followed. **The data** is every value the steps
type or choose. **The state** is everything the application already holds when step 1 begins:
the accounts, the orders, the seats left, even the time. A stranger who uses other data, or starts
from another state, runs another test, and the case gives them no way to know.

Four runs on boxoffice show what an unwritten state does to a verdict. Each one follows steps
that are perfectly clear.

## The same steps, twice

Lesson 2's TC-BOOK-01 books two Hamlet tickets as the member. Run it twice without restarting
boxoffice in between, and look at the message each time and at the Shows page after:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1002 reserved.</p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<tr><td>[^<]*</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'
<tr><td>The Seagull</td><td>2026-10-10 20:00</td><td>R$ 60,00</td><td>120</td>
<tr><td>Hamlet</td><td>2026-10-17 20:00</td><td>R$ 80,00</td><td>76</td>
<tr><td>The Little Prince</td><td>2026-10-18 16:00</td><td>R$ 30,00</td><td>200</td>
```

The second run is order 1002, and Hamlet is at 76 rather than 78. A case that expected *Order
1001* or *78 seats left* passes the first time it runs and fails every time after, while boxoffice
behaves exactly as R4 says. That is why lesson 2 left the order number out of TC-BOOK-01 and put
*Hamlet has 80 seats left* into its precondition.

There are two ways to make a result like this hold. **State the starting point**, as TC-BOOK-01
does, so the stranger knows to restart boxoffice if it does not hold. Or **write the result
relative to the start**: *Hamlet's seats left go down by 2*. The second survives any state, and it
asks the stranger to read the number before step 1 as well as after, which the steps then have to
say.

## Data that is used up

Some data can only be used once. Lesson 2's TC-SIGNUP-01 creates an account for
`ana@example.org`. Run it a second time on the same server:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana+Lima&email=ana@example.org&password=boxoffice-2026' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to ana@example.org.</p>
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana+Lima&email=ana@example.org&password=boxoffice-2026' http://127.0.0.1:8000/signup | grep msg
<p class="msg">There is already an account with that e-mail.</p><form method="post" action="/signup">
```

The second run is no longer TC-SIGNUP-01 at all. It is TC-SIGNUP-02, the refusal of a taken
address, with Ana's address standing in for the member's. **The case consumed its own data**, and
that is why its precondition says that no account uses `ana@example.org`, and says how to make
that true: a fresh start has only the member.

## An account in another state

The draft of section 02 said *a member*. Here is the same booking made by Ana's new account,
created a moment earlier and never confirmed:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana+Lima&email=ana@example.org&password=boxoffice-2026' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to ana@example.org.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=ana@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -A3 'class="msg"'
<p class="msg">Order 1001 reserved.</p>
<p>Hamlet, 2 ticket(s), 0% off:
<strong>R$ 160,00</strong></p>
<p>State: <strong>reserved</strong></p>
```

0% off and R$ 160,00, against the member's 10% off and R$ 144,00 in lesson 2. Both are right: R5
gives the discount to a confirmed account, and this one is not. **An account is not data until its
state is written beside it**: which address, and whether it is confirmed.

## The time is state too

R4 closes booking one hour before the show, so whether a booking for tonight's show is accepted
depends on when the case runs. The same request for The Seagull, made with the application's clock
at half past seven in the evening:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Booking for this show has closed.</p><form method="post" action="/book">
```

At two in the afternoon the same request reserves an order. Both answers are correct, and a case
that books The Seagull without saying when it is run will pass for whoever runs it in the morning
and fail for whoever runs it after work. **When time is not what the case checks, it picks data
far from the edge**: Hamlet, a week away, answers the same at any hour of today. When time is what
the case checks, the precondition gives the time.

## Where the state comes from

A precondition says what must be true. The stranger also needs to know how to make it true, and
there are three ways:

- **a reset**: stop boxoffice and start it again, which gives the state lesson 1 describes, three
  shows, full seats, one confirmed member and no orders;
- **set-up steps** inside the precondition: *sign up `ana@example.org` and do not confirm it*;
- **another case**, named by its id: *TC-CONFIRM-01 has passed*.

The third is the cheapest to write and the most fragile to run, because when the earlier case
fails, this one is blocked, as lesson 2 section 05 showed. A case that has to run on its own, on a
day when nothing else has run, uses the first two. Where test data comes from on a larger system,
and how a whole suite is reset, is lesson 20.
