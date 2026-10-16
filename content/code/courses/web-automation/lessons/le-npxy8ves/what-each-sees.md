---
title: What each layer can see
version: 1
---

Three green runs say the same thing three times, so they cannot tell you what the layers are for.
**A layer earns its place by the defect it catches and the others miss**, and the way to see that
is to put a defect in and watch which tests go red. Each change below is made with `sed` for one
run and undone straight after, which is mutation testing done by hand: break the code on purpose
and see whether any test notices.

## A defect only the browser sees

The page turns cents into reais in one place, the function in `app/public/app.js` that draws the
header. Take the division out of it:

```sh
sed -i 's|money.format(basket.total / 100)|money.format(basket.total)|' app/public/app.js
```

The server still answers `total: 590`, which is right. The page now formats 590 as reais. Run the
three files:

```
ana@laptop:~/quitanda$ node --test --test-reporter=tap unit/total.test.js
TAP version 13
# Subtest: an empty basket costs nothing
ok 1 - an empty basket costs nothing
  ---
  duration_ms: 0.823823
  type: 'test'
  ...
# Subtest: one banana costs 590 cents
ok 2 - one banana costs 590 cents
  ---
  duration_ms: 0.187692
  type: 'test'
  ...
# Subtest: quantities multiply and lines add up
ok 3 - quantities multiply and lines add up
  ---
  duration_ms: 0.134308
  type: 'test'
  ...
1..3
# tests 3
# suites 0
# pass 3
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 69.284004
ana@laptop:~/quitanda$ npx playwright test tests/basket-api.spec.js tests/basket-ui.spec.js --workers 1

Running 2 tests using 1 worker

  ✓  1 tests/basket-api.spec.js:4:1 › a banana in the basket costs 590 cents (57ms)
  ✘  2 tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 (5.2s)


  1) tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 ────────────────────────────

    Error: expect(locator).toHaveText(expected) failed

    Locator:  locator('.basket-total')
    Expected: "R$ 5,90"
    Received: "R$ 590,00"
    Timeout:  5000ms

    Call log:
      - Expect "toHaveText" with timeout 5000ms
      - waiting for locator('.basket-total')
        9 × locator resolved to <span class="basket-total">R$ 590,00</span>
          - unexpected value "R$ 590,00"


       6 |   await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
       7 |   await expect(page.getByTestId('basket-count')).toHaveText('1');
    >  8 |   await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
         |                                               ^
       9 | });
      10 |
        at /home/ana/quitanda/tests/basket-ui.spec.js:8:47

    Error Context: test-results/basket-ui-a-banana-in-the-basket-shows-R-5-90/error-context.md

  1 failed
    tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 ─────────────────────────────
  1 passed (6.6s)
```

The unit test passed all three cases, and the API test passed in 57 ms. The browser test failed
after 5.2 s, which is the five seconds `expect` keeps retrying a text before it gives up, and its
message shows both sides: expected `R$ 5,90`, received `R$ 590,00`.

**This defect lives in the seam between the page and the server**, the agreement that the server
speaks cents and the page divides. The unit test cannot see it, because `total()` was never wrong.
The API test cannot see it, because the API was never wrong. Only the test that reads what the page
draws can, and it is the only one of the three that runs the page's code at all. Put the line back
before going on:

```sh
sed -i 's|money.format(basket.total)|money.format(basket.total / 100)|' app/public/app.js
```

## A defect the unit layer pins down cheaply

Now break the arithmetic. In `app/store.js`, make `total()` forget the quantity:

```sh
sed -i 's|return sum + product.price \* line.qty;|return sum + product.price;|' app/store.js
```

```
ana@laptop:~/quitanda$ node --test --test-reporter=tap unit/total.test.js
TAP version 13
# Subtest: an empty basket costs nothing
ok 1 - an empty basket costs nothing
  ---
  duration_ms: 0.887472
  type: 'test'
  ...
# Subtest: one banana costs 590 cents
ok 2 - one banana costs 590 cents
  ---
  duration_ms: 0.320592
  type: 'test'
  ...
# Subtest: quantities multiply and lines add up
not ok 3 - quantities multiply and lines add up
  ---
  duration_ms: 0.87445
  type: 'test'
  location: '/home/ana/quitanda/unit/total.test.js:13:1'
  failureType: 'testCodeFailure'
  error: |-
    Expected values to be strictly equal:
    
    1880 !== 4350
    
  code: 'ERR_ASSERTION'
  name: 'AssertionError'
  expected: 4350
  actual: 1880
  operator: 'strictEqual'
  stack: |-
    TestContext.<anonymous> (file:///home/ana/quitanda/unit/total.test.js:15:10)
    Test.runInAsyncScope (node:async_hooks:214:14)
    Test.run (node:internal/test_runner/test:1047:25)
    Test.processPendingSubtests (node:internal/test_runner/test:744:18)
    Test.postRun (node:internal/test_runner/test:1173:19)
    Test.run (node:internal/test_runner/test:1101:12)
    async Test.processPendingSubtests (node:internal/test_runner/test:744:7)
  ...
1..3
# tests 3
# suites 0
# pass 2
# fail 1
# cancelled 0
# skipped 0
# todo 0
# duration_ms 78.745706
ana@laptop:~/quitanda$ npx playwright test tests/basket-api.spec.js tests/basket-ui.spec.js --workers 1

Running 2 tests using 1 worker

  ✓  1 tests/basket-api.spec.js:4:1 › a banana in the basket costs 590 cents (49ms)
  ✓  2 tests/basket-ui.spec.js:3:1 › a banana in the basket shows R$ 5,90 (213ms)

  2 passed (1.6s)
```

Now the unit test is the one that fails. The third case expected 4350 and got 1880, which is one
banana and one guava, 590 + 1290, with the quantities gone. The first two cases still pass,
because a quantity of one hides the defect. The API and browser tests both passed, in 49 ms and
213 ms.

**The browser test went green on a shop that charges wrong.** It is not a bad test; it bought one
banana, and with one of each thing the defect has no effect. To catch it there, the test would have
to press the button three times on one card, twice on another, and read the total, which is more
steps, more waiting and more ways to fail for reasons that are not the arithmetic. The API test is
in the same position: it would need three requests. The unit test reached it by writing one more line with
other numbers in it. Put it back:

```sh
sed -i 's|return sum + product.price;|return sum + product.price * line.qty;|' app/store.js
```

## The two together

| | unit `total()` | API `/api/basket` | browser, one click |
|---|---|---|---|
| cents drawn as reais in the header | green, cannot see it | green, cannot see it | **red**, and the message names both texts |
| quantity left out of `total()` | **red**, `1880 !== 4350` | green, one banana | green, one banana |
| where the failure points | the function and the numbers | the route's answer | a locator, a text, a page |

Read the bottom row too. **A red unit test names the rule that broke**; a red browser test names
what a customer would notice, and the cause can be anywhere between the server's arithmetic and the
page's formatting. Both are useful, and they are useful for different things. The first one tells
you what to fix. The second tells you that something a customer touches is wrong, which no amount
of unit tests will ever say.

That is also the honest answer to "which layer is best": none of the three caught both defects. The
next section asks what each one costs to run, because if they were all free you would simply keep
all three everywhere.
