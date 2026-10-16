---
title: What each layer costs
version: 1
---

A test costs three things: **the time it takes, the times it fails for no reason, and the work of
keeping it true** when the product changes for reasons that are not defects. All three grow as the
test runs more of the system, and this section measures each of them on the three files.

## Time, once and twenty times

One run of each, timed by the shell, with the output thrown away so only the clock is left:

```
ana@laptop:~/quitanda$ time node --test --test-reporter=tap unit/total.test.js > /dev/null

real	0m0.114s
user	0m0.102s
sys	0m0.021s
ana@laptop:~/quitanda$ time npx playwright test tests/basket-api.spec.js > /dev/null

real	0m2.521s
user	0m2.156s
sys	0m0.362s
ana@laptop:~/quitanda$ time npx playwright test tests/basket-ui.spec.js > /dev/null

real	0m2.647s
user	0m2.290s
sys	0m0.368s
```

That `real` line is what you wait at the keyboard: 0.114 s for the unit test, 2.521 s and 2.647 s
for the other two. **On a single run the two Playwright files are almost the same**, 0.126 s apart,
because most of a single run is what both pay before any test starts: loading Playwright and
starting the shop through `webServer`.

Twenty runs separate them. The unit file is run twenty times by a shell loop; the Playwright files
use `--repeat-each 20`, on one worker because both write the shared basket:

```
ana@laptop:~/quitanda$ time for i in $(seq 20); do node --test --test-reporter=tap unit/total.test.js > /dev/null; done

real	0m2.164s
user	0m1.816s
sys	0m0.547s
ana@laptop:~/quitanda$ time npx playwright test tests/basket-api.spec.js --repeat-each 20 --workers 1 --reporter=dot

Running 20 tests using 1 worker
····················
  20 passed (16.3s)

real	0m17.531s
user	0m17.904s
sys	0m2.368s
ana@laptop:~/quitanda$ time npx playwright test tests/basket-ui.spec.js --repeat-each 20 --workers 1 --reporter=dot

Running 20 tests using 1 worker
····················
  20 passed (23.1s)

real	0m24.310s
user	0m22.908s
sys	0m4.574s
```

All forty Playwright runs passed. Divided by twenty, a run cost 0.108 s at the unit layer, 0.877 s
at the API layer and 1.215 s at the browser layer. Twenty repetitions are not twenty tests in one
worker, though, and it matters here. Playwright gives each repetition **a worker of its own**, which
the JSON report shows:

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-api.spec.js --repeat-each 3 --workers 1 --reporter=json > /tmp/run.json
ana@laptop:~/quitanda$ grep -o "\"workerIndex\": [0-9]*" /tmp/run.json
"workerIndex": 0
"workerIndex": 1
"workerIndex": 2
```

So each of those twenty runs started a fresh worker process, just as each unit run started a fresh
Node. The comparison is fair between the layers, and it is the price of starting over, which is
what running one file again costs. Inside a long suite a worker is reused, and the number that
grows with the suite is the time per test, the one each runner printed in the last section: well
under a millisecond, 51 ms, and 281 ms.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"The three test files drawn as a pyramid of three bands. The narrow top band is the browser layer, one test, 281 milliseconds a test and 24.310 seconds for twenty runs. The middle band is the API layer, one test, 51 milliseconds a test and 17.531 seconds for twenty runs. The wide bottom band is the unit layer, three tests, under a millisecond each and 2.164 seconds for twenty runs.\"><path d=\"M200 30 L260 110 L140 110 Z\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M140 110 L260 110 L320 190 L80 190 Z\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><path d=\"M80 190 L320 190 L380 270 L20 270 Z\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"200\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">1</text><text x=\"200\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text><text x=\"200\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">3</text><path d=\"M240 81 L410 81\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"420\" y=\"72\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">browser: a click in a real page</text><text x=\"420\" y=\"91\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">281 ms</text><text x=\"560\" y=\"91\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">24.310 s</text><path d=\"M293 151 L410 151\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"420\" y=\"142\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">API: one request, no browser</text><text x=\"420\" y=\"161\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">51 ms</text><text x=\"560\" y=\"161\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">17.531 s</text><path d=\"M353 231 L410 231\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"420\" y=\"222\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">unit: a function call, no server</text><text x=\"420\" y=\"241\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">under 1 ms</text><text x=\"560\" y=\"241\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">2.164 s</text><text x=\"20\" y=\"302\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the number in each band is how many tests it holds; the times are this lesson's runs</text><text x=\"420\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one test</text><text x=\"560\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">twenty runs</text></svg>", "caption": "The pyramid with this shop's own numbers. One behaviour, checked three times: the browser test cost more than five times the API test per test, and the unit layer checked three cases in less time than either Playwright command took to finish."}
```

