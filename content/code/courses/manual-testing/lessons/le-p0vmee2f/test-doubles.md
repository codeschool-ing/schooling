---
title: Stubs, mocks, fakes and a fake clock
version: 1
---

A test often needs something it cannot control. It wants to check what happens at 19:30 on the
day of a show, and the clock says 14:00. It wants to know that sign-up sends an e-mail, and nobody
wants a test sending real e-mail. The usual answer is a **test double**: a stand-in that takes the
place of the real thing for the length of a test, the way a stunt double takes an actor's place
for one scene. The name and the family of words below come from Gerard Meszaros's book on test
patterns, and they are the words developers will use around you.

## Three kinds, by what they do

The word "mock" is commonly used for all of them. The distinctions are worth having, because each
kind answers a different question.

| double | what it does | in or around boxoffice |
|---|---|---|
| stub | gives canned answers, and nothing else | a payment service that always says "approved", so a test of the order page never touches a card |
| mock | records how it was called, so the test can check the calls | a `send` that sends nothing and remembers every address it was given |
| fake | a working, simpler version of the real thing | the outbox, which keeps every e-mail in memory instead of passing it to a mail server |

A **stub** is about the answer the code gets back. A **mock** is about what the code asked for. A
**fake** behaves like the real thing well enough to use, and takes a shortcut that would be wrong
in production. You have been using a fake since lesson 1: the outbox at `/outbox` is boxoffice's
test build replacing a mail server, and lesson 22 is about what that costs.

## A mock, in a test file

Here is a mock doing its job. Sign-up should send one confirmation e-mail to the new address. The
test replaces boxoffice's `send` with a mock for the length of one sign-up, then asks the mock what
happened. Save it as `test_signup.py` beside the others:

```schooling-example
{"language": "python", "file": "test_signup.py", "parts": [
 {"code": "import unittest\nfrom unittest import mock\n\nimport boxoffice\n\n", "note": "`unittest.mock` is the standard library's kit of test doubles. This time the whole module is imported, because the test has to reach inside it."},
 {"code": "class SignupTest(unittest.TestCase):\n\n    def test_signup_sends_one_email(self):\n        with mock.patch.object(boxoffice, \"send\") as send:\n            boxoffice.signup({\"name\": \"Caio\", \"email\": \"caio@example.org\",\n                              \"password\": \"long-enough\"})\n", "note": "For the length of the `with` block, `boxoffice.send` is replaced by a mock that sends nothing and remembers every call. Then a sign-up runs, exactly as the form would trigger it."},
 {"code": "        send.assert_called_once()\n        self.assertEqual(send.call_args.args[0], \"caio@example.org\")\n        self.assertEqual(boxoffice.OUTBOX, [])", "note": "The checks are about the conversation, not a result: one e-mail was asked for, addressed to Caio, and nothing reached the outbox, because the real `send` never ran."}
]}
```

Run it on its own by naming it:

```
ana@laptop:~/boxoffice$ python3 -m unittest -v test_signup
test_signup_sends_one_email (test_signup.SignupTest.test_signup_sends_one_email) ... ok

----------------------------------------------------------------------
Ran 1 test in 0.001s

OK
```

It passes, and look at what it did not need: no server was running, and nothing reached the outbox. The test checked the conversation between `signup` and the mail
code, which is the one thing it was about. `unittest.mock` is in the standard library; other
languages have their own kits, and they all do this.

## The fake clock

boxoffice reads one setting that is a test double by any definition. `BOXOFFICE_NOW` pins the
application's clock to a moment you choose, so a test does not have to wait for one. R4 says
booking for a show closes an hour before it starts. To check that on the real clock you would have
to be at your desk between 19:00 and 20:00 on the day of The Seagull. With a fake clock it takes a
restart.

In the server's terminal, stop boxoffice and start it with the clock set to 19:30:

```
ana@laptop:~/boxoffice$ BOXOFFICE_NOW=2026-10-10T19:30:00-03:00 python3 boxoffice.py
boxoffice 1.1 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

Then book two tickets for The Seagull from the second terminal:

```
ana@laptop:~$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Booking for this show has closed.</p><form method="post" action="/book">
```

Closed, as R4 says. Restart it at 18:30 and the same request goes through:

```
ana@laptop:~$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
```

The shows are scheduled from the pinned date, so on a computer set to São Paulo time these
transcripts come out the same whatever today's date is; lesson 21 is about what changes elsewhere. On Windows the variable is set before the command instead:
`$env:BOXOFFICE_NOW = "2026-10-10T19:30:00-03:00"` in PowerShell, then `python boxoffice.py`. That
line was not run for this course. To go back to the real clock, close that terminal, or run
`Remove-Item Env:BOXOFFICE_NOW`; on Linux and macOS the variable only applied to the one command.

## What a double can hide

**A double is a claim that the real thing behaves like it**, and every test that uses one rests on
that claim. If the payment stub always says "approved", no test of the order page has ever seen a
declined card. If the mock of `send` accepts any address, a sign-up that sends to the wrong one
passes. The clock is the subtle one: a fixed moment hides everything that depends on where the
machine is in the world, and lesson 21 uses `BOXOFFICE_NOW` to show a defect that only exists on
some machines.

That is why the layers above exist. The doubles make the lower layers fast and steady, and the
system tests of this course run the real clock, the real form and a real browser, where nothing is
standing in for anything. For a manual tester the useful habit is one question about every green
suite: **what was replaced, and has anyone checked the real one?**
