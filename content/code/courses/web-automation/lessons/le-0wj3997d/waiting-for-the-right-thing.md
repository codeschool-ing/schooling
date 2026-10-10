---
title: Waiting for the right thing
version: 1
---

A sleep fails because it waits for a length of time, and time is not what the test cares about.
The cure is to wait for a **state**: something in the page that is true when the test may look and
false before. Playwright makes that the ordinary way to write a check, and this section shows three
forms of it. **Two of them pass on this page, and both are wrong**, and why they are wrong is
what this section is for.

## Assertions that retry

`expect(locator).toHaveCount(1)` looks like `expect(await locator.count()).toBe(1)` and behaves
differently. The second counts once and compares. The first is a **web-first assertion**: it asks
the page again and again until the answer is 1 or the assertion's time runs out, which is five seconds
unless configured otherwise, as Playwright's documentation says. Every method of `expect` that
takes a locator works that way, `toHaveText`, `toBeVisible` and `toHaveAttribute` among them, and
the smoke test in lesson 1 relied on it without saying so. With one, a slow server stops being a
reason to fail: the check waits as long as the answer takes, and no longer.

## Waiting for a response

`page.waitForResponse` waits for the browser to receive a response that matches a condition. Start
waiting **before** the action that causes the request, or the response can arrive before anything
is listening for it; that is why the promise is created first and awaited after the typing. It
answers a narrower question than an assertion does: not *what does the page show* but *has the
server answered this request*.

## Waiting for the page to say it is done

The third form waits for the signal the page itself publishes: `aria-busy` going back to `false`.
`toHaveAttribute('aria-busy', 'false')` is a web-first assertion like the others, so it retries
until the attribute says so, and only then do the next two lines check the list and the count.

This version of the file has one test of each kind. Save it as `tests/search.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/search.html');
});

test('an assertion that retries', async ({ page }) => {
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await expect(page.locator('#results li')).toHaveCount(1);
});

test('waiting for the answer to "papaya"', async ({ page }) => {
  const answer = page.waitForResponse((response) => response.url().endsWith('?q=papaya'));
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await answer;
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
});

test('waiting until the page is no longer busy', async ({ page }) => {
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await expect(page.locator('#results')).toHaveAttribute('aria-busy', 'false');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
  await expect(page.locator('#count')).toHaveText('1 found');
});
```

```
%%CAP v2%%
```

**The first two passed, in well under a second, and the third failed after retrying for five.**
Read the failure: `aria-busy` reached `false`, then `toHaveText` expected one item and received
three, *Papaya, Passion fruit, Pineapple*, and went on receiving them until it gave up.

The retrying assertion passed because it is satisfied by the first moment the list holds one
item, and the first answer to arrive, the one to `papaya`, gave it that moment. **A web-first
assertion waits for its condition to become true; it does not check that it stays true.** The
response test passed for the same reason in another form: the answer to `papaya` is real, it
arrived first, and the list it drew was right until the answer to `p` replaced it. Both tests
looked at the page during the window when it was correct, and stopped looking.

Only the third waited for what the test actually claims: *when the search is finished, the list
holds Papaya*. It is the honest test of the three, and it is the one that failed. The figure puts
all six of this lesson's ways to wait on one timeline.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The same timeline of what the list shows, Papaya until 600 ms, two fruit until 750 ms, three after, with six tests marked at the moment each one looks. count(), read at once, looks at 0 ms and finds an empty list. waitForTimeout(500) looks at 500 ms and passes. waitForTimeout(1000) looks at 1000 ms and fails on three fruit. toHaveCount(1) and waitForResponse are satisfied by the first answer and pass too early. Waiting for aria-busy false looks at 750 ms and fails on three fruit, which is the page's real final state.\"><text x=\"20\" y=\"45\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the list</text><rect x=\"250\" y=\"30\" width=\"240\" height=\"22\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"370\" y=\"45\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Papaya</text><rect x=\"490\" y=\"30\" width=\"60\" height=\"22\" rx=\"3\" fill=\"var(--wire)\"></rect><text x=\"520\" y=\"45\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"550\" y=\"30\" width=\"140\" height=\"22\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"620\" y=\"45\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">3 found</text><text x=\"250\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 ms</text><text x=\"350\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">250 ms</text><text x=\"450\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">500 ms</text><text x=\"550\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">750 ms</text><text x=\"650\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000 ms</text><text x=\"20\" y=\"104\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">count()</text><path d=\"M250 54 L250 96\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"250\" cy=\"100\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"260\" y=\"104\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">empty: fails</text><text x=\"20\" y=\"136\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">waitForTimeout(500)</text><path d=\"M450 54 L450 128\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"450\" cy=\"132\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"460\" y=\"136\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">passes, by luck</text><text x=\"20\" y=\"168\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">waitForTimeout(1000)</text><path d=\"M650 54 L650 160\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"650\" cy=\"164\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"640\" y=\"168\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">fails on 3</text><text x=\"20\" y=\"200\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">toHaveCount(1)</text><path d=\"M250 54 L250 192\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"250\" cy=\"196\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"260\" y=\"200\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">passes, too early</text><text x=\"20\" y=\"232\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">waitForResponse</text><path d=\"M250 54 L250 224\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"250\" cy=\"228\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"260\" y=\"232\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">passes, too early</text><text x=\"20\" y=\"264\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">aria-busy=\"false\"</text><path d=\"M550 54 L550 256\" stroke=\"var(--wire)\" stroke-dasharray=\"3 3\"></path><circle cx=\"550\" cy=\"260\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"540\" y=\"264\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">fails on 3: the truth</text></svg>", "caption": "Six ways to wait, and where each one looks. Only the last looks at the state the page ends in."}
```

## Waiting for a state that cannot be true too early

A condition is only worth waiting for if it cannot be met before the moment you mean. **Look at
the HTML of the search page: the list starts with `aria-busy="false"`.** Before the first key, the
condition the third test waits for is already true. It works here because `pressSequentially`
returns only after the last key's `input` event has run, and the first of them had already set the
attribute to `true`. A test that started waiting before typing, or a page that set the attribute a
moment after the request instead of before, would pass the wait at once and read an empty list.

So when you choose what to wait for, ask two questions: **is it true when the page is finished,
and is it false until then?** A response arriving answers the first and not the second. A count of
one answers neither on this page. `aria-busy` answers both, which is why the test built on it is
the one that told the truth. Lesson 13 turns this into the vocabulary of explicit waits and custom
conditions; for now, recognising the two questions is enough.
