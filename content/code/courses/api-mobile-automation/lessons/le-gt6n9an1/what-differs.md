---
title: What changes when the thing under test is an app
version: 1
---

**The second half of this course tests something a person holds in their hand, and almost every
assumption of the first half stops being true.** An API waits at an address for a request and
answers it. An app is a program installed on somebody's phone, sharing that phone with a hundred
others, at the mercy of a battery, a signal and an operating system that may stop it whenever it
likes. Lessons 1 to 13 were about whether an answer is right. Lessons 14 to 22 are about whether
the app does the right thing with it, on a device you do not control.

The common mistake is to think of mobile testing as web testing on a small screen. Some ideas
carry over: you still design cases, you still automate the ones worth repeating, you still find
elements on a screen and act on them, which `web-automation` taught if you took it. What changes
is the list below, and each item is a lesson of its own later on.

| | a web page | an app |
|---|---|---|
| **how it arrives** | an address in a browser; every visit loads the current version | an installed package, an APK on Android; old versions stay installed for months |
| **where it runs** | a handful of browsers | thousands of phone models, a dozen Android versions in use at once (lesson 20) |
| **its life** | open or closed | started, paused, sent to the background, killed to free memory, restored (lesson 21) |
| **what it may do** | what the browser allows | what the person granted: camera, location, notifications, each asked for at runtime (lesson 21) |
| **its network** | assumed present | a tunnel, a lift, a train: slow, lost, back again (lesson 22) |
| **how you touch it** | a mouse and a keyboard | taps, swipes, long presses, rotation, the back button (lesson 21) |
| **where tests run** | a browser on any computer | an emulator, a real device, or a farm of them (lessons 19 and 20) |

## Three places a mobile test can live

On the web there is roughly one kind of browser test. On Android there are three, and the
difference is **where the test code runs relative to the app**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 266\" role=\"img\" aria-label=\"Three places a mobile test can live. A local test runs on the computer, on the Java runtime, with no Android. An instrumented test such as Espresso runs on the device inside the app's own process, beside Tickets. An end-to-end test such as Appium runs on the computer and reaches the app from outside, through the device's accessibility layer, the tree of what is on the screen.\"><defs><marker id=\"f14where-tests-run-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"250\" height=\"200\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"145\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">your computer</text><rect x=\"330\" y=\"30\" width=\"350\" height=\"200\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"505\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the device: emulator or phone</text><rect x=\"470\" y=\"70\" width=\"190\" height=\"140\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"565\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">the app's process</text><rect x=\"485\" y=\"100\" width=\"160\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"565\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Tickets</text><text x=\"565\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the app</text><rect x=\"485\" y=\"154\" width=\"160\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"565\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instrumented test</text><text x=\"565\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Espresso</text><rect x=\"40\" y=\"70\" width=\"210\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">local test</text><text x=\"145\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">JVM on the computer, no Android</text><rect x=\"40\" y=\"154\" width=\"210\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"145\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">end-to-end test</text><text x=\"145\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Appium</text><rect x=\"345\" y=\"100\" width=\"105\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"397.5\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">accessibility</text><text x=\"397.5\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the screen tree</text><line x1=\"250\" y1=\"176\" x2=\"343\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f14where-tests-run-ah)\"></line><line x1=\"450\" y1=\"122\" x2=\"483\" y2=\"122\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f14where-tests-run-ah)\"></line><text x=\"350\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the further from the app a test runs, the more it sees like a person, and the slower it is</text></svg>", "caption": "Where the test code runs decides what it can see: nothing of the screen, the app from inside, or the screen as a person sees it."}
```

- **A local test** runs on your computer's own Java runtime, without Android. It is fast, seconds
  for hundreds, and it can only test code that does not need a screen: the price formatting of the
  app you build in section 05, for example.
- **An instrumented test** is packaged into a second APK and runs on the device, **inside the
  app's own process**, so it can see the app's views and wait for its threads. Espresso, lesson 16,
  works this way. It is quick for a device test and it knows only this one app.
- **An end-to-end test** runs on your computer and drives the device from outside, through the
  accessibility layer, the way a person would: it sees what is on the screen and nothing else.
  Appium, lesson 15, works this way. It can cross apps (the permission dialog belongs to Android,
  not to the app) and it is the slowest of the three.

The test pyramid holds here as everywhere: many local tests, fewer instrumented ones, a handful
end to end. And the first half of this course sits underneath all three, because an app
whose API is wrong is wrong on every screen.

## The two platforms, and the one this course runs

Android and iOS share these ideas and nothing else: different languages, different tools,
different rules about what a test may touch. **This course runs Android and describes iOS from the
outside.** Testing an iOS app needs Xcode, and Xcode runs only on macOS; there is no path to it from
Windows or Linux at any price. Lesson 18 explains what XCUITest and Swift Testing do and how they
compare, so you can read an iOS suite and talk about one, and says plainly that you will not run
one in this course unless you have a Mac.
