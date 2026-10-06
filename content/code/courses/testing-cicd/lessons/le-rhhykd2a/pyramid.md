---
title: The test pyramid, measured
version: 1
---

The **test pyramid** is a picture of how a healthy suite is shaped: many unit tests at the base,
fewer integration tests above them, and a handful of functional and acceptance tests at the top.
It is usually drawn from intuition. `shipquote` lets you draw it from measurements, because every
test carries a marker naming its layer.

```
ana@laptop:~/shipquote$ python -m pytest -q -m "not integration and not functional and not acceptance"
........................                                                 [100%]
24 passed, 7 deselected in 0.17s
ana@laptop:~/shipquote$ python -m pytest -q -m "integration or functional or acceptance"
.......                                                                  [100%]
7 passed, 24 deselected in 1.21s
ana@laptop:~/shipquote$ python -m pytest -q --durations=4
...............................                                          [100%]
============================= slowest 4 durations ==============================
0.50s teardown tests/test_app.py::test_a_bad_cep_is_a_400_that_says_why
0.50s teardown tests/test_acceptance.py::test_a_basket_of_199_reais_ships_free_to_every_region
0.03s call     tests/test_acceptance.py::test_a_basket_of_199_reais_ships_free_to_every_region

(1 durations < 0.005s hidden.  Use -vv to show these durations.)
31 passed in 1.23s
```

The first command runs everything that is **not** marked as one of the slower layers: 24 unit
tests in 0.17 seconds. The second runs the other 7, and they take 1.21 seconds. Seven tests cost
seven times what twenty-four do.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The shipquote suite drawn as a pyramid of three bands. The wide bottom band holds 24 unit tests, which run in 0.17 seconds together. The middle band holds 3 integration tests and the narrow top band 4 functional and acceptance tests; those 7 run in 1.21 seconds together.\"><path d=\"M360 30 L440 110 L280 110 Z\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M280 110 L440 110 L520 190 L200 190 Z\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M200 190 L520 190 L600 270 L120 270 Z\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"360\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">4</text><text x=\"360\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">3</text><text x=\"360\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">24</text><path d=\"M420 80 L470 80\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"476\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">functional and acceptance</text><path d=\"M490 150 L530 150\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"536\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">integration</text><path d=\"M570 232 L600 232\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"606\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">unit</text><path d=\"M190 34 L180 34 L180 186 L190 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"172\" y=\"102\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1.21 s</text><text x=\"172\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">for these 7</text><path d=\"M110 194 L100 194 L100 266 L110 266\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"92\" y=\"222\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">0.17 s</text><text x=\"92\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">for these 24</text><text x=\"360\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">many fast tests at the bottom, a few slow ones at the top</text></svg>", "caption": "The suite's own numbers. Seven tests at the top cost seven times what twenty-four cost at the bottom, which is why the shape is wide at the base."}
```

## Where the time goes

`--durations=4` lists the four slowest phases of the run, and the answer is not what most people
guess. **The two slowest entries are teardowns, 0.50 seconds each**, not requests. They belong to
the `base_url` fixture: `server.shutdown()` waits for the server's loop to notice it should stop,
and Python's `serve_forever` checks for that every half second by default. The fixture is scoped to
a module and two modules use it, so the suite pays the half second twice. The requests
themselves cost 0.03 seconds for the whole acceptance test, six quotes included.

That is a typical finding. The slow part of a high-level test is rarely the assertion; it is the
setting up and tearing down of a world for the test to run in: a server, a browser, a database
with a schema. **That cost is per test or per module, so it multiplies with the number of tests**,
which is the whole argument for keeping the top of the pyramid narrow.

## The shape is a budget, not a law

The pyramid says where to spend tests, and the reason is cost and precision:

- **Lower layers are cheaper and point closer to the cause.** A red unit test names a rule; a red
  functional test names an endpoint.
- **Higher layers see what lower ones cannot**, the wiring between pieces, so a suite with none of
  them is green on the day nothing starts.

Two other shapes get named often enough to recognise. The **ice-cream cone** is the pyramid upside
down: most checks are end-to-end, often manual, few are unit tests. It happens when testing starts
after the code is written and only the outside is reachable. It is slow, flaky, and points
nowhere when it fails. The **testing trophy** widens the middle, on the argument that for code
which is mostly glue between services, integration tests buy the most confidence per second. Both
are arguments about the same trade, and for a codebase with real rules in it, like prices with
edges, the wide base pays.

**What matters is that you know your suite's shape and why.** Counting tests per marker, as above,
takes one command. If the top layer holds most of the time and most of the tests, the suite will
be slow on every push and the team will start skipping it, and lesson 5 shows what a pipeline does
with a slow suite.

In the `qa` track, `web-automation` lesson 21 looks at the same pyramid from the browser's end,
where the top layer is far more expensive than it is here.
