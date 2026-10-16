---
title: Writing the first cases
version: 1
---

This section writes the cases section 03 named for sign-up, confirmation and booking. Each one was
written the way section 02 says: **the expected result first, from the requirement, with the
application stopped.** Read them for their shape before their content. Every precondition says
only what the result depends on, every step is one action, and every expected result can be
checked by looking at the screen.

TC-BOOK-01 is the case section 02 used as its example, so it is not repeated here.

## Sign-up

| field | TC-SIGNUP-01 |
|---|---|
| title | An account is created with a valid name, e-mail and password |
| requirement | R2, R3 |
| precondition | boxoffice 1.0 is running. No account uses `ana@example.org`; a fresh start has only `member@example.org`. |
| test data | name `Ana Lima`; e-mail `ana@example.org`; password `boxoffice-2026` |
| steps | 1. Open `http://127.0.0.1:8000/signup`. 2. Type the name in Name. 3. Type the e-mail in E-mail. 4. Type the password in Password. 5. Press Create account. |
| expected result | A page titled Account created says a link was sent to `ana@example.org`. The Outbox lists one new e-mail, Confirm your account, addressed to `ana@example.org`. |

| field | TC-SIGNUP-02 |
|---|---|
| title | An e-mail address that already has an account is refused |
| requirement | R2, R7 |
| precondition | boxoffice 1.0 is running. The account `member@example.org` exists; a fresh start has it. |
| test data | name `Ana Lima`; e-mail `member@example.org`; password `boxoffice-2026` |
| steps | 1. Open `http://127.0.0.1:8000/signup`. 2. Type the name in Name. 3. Type the e-mail in E-mail. 4. Type the password in Password. 5. Press Create account. |
| expected result | The sign-up form comes back with a sentence saying that the e-mail already has an account. No e-mail is sent: the Outbox has nothing new. |

TC-SIGNUP-01 traces to R3 as well as R2, because R3 is the line that promises the e-mail. The
account being created is only half of what the theatre asked for, and **the half a customer
notices is the e-mail that never came**.

The second case's expected result checks that something did not happen. A refusal on the screen
is easy to see; a refusal on the screen while an e-mail went out anyway is the defect that matters,
and the only way to catch it is to say in the case where to look.

All the addresses end in `example.org`. That domain is reserved for documentation and examples, so
no real person ever receives a message sent to it, and a test e-mail that escapes a test
environment by mistake goes nowhere.

## Confirmation

| field | TC-CONFIRM-01 |
|---|---|
| title | The link in the confirmation e-mail confirms the account |
| requirement | R3 |
| precondition | TC-SIGNUP-01 has passed, and `ana@example.org` has not been confirmed since. |
| test data | the link in the e-mail Confirm your account, addressed to `ana@example.org` |
| steps | 1. Open `http://127.0.0.1:8000/outbox`. 2. In the newest e-mail addressed to `ana@example.org`, open the link. |
| expected result | A page titled Confirm says the account is confirmed. |

| field | TC-CONFIRM-02 |
|---|---|
| title | A confirmation link that was never sent is refused |
| requirement | R3, R7 |
| precondition | boxoffice 1.0 is running. |
| test data | the address `http://127.0.0.1:8000/confirm?token=nottherealone` |
| steps | 1. Open the address. |
| expected result | A page titled Confirm says the link is not valid. |

TC-CONFIRM-01 has another case as its precondition. That is a choice with a cost. It is
realistic, because nobody confirms an account that was never created, and it saves writing the
sign-up again. In exchange, **if TC-SIGNUP-01 fails, TC-CONFIRM-01 cannot run at all**, and section
05 of this lesson says what its status is then.

Its expected result is thinner than it looks. *The account is confirmed* is a sentence on a page,
and the page could say it without anything having changed. The proof is the member discount,
which only a confirmed account gets, and that is the job of the last case below.

## Booking

| field | TC-BOOK-02 |
|---|---|
| title | Somebody without an account cannot book |
| requirement | R4, R7 |
| precondition | boxoffice 1.0 is running. No account uses `nobody@example.org`. |
| test data | e-mail `nobody@example.org`; show Hamlet; 2 tickets; Student unticked |
| steps | 1. Open `http://127.0.0.1:8000/book`. 2. Type the e-mail in the E-mail field. 3. Choose Hamlet under Show. 4. Type `2` in the tickets field. 5. Press Book. |
| expected result | The booking form comes back with a sentence saying to sign up first. No order is made: Hamlet's seats left are the same as before. |

| field | TC-BOOK-03 |
|---|---|
| title | An account confirmed today books at the member price |
| requirement | R3, R4, R5 |
| precondition | TC-CONFIRM-01 has passed. The Little Prince has 200 seats left. |
| test data | e-mail `ana@example.org`; show The Little Prince; 2 tickets; Student unticked |
| steps | 1. Open `http://127.0.0.1:8000/book`. 2. Type the e-mail in the E-mail field. 3. Choose The Little Prince under Show. 4. Type `2` in the tickets field. 5. Press Book. |
| expected result | An order is reserved for 2 tickets for The Little Prince at 10% off, R$ 54,00 in total, in the state reserved. The Shows page lists 198 seats left for The Little Prince. |

The arithmetic of TC-BOOK-03 is R5's, done before the run: two tickets at R$ 30,00 are R$ 60,00,
and 10% off makes R$ 54,00. If the confirmation in TC-CONFIRM-01 had only printed a sentence and
changed nothing, this case would show 0% off and R$ 60,00, and fail.

**Two tickets in every booking is deliberate.** Two is inside R4's range of 1 to 6 and below the
five tickets at which R5's group discount starts, so these cases check booking and the member
discount and nothing else. The quantities near the edges of the range, and the order of five or
more, are where lessons 4 and 5 spend their time.

## What they share

Six cases, plus TC-BOOK-01, and each one fits on a screen. None of them says *check that it works*
or *verify the page is correct*, because neither phrase says what to look at. Lesson 3 is a whole
lesson on the words that do that, and on what to write instead.
