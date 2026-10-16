---
title: A gesture is a finger, moved
version: 1
---

**To a test, a swipe is not a command. It is a finger put down at one point, moved to another
over some milliseconds, and lifted.** The W3C protocol of lesson 15 has a single request for every
gesture there is, `POST /session/{id}/actions`. Its body describes the finger: an *input source* of
type `pointer` with `pointerType` `touch`, and the list of things it does, in order.
Five kinds of step are enough for every gesture on a phone:

| step | what the finger does |
|---|---|
| `pointerMove` | goes to a point, at once or over a `duration` in milliseconds |
| `pointerDown` | touches the screen |
| `pause` | stays where it is for a `duration` |
| `pointerUp` | leaves the screen |

So a *tap* is down and up at one point. A *long press* is down, a pause of a second or so, and
up. A *swipe* is down, a move with a duration, and up. A *pinch* needs two fingers, which is two
pointer sources in one request, each with its own steps, played together.

## Seeing one

A gesture on a device is invisible from the test's side. The request goes out, the screen moves,
and the answer is `null`. Appium's fake driver from lesson 15 is the way to look at one. It keeps a
log of the actions it receives, which no other driver does. With the server of lesson 15
running and the fake driver installed, save it as `appium/fake-gestures.mjs`:

```js
// appium/fake-gestures.mjs: gestures sent to Appium's fake driver, to see what a gesture is
import path from 'node:path';
import { remote } from 'webdriverio';

const ID = 'id=example.tickets:id/';

const driver = await remote({
  hostname: '127.0.0.1',
  port: 4723,
  logLevel: 'silent',
  connectionRetryCount: 0,
  capabilities: {
    platformName: 'Fake',
    'appium:automationName': 'Fake',
    'appium:app': path.resolve('appium/tickets-model.xml'),
  },
});

// The fake driver keeps every gesture it receives in a log of its own; print the last one.
async function received(name) {
  const log = await driver.getLogs('actions');
  console.log(`${name}:`);
  for (const source of log.at(-1)) {
    for (const action of source.actions) console.log('  ' + JSON.stringify(action));
  }
}

try {
  const list = await driver.$(ID + 'shows');
  const refresh = await driver.$(ID + 'refresh');
  console.log('the list:', await list.getLocation(), await list.getSize());

  // A swipe up the list, by hand: a finger down near the bottom, moved up, lifted.
  await driver.action('pointer', { parameters: { pointerType: 'touch' } })
    .move({ x: 540, y: 2100 })
    .down()
    .pause(100)
    .move({ x: 540, y: 700, duration: 400 })
    .up()
    .perform();
  await received('swipe by hand');

  // A long press on the button: down, a second without moving, up.
  await driver.action('pointer', { parameters: { pointerType: 'touch' } })
    .move({ origin: refresh })
    .down()
    .pause(1000)
    .up()
    .perform();
  await received('long press by hand');

  // The same two gestures through WebdriverIO's helpers.
  await driver.swipe({ scrollableElement: list, direction: 'up', percent: 0.5 });
  await received('driver.swipe()');
  await refresh.longPress({ duration: 800 });
  await received('longPress()');

  // A gesture of the UiAutomator2 driver's own, which this driver does not have.
  try {
    await driver.execute('mobile: swipeGesture', { elementId: list.elementId, direction: 'up', percent: 0.5 });
  } catch (error) {
    console.log('mobile: swipeGesture failed:', error.message.split('. ')[0]);
  }
} finally {
  await driver.deleteSession();
}
```

`logLevel: 'silent'` and `connectionRetryCount: 0` keep WebdriverIO from printing its own
warnings. They also stop it retrying the command that is meant to fail at the end. The script
prints that error itself. From `~/boxoffice`:

