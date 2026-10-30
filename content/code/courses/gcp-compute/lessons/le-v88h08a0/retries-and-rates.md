---
title: Retries and rates, in seconds
version: 1
---

`min_backoff = "10s"`, `max_backoff = "300s"` and `max_doublings = 3` read like three independent
settings. **They are one rule, and the only way to know what they do to a task is to work the rule
out.** Google documents it: the first retry waits `min_backoff`, the wait doubles `max_doublings`
times, then grows by a fixed step, and never exceeds `max_backoff`.

## Working it out

A dozen lines of Python follow the rule. **Save this as `~/gcp/backoff.py`:**

```schooling-example
{"language": "python", "file": "backoff.py", "parts": [{"code": "import sys\n\n\n", "note": "One module, to read the command line."}, {"code": "def waits(min_backoff, max_backoff, max_doublings, max_attempts):\n    \"\"\"The wait before each retry, by the rule Cloud Tasks documents.\"\"\"\n    wait, step = min_backoff, min_backoff * 2 ** max_doublings\n    for retry in range(1, max_attempts):\n        yield retry, min(wait, max_backoff)\n        wait = wait * 2 if retry <= max_doublings else wait + step\n\n\n", "note": "The rule as Google documents it for Cloud Tasks: the first wait is `min_backoff`, it doubles `max_doublings` times, then grows by a fixed step of `min_backoff` times two to the `max_doublings`, and never exceeds `max_backoff`."}, {"code": "def main():\n    args = [int(a) for a in sys.argv[1:]] or [10, 300, 3, 9]\n    total = 0\n    for retry, wait in waits(*args):\n        total += wait\n        print(f'retry {retry}: wait {wait:>3} s, {total:>4} s after the first attempt')\n\n\nif __name__ == '__main__':\n    main()\n", "note": "With no arguments it uses the numbers from Google's own example, 10 and 300 seconds, three doublings and nine attempts, so the output can be checked against the documentation."}]}
```

With no arguments it takes the numbers from Google's own example, nine attempts:

```
ana@laptop:~/gcp$ python3 backoff.py
retry 1: wait  10 s,   10 s after the first attempt
retry 2: wait  20 s,   30 s after the first attempt
retry 3: wait  40 s,   70 s after the first attempt
retry 4: wait  80 s,  150 s after the first attempt
retry 5: wait 160 s,  310 s after the first attempt
retry 6: wait 240 s,  550 s after the first attempt
retry 7: wait 300 s,  850 s after the first attempt
retry 8: wait 300 s, 1150 s after the first attempt
```

**10, 20, 40 and 80 are the three doublings; 160 and 240 are the linear step of 80; and 300 is the
ceiling**, which is the sequence Google's documentation gives for the same settings. Now the
queue of section 02, which allows five attempts and therefore four retries:

```
ana@laptop:~/gcp$ python3 backoff.py 10 300 3 5
retry 1: wait  10 s,   10 s after the first attempt
retry 2: wait  20 s,   30 s after the first attempt
retry 3: wait  40 s,   70 s after the first attempt
retry 4: wait  80 s,  150 s after the first attempt
```

A task that fails every time is abandoned two and a half minutes after its first attempt. That is
the number to compare with how long the thing it depends on is usually down for. If the mail
provider's outages last ten minutes, this queue gives up on every email sent during one of them,
and the honest fixes are more attempts or a longer `max_backoff`, not hope.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A bar chart of the wait before each retry, with min_backoff 10 seconds, max_backoff 300 and three doublings. Retries 1 to 4 wait 10, 20, 40 and 80 seconds, the doublings. Retries 5 and 6 wait 160 and 240, growing by a fixed 80. Retries 7 and 8 wait 300, the ceiling. A dashed line marks the end of the queue in this lesson, which allows five attempts and so stops after retry 4.\"><defs><marker id=\"f20back-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">wait (s)</text><rect x=\"70\" y=\"224.0\" width=\"56\" height=\"6.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"98.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10</text><text x=\"98.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">retry 1</text><rect x=\"144\" y=\"218.0\" width=\"56\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"172.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20</text><text x=\"172.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">retry 2</text><rect x=\"218\" y=\"206.0\" width=\"56\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"246.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">40</text><text x=\"246.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">retry 3</text><rect x=\"292\" y=\"182.0\" width=\"56\" height=\"48.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">80</text><text x=\"320.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">retry 4</text><rect x=\"366\" y=\"134.0\" width=\"56\" height=\"96.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"394.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">160</text><text x=\"394.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">retry 5</text><rect x=\"440\" y=\"86.0\" width=\"56\" height=\"144.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"468.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">240</text><text x=\"468.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">retry 6</text><rect x=\"514\" y=\"50.0\" width=\"56\" height=\"180.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"542.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">300</text><text x=\"542.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">retry 7</text><rect x=\"588\" y=\"50.0\" width=\"56\" height=\"180.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"616.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">300</text><text x=\"616.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">retry 8</text><rect x=\"60\" y=\"230\" width=\"600\" height=\"1\" rx=\"0\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M357.0 52 L357.0 228\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#f20back-amber)\"></path><text x=\"349.0\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">five attempts end here</text><text x=\"209.0\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">doubling</text><text x=\"431.0\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fixed step</text><text x=\"579.0\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ceiling</text></svg>", "caption": "The wait before each retry. Three doublings, then a fixed step, then the ceiling; the queue in this lesson stops at the dashed line."}
```

## Rates: the queue as a brake

Retries decide how long a task keeps trying. The rate limits decide how fast the queue empties,
and the arithmetic is simpler: a queue holding 1,000 confirmations, dispatching at most 5 a second,
needs 1,000 ÷ 5 = 200 seconds to drain, about three and a half minutes, however fast the mailer
could have gone. **That is the point.** The queue absorbs the burst so the mail provider, or the
database behind a handler, sees a steady five a second and never a thousand at once.

`max_concurrent_dispatches` is the other brake: at most ten requests in flight. With a handler that
takes two seconds per email, ten in flight is also five a second, and the two limits agree; with a
slower handler the concurrency limit bites first. Which one binds is worth knowing before a sale,
and both are a line of Terraform to change.

## When a task should not be retried at all

A task whose order no longer exists will fail on every attempt, and all of them are wasted. The
handler is the only place that knows the difference, so it decides: **answer 2xx for a task that
can never succeed**, after logging why, and keep the non-2xx answers for failures that time can
fix. It is the same rule lesson 18 gave for events, and for the same reason.
