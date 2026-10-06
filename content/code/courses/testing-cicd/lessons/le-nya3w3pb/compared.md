---
title: The five doubles side by side
version: 1
---

The names come from Gerard Meszaros's *xUnit Test Patterns*, and they are worth keeping apart
because each one answers a different question about a collaborator. Here they are against the four
things a double can do:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A grid of the five test doubles against four capabilities. A dummy has none of them. A stub answers with values set in advance. A spy answers and also records the calls. A mock answers, records and checks the calls itself. A fake answers and works for real, with behaviour of its own, without recording or checking calls.\"><text x=\"220.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">answers with</text><text x=\"220.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">values set in advance</text><text x=\"360.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">records</text><text x=\"360.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the calls</text><text x=\"500.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">checks the</text><text x=\"500.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">calls itself</text><text x=\"640.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">works for real,</text><text x=\"640.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">in a shortcut</text><text x=\"134\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">dummy</text><rect x=\"156\" y=\"75\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"220.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no</text><rect x=\"296\" y=\"75\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no</text><rect x=\"436\" y=\"75\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"500.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no</text><rect x=\"576\" y=\"75\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no</text><text x=\"134\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">stub</text><rect x=\"156\" y=\"115\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"220.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">yes</text><rect x=\"296\" y=\"115\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no</text><rect x=\"436\" y=\"115\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"500.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no</text><rect x=\"576\" y=\"115\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no</text><text x=\"134\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">spy</text><rect x=\"156\" y=\"155\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"220.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">yes</text><rect x=\"296\" y=\"155\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">yes</text><rect x=\"436\" y=\"155\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"500.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no</text><rect x=\"576\" y=\"155\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no</text><text x=\"134\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">mock</text><rect x=\"156\" y=\"195\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"220.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">yes</text><rect x=\"296\" y=\"195\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">yes</text><rect x=\"436\" y=\"195\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"500.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">yes</text><rect x=\"576\" y=\"195\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no</text><text x=\"134\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">fake</text><rect x=\"156\" y=\"235\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"220.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">yes</text><rect x=\"296\" y=\"235\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no</text><rect x=\"436\" y=\"235\" width=\"128\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"500.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no</text><rect x=\"576\" y=\"235\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"640.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">yes</text></svg>", "caption": "Each double is defined by what it does, not by the library used to build it: one Mock object can play stub, spy and mock in the same test."}
```

Read the picture from left to right as rising capability, and from the lesson's examples:

| double | in shipquote | what the test asserts |
|---|---|---|
| dummy | `mailer=None` in the refusal test | nothing about it; it should not be touched |
| stub | `StubCarrier(cents=1999)` | the result `price` returns |
| spy | `log=lines.append` | the lines recorded, read by the test |
| mock | `create_autospec(SmtpMailer)` | the calls, through the mock's own methods |
| fake | `FakeOrders()` | the result, and the state left behind |

Every double in that table runs in two files, `tests/test_carrier.py` and `tests/test_orders.py`.
Six tests, and none of them touches a network, a mail server or a disk:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_carrier.py tests/test_orders.py -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
plugins: hypothesis-6.168.5
collecting ... collected 6 items

tests/test_carrier.py::test_the_carriers_price_wins_when_it_answers PASSED [ 16%]
tests/test_carrier.py::test_the_table_is_used_when_the_carrier_is_down PASSED [ 33%]
tests/test_carrier.py::test_the_fallback_is_logged_with_the_reason PASSED [ 50%]
tests/test_carrier.py::test_a_free_order_never_asks_the_carrier PASSED   [ 66%]
tests/test_orders.py::test_placing_an_order_sends_exactly_one_confirmation PASSED [ 83%]
tests/test_orders.py::test_an_order_of_nothing_is_refused_before_anything_is_written PASSED [100%]

============================== 6 passed in 0.70s ===============================
```

## Choosing

Start from what the test is about:

- **About a result?** Use a stub to set the scene, or a fake when the collaborator has to remember
  something between calls. Assert on what came back.
- **About a call that is the behaviour**, like an e-mail sent or a paid API *not* called? Use a spy
  or a mock, built from the real class.
- **About something else entirely**, with a collaborator in the way? A dummy.

The common failure is reaching for a mock for everything because the library makes it easy. A
test full of `assert_called_once_with` checks *how* the code does its job, call by call. Change the
how without changing the result, a refactoring, and those tests break. Section 11 shows that cost.

**And none of them is the real thing.** Every double is a claim about how the collaborator behaves,
written by somebody who might be wrong. The fewer claims a test makes, the fewer ways it can be
wrong, and section 10 is how to check the claims that remain.