## Why slow matters

A second either way sounds like nothing, and for one test it is. **The cost of a test is its time
multiplied by the number of times it runs**, and both numbers grow. Take a suite of 300 checks like
these, on one worker, at the per-test times above:

| the 300 checks at | one run | 60 runs a day |
|---|---|---|
| the browser layer, 281 ms each | 300 × 0.281 = 84.3 s | 84.3 × 60 = 5,058 s, about 84 minutes |
| the API layer, 51 ms each | 300 × 0.051 = 15.3 s | 15.3 × 60 = 918 s, about 15 minutes |
| the unit layer, 1 ms each at most | 300 × 0.001 = 0.3 s | 0.3 × 60 = 18 s |

Sixty runs is four people running the suite fifteen times each in a working day, which is a modest
team doing what you want it to do: running the tests after every change. Parallel workers divide
the first column, and lesson 19 is about that; they divide it by the number of cores, not by a
thousand.

The minutes are the smaller half of the cost. **A suite that takes a minute and a half is run less
often**, so a defect lives longer between being written and being seen, and that gap is the cost
`qa-fundamentals` lesson 3 puts a price on. A suite that answers in a third of a second is run on
every save without anybody deciding to.

## Flakiness

All forty Playwright runs above passed, and that proves less than it looks. A test that fails one
run in a hundred, for reasons that have nothing to do with the shop, passes twenty in a row with
probability 0.99 to the power 20, about 0.82: **four times in five you would see a clean twenty and
believe it.** Lesson 11 removed the waits from a Puppeteer script and got the basket 0, 0, 0, 1, 1
over five runs; lesson 14 is about finding and containing tests like that.

What the layers change is how many sources of that kind each test has. The unit test has no network,
no server, no timer and no rendering, so there is nothing in it to race. The API test adds a server
and HTTP. The browser test adds a browser starting, a page loading its scripts, an event reaching a
button, and every wait in between, and each of those is a place where timing can decide the result.

## Maintenance

The third cost arrives when the product changes and nothing is wrong. Rename the button from
"Add to basket" to "Add to cart", which is a change of words that a customer would not call a
defect:

```sh
sed -i 's|<button type="button">Add to basket</button>|<button type="button">Add to cart</button>|' app/public/app.js
```

And run the two Playwright files:

```
ana@laptop:~/quitanda$ npx playwright test tests/basket-api.spec.js tests/basket-ui.spec.js --workers 1

Running 2 tests using 1 worker

  ✓  1 tests/basket-api.spec.js:4:1 › a banana in the basket costs 590 cents (46ms)
  ✘  2 tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 (30.0s)


  1) tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 ────────────────────────────

    Test timeout of 30000ms exceeded.

    Error: locator.click: Test timeout of 30000ms exceeded.
    Call log:
      - waiting for getByTestId('product-banana').getByRole('button', { name: 'Add to basket' })


      4 |   await request.post('/api/reset');
      5 |   await page.goto('/');
    > 6 |   await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
        |                                                                                           ^
      7 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
      8 |   await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
      9 | });
        at /home/ana/quitanda/tests/basket-ui.spec.js:6:91

    Error Context: test-results/basket-ui-a-banana-in-the-basket-shows-R-5-90/error-context.md

  1 failed
    tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 ─────────────────────────────
  1 passed (31.3s)
```

**The browser test failed on a shop that works**, and it took the whole 30-second test timeout to
say so, because Playwright kept waiting for a button with the old name to appear. The API test does
not know what the button says. Every browser test that names the button pays this change once, which
is the argument lesson 12 made for keeping a locator in one page object rather than in fifty tests.
None of this is a reason to have no browser tests. It is the reason each one has to be worth its
cost, which is where the next two sections go. Put the label back first:

```sh
sed -i 's|<button type="button">Add to cart</button>|<button type="button">Add to basket</button>|' app/public/app.js
```