```
ana@laptop:~/boxoffice$ node appium/fake-gestures.mjs
the list: { x: 42, y: 306 } { width: 996, height: 2052 }
swipe by hand:
  {"type":"pointerMove","button":0,"x":540,"y":2100,"duration":100,"origin":"viewport"}
  {"type":"pointerDown","button":0}
  {"type":"pause","duration":100}
  {"type":"pointerMove","button":0,"x":540,"y":700,"duration":400,"origin":"viewport"}
  {"type":"pointerUp","button":0}
long press by hand:
  {"type":"pointerMove","button":0,"x":0,"y":0,"duration":100,"origin":{"ELEMENT":"2","element-6066-11e4-a52e-4f735466cecf":"2"}}
  {"type":"pointerDown","button":0}
  {"type":"pause","duration":1000}
  {"type":"pointerUp","button":0}
driver.swipe():
  {"type":"pointerMove","button":0,"x":540,"y":1845,"duration":100,"origin":"viewport"}
  {"type":"pointerDown","button":0}
  {"type":"pause","duration":10}
  {"type":"pointerMove","button":0,"x":540,"y":819,"duration":1500,"origin":"viewport"}
  {"type":"pointerUp","button":0}
longPress():
  {"type":"pointerMove","button":0,"x":0,"y":0,"duration":100,"origin":{"ELEMENT":"2","element-6066-11e4-a52e-4f735466cecf":"2"}}
  {"type":"pointerDown","button":0}
  {"type":"pause","duration":800}
  {"type":"pointerUp","button":0}
mobile: swipeGesture failed: WebDriverError: Unsupported execute method 'mobile: swipeGesture'
```

