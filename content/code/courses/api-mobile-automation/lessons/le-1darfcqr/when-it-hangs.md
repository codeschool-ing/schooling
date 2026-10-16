---
title: When the app is never idle
version: 1
---

**Detox waits for an idle app, so an app that is never idle makes every step wait until the test's
own timeout.** Nothing on the screen is wrong. The list is there, the row is there, and the spec
never reaches it. This is the failure that belongs to gray-box synchronisation, and every Detox
suite meets it sooner or later.

## How an app stays busy

Suppose a developer makes the list keep its seats up to date by asking boxoffice again every
second. That is a common request for a box office during a sale. In `App.tsx` it is three lines, in place of
the `useEffect` that loads once:

```tsx
useEffect(() => {
  load();
  const every = setInterval(load, 1000);
  return () => clearInterval(every);
}, [load]);
```

Now look at the table of section 03. There is always a timer about to fire, and a request to
boxoffice in flight for part of every second. **The app is correct and never idle.** The first
`expect` of the spec waits, and waits, until Jest's two minutes in `e2e/jest.config.js` run out and
the test fails. While it waits, Detox can print the list of what is keeping the app busy. The timer
and the network request would both be on it. That message is the place to start: it names
the cause rather than the element.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 332\" role=\"img\" aria-label=\"Two timelines of what keeps an app busy: network, timers, the JavaScript thread and the main thread. In the first, the app loads the shows once: a request, then JavaScript work, then drawing, and after that every lane is empty and Detox taps. In the second, the app asks boxoffice again every second: a timer is always pending and requests and JavaScript work keep returning, so there is never a moment when every lane is empty, and the tap waits until the test times out.\"><text x=\"350\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">loads once</text><text x=\"350\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">asks again every second</text><text x=\"140\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">network</text><line x1=\"150\" y1=\"48\" x2=\"690\" y2=\"48\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"165\" y=\"41\" width=\"165\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"140\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">timers</text><line x1=\"150\" y1=\"74\" x2=\"690\" y2=\"74\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><text x=\"140\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">JavaScript</text><line x1=\"150\" y1=\"100\" x2=\"690\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"330\" y=\"93\" width=\"50\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"140\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main thread</text><line x1=\"150\" y1=\"126\" x2=\"690\" y2=\"126\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"375\" y=\"119\" width=\"45\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><line x1=\"440\" y1=\"34\" x2=\"440\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><text x=\"440\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">all idle: Detox taps</text><text x=\"140\" y=\"208\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">network</text><line x1=\"150\" y1=\"208\" x2=\"690\" y2=\"208\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"165\" y=\"201\" width=\"135\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"345\" y=\"201\" width=\"125\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"525\" y=\"201\" width=\"125\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"140\" y=\"234\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">timers</text><line x1=\"150\" y1=\"234\" x2=\"690\" y2=\"234\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"150\" y=\"227\" width=\"540\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"140\" y=\"260\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">JavaScript</text><line x1=\"150\" y1=\"260\" x2=\"690\" y2=\"260\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"300\" y=\"253\" width=\"40\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"470\" y=\"253\" width=\"40\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"650\" y=\"253\" width=\"40\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"140\" y=\"286\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main thread</text><line x1=\"150\" y1=\"286\" x2=\"690\" y2=\"286\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"335\" y=\"279\" width=\"25\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"505\" y=\"279\" width=\"25\" height=\"14\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"420\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">never all idle at once: the tap waits until the test times out</text></svg>", "caption": "Detox acts at the first moment nothing is busy. An app that polls never has such a moment."}
```

Other common causes, each of which keeps one row of that table true for ever:

- an animation that loops, such as a pulsing *live* badge or a spinner nobody stops;
- a long-lived connection the app keeps open, for prices or chat, which Detox sees as a request
  that never ends;
- a timer used as a heartbeat, for analytics or to refresh a token.

## Three ways out, best first

**Make the app quiet in the test build.** If the polling is a feature, the developers can switch it
off, or slow it down, when the app is built for tests. The spec stays exactly as it is. This is
lesson 16's argument for `CountingIdlingResource` again: the app helps its tests, on purpose. The
tests keep the full synchronisation everywhere else.

**Tell Detox to ignore one address.** `device.setURLBlacklist` takes a list of patterns, and requests
to a matching URL no longer count as work in flight. The rest of the synchronisation stays on:

```js
await device.setURLBlacklist(['.*/v1/shows.*']);
```

It deals with the request and not with the timer, which on its own may still keep Detox waiting.
That is why the first way is better when it is possible.

**Switch synchronisation off for the part that never settles, and wait explicitly there.** This is
lesson 15's style, inside Detox:

```js
it('opens a show while the list keeps polling', async () => {
  await device.disableSynchronization();
  try {
    await waitFor(element(by.id('show-sh-103'))).toBeVisible().withTimeout(10000);
    await element(by.id('show-sh-103')).tap();
    await waitFor(element(by.id('chosen'))).toBeVisible().withTimeout(5000);
  } finally {
    await device.enableSynchronization();
  }
});
```

`waitFor(…).withTimeout(…)` asks again until the condition holds or the deadline passes, like
WebdriverIO's `waitForDisplayed`. Without synchronisation, a plain `expect` would look once, at
once, and fail on a list not yet drawn. **The `finally` matters.** Suppose a spec fails with
synchronisation off and never switches it back. Every later spec in the file then runs without it,
passing or failing for reasons that have nothing to do with them.

None of these was run for this course, for the reason section 04 gave. They are written from
Detox's documented API, and each is a few lines a test can carry until the developers make the
app quiet.
