---
title: A minimum, and what a minimum invites
version: 1
---

The obvious way to use coverage in a team is a rule: the build fails below some percentage.
`coverage report` supports it directly with `--fail-under`, or with `fail_under` in the
configuration. Here it is set at 85%, against `shipquote`'s 81%:

```
ana@laptop:~/shipquote$ coverage run -m pytest -q > /dev/null; coverage report --fail-under=85 | tail -1; echo "exit status $?"
Coverage failure: total of 81 is less than fail-under=85
exit status 0
ana@laptop:~/shipquote$ coverage report --fail-under=85 > /dev/null; echo "exit status $?"
exit status 2
```

The first command printed the failure message and then `exit status 0`. The second printed
`exit status 2`. Same report, same threshold, and the difference is the pipe: `| tail -1` makes the
line's status the status of `tail`, which succeeded. **A pipeline step written like the first line
passes with coverage below the minimum.** Lesson 1 section 14 warned about this with pytest's exit
status 5, and lesson 5 shows how a CI shell is configured so that it cannot happen.

## What the minimum invites

Now somebody needs the build green by the end of the day. They add one file:

```python
from unittest import mock

from shipquote.carrier import CarrierClient
from shipquote.mailer import SmtpMailer


def test_the_client_can_be_used():
    try:
        CarrierClient("http://carrier.example", "t",
                      opener=mock.MagicMock()).rate("01310100", 1)
    except Exception:
        pass


def test_the_mailer_can_be_used():
    with mock.patch("smtplib.SMTP"):
        SmtpMailer("smtp.example").send("bia@example.org", "s", "b")
```

```
ana@laptop:~/shipquote$ coverage run -m pytest -q | tail -1; coverage report | tail -1
43 passed, 2 skipped in 1.67s
TOTAL                     164     14     24      4    90%
ana@laptop:~/shipquote$ coverage report --fail-under=85 > /dev/null; echo "exit status $?"
exit status 0
```

**90%, and the threshold passes.** The two tests execute the carrier client and the mailer and
check nothing at all; the first even swallows whatever exception the client raises. Every line they
touch is now "covered". The contract test from lesson 2 is still skipped, so `CarrierClient` is no
better tested than an hour ago, and the report now says otherwise.

This is Goodhart's law in miniature: **when a measure becomes a target, it stops being a good
measure.** Nobody meant to deceive anyone. The rule asked for a number and the number was the
cheapest thing to change.

## What this repository does instead

The project that publishes this course states its rule in `CLAUDE.md`:

> **Coverage is not a target.** Do not add tests to raise a percentage. Add the test that would
> have caught the failure you just found, and the one for the failure mode you can name. (X-04)

That rule keeps coverage as a **diagnostic**: something you read to find blind spots, not
something you are scored on. Teams that do want a gate usually choose one of two milder forms:

- **a ratchet**: the build fails only if coverage *drops* below what main has today, so it can
  only stay or rise, and nobody is asked to reach an arbitrary number in one go;
- **coverage of the change**: the lines a pull request added must be covered, whatever the
  total, which is the next section.

Neither is immune to the file above. A gate on a number can always be met by tests that check
nothing, which is why the review of a test is about its assertions, and why section 05 exists.