**Read the swipe by hand first.** The finger goes to `540,2100`, near the bottom of a screen 2400
pixels tall, and touches. It waits 100 ms, travels to `540,700` in 400 ms and lifts. The content
under it moves up with the finger, which is what *swipe up* means. **The direction is the finger's,
not the list's**, and a swipe up brings the rows further down the list into view. Mixing the two is
the commonest gesture bug in a test, and it fails quietly. The list moves the wrong way, nothing is
found, and the report blames the locator.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 374\" role=\"img\" aria-label=\"On the left, a phone screen with the list drawn inside it. A finger touches at 540,2100 near the bottom and moves straight up to 540,700. On the right, the five steps of the one actions request that does it: pointerMove to 540,2100, pointerDown, a pause of 100 ms, pointerMove to 540,700 in 400 ms, pointerUp.\"><defs><marker id=\"f21swipe-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"30\" width=\"140.4\" height=\"312\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"45.46\" y=\"69.78\" width=\"129.48\" height=\"266.76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"110.2\" y=\"81.78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the list</text><rect x=\"105.2\" y=\"298\" width=\"10\" height=\"10\" rx=\"5\" fill=\"var(--amber)\"></rect><line x1=\"110.2\" y1=\"296\" x2=\"110.2\" y2=\"123\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#f21swipe-ah)\"></line><rect x=\"106.2\" y=\"117\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"120.2\" y=\"303\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--amber)\">540,2100</text><text x=\"120.2\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--amber)\">540,700</text><text x=\"110.2\" y=\"358\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the finger moves up</text><text x=\"385\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">one POST /actions, five steps</text><rect x=\"260\" y=\"34\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pointerMove</text><text x=\"385\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">to 540,2100</text><line x1=\"385\" y1=\"78\" x2=\"385\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21swipe-ah)\"></line><rect x=\"260\" y=\"96\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pointerDown</text><text x=\"385\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the finger touches</text><line x1=\"385\" y1=\"140\" x2=\"385\" y2=\"157\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21swipe-ah)\"></line><rect x=\"260\" y=\"158\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pause</text><text x=\"385\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">100 ms</text><line x1=\"385\" y1=\"202\" x2=\"385\" y2=\"219\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21swipe-ah)\"></line><rect x=\"260\" y=\"220\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pointerMove</text><text x=\"385\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">to 540,700, in 400 ms</text><line x1=\"385\" y1=\"264\" x2=\"385\" y2=\"281\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f21swipe-ah)\"></line><rect x=\"260\" y=\"282\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"385\" y=\"297\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pointerUp</text><text x=\"385\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the finger lifts</text><text x=\"530\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the content follows</text><text x=\"530\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the finger: a swipe up</text><text x=\"530\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">shows the rows below</text></svg>", "caption": "A swipe up as WebdriverIO sent it in the run above: the direction names where the finger goes, and the list moves with it."}
```

**The long press names no coordinates at all.** Its `origin` is the refresh button, as a W3C
element reference, and `x: 0, y: 0` is an offset from the element's centre. That is the gesture's version of lesson 14's advice about locators. A point worked out from an
element survives a new layout, and a point typed in as pixels does not.

**WebdriverIO's helpers send the same five steps.** `driver.swipe()` asked the list for its
rectangle, which starts at `y: 306` and is 2052 pixels tall. It took the middle half of it because
of `percent: 0.5`, and swiped from `y: 1845` to `y: 819` in 1500 ms, its default. `longPress()` is the
long press with 800 ms in the pause. The server's own log shows what went over HTTP:

```
[5f76d6dd][HTTP] --> POST /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
[5f76d6dd][HTTP] --> DELETE /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
[5f76d6dd][HTTP] --> POST /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
[5f76d6dd][HTTP] --> DELETE /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
[5f76d6dd][HTTP] --> POST /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
[5f76d6dd][HTTP] --> DELETE /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
[5f76d6dd][HTTP] --> POST /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
[5f76d6dd][HTTP] --> DELETE /session/5f76d6dd-8e9f-42b3-a7c9-7215833eb22e/actions
```

One `POST …/actions` per gesture, each followed by a `DELETE …/actions`. WebdriverIO sends that second request to release whatever the finger might still be holding. Every gesture library for Appium
ends in these requests. When a gesture misbehaves on a device, read the body of that `POST` in the
server's log first.

## The driver's own gestures

The last line of the run is the fake driver refusing `mobile: swipeGesture`. **Commands that start
with `mobile:` are not the protocol's; they belong to one driver.** They travel through the
standard `execute` request with the command's name in place of a script. The UiAutomator2 driver has
a set of them that hand the gesture to Android's UiAutomator. UiAutomator performs it on the device
from an element and a percentage, with no coordinates worked out in the test:

| gesture | UiAutomator2's command | its main arguments |
|---|---|---|
| tap | `mobile: clickGesture` | `elementId`, or `x` and `y` |
| long press | `mobile: longClickGesture` | `elementId`, `duration` |
| swipe | `mobile: swipeGesture` | `elementId`, `direction`, `percent` |
| scroll | `mobile: scrollGesture` | `elementId`, `direction`, `percent`; answers whether more is left to scroll |
| drag | `mobile: dragGesture` | `elementId`, `endX`, `endY` |
| pinch | `mobile: pinchOpenGesture`, `mobile: pinchCloseGesture` | `elementId`, `percent` |

In WebdriverIO they are called with `driver.execute('mobile: swipeGesture', { elementId, direction:
'up', percent: 0.75 })`. **The choice between the two kinds is portability against reliability.**
W3C actions work on every driver, Android and iOS alike, and leave the coordinates to you. The
`mobile:` gestures are often steadier on Android, because UiAutomator knows the screen, and they tie
the test to one driver. A suite that runs on one platform can take the `mobile:` ones. A suite for
both keeps to actions, or to WebdriverIO's helpers, which are actions underneath.

## Scrolling to something

Most swipes in a real suite exist to bring an element into view. WebdriverIO's
`element.scrollIntoView({ scrollableElement: list, direction: 'up' })` swipes until the element is
displayed, up to ten times by default. UiAutomator has its own way, in the selector syntax of
lesson 15:

```js
await driver.$('android=new UiScrollable(new UiSelector().scrollable(true))' +
  '.scrollIntoView(new UiSelector().resourceId("example.tickets:id/title").text("O Pagador de Promessas"))');
```

It scrolls the first scrollable view on screen until a row with that title appears, and returns
that row. Tickets has three shows and they fit on any phone. So neither is needed for the list as
boxoffice serves it; they matter the day there are thirty.

## Gestures in Espresso

Espresso has the same gestures as **view actions**, performed on a view it found. Like every
Espresso step, they wait for the main thread first:

```kotlin
onView(withId(R.id.shows)).perform(swipeUp())
onData(showWithId("sh-103")).inAdapterView(withId(R.id.shows)).perform(longClick())
```

`swipeUp()`, `swipeDown()`, `swipeLeft()` and `swipeRight()` swipe across the view they are given.
`longClick()` and `doubleClick()` press it. **`onData` already scrolls a `ListView` to the row it
finds**, which is why lesson 16's tests never needed a swipe. `scrollTo()` does the same for a view
inside a `ScrollView`. Espresso's gestures are touch events injected into the app's own window. They
can only reach the app's views, and the next section runs into that limit.

**No gesture in this section was performed on a device for this course.** As lesson 14 showed, no
emulator can start on the recording machine. The run above is the protocol, real, through the real
server. What a swipe does to Tickets's list is for your emulator to show.
