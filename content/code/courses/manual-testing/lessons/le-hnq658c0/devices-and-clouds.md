---
title: Real devices, emulators and device clouds
version: 1
---

Responsive mode is often treated as testing on a phone. It is testing a desktop browser at a phone's
width, which catches most layout defects and misses a particular set of others. **Responsive mode
imitates the size, the pixel density, touch input and the name the browser gives itself. It does
not change the engine**, so Chrome set to look like an iPhone still draws the page with Blink, and
it does not bring along anything else the phone has.

## What only a real phone shows

The differences that responsive mode cannot reach are the ones a customer meets in their hand:

- the engine: Safari on an iPhone draws with WebKit, and a layout quirk of WebKit's is invisible
  in Chrome at any width;
- the on-screen keyboard, which slides up when somebody taps the tickets field and covers half the
  page, sometimes including the Book button;
- the fonts the phone has, which make words wider or narrower than on the laptop;
- the phone's settings, such as a larger text size chosen by somebody who reads with difficulty;
- the finger, which is wider than a mouse pointer and lands on the neighbouring link when two are
  close;
- the phone's speed and its network, which a laptop on a good connection hides.

None of these makes responsive mode useless. It is the first check, run on every change to a page,
because it costs a key press. The others are for the cells of the matrix that carry the most
customers.

## Three ways to reach a real engine

**An emulator or simulator** runs a phone's software on the laptop. The Android Emulator, which
comes with Google's Android Studio, runs Android, and its system images that include Google's apps
bring the real Chrome for Android. Apple's
Simulator, which comes with Xcode, runs iOS with Safari's engine, and Xcode runs only on a Mac. The
engine is the real one; the hardware, the keyboard under a thumb and the speed are still the
laptop's.

**Phones of your own** cover the rest. A team that tests for phones often keeps a drawer of a few,
chosen from the top rows of its audience table, and keeps notes of which system version each one
runs. A phone in a drawer goes out of date, sometimes usefully, since customers' phones do too.

**A real-device cloud** rents phones and desktop browsers that sit in somebody else's building.
BrowserStack, Sauce Labs and LambdaTest are three of the companies that offer it: you open their
site, choose a device and a browser, and the device's screen appears in your own browser, where you
tap and type with the mouse and keyboard. They exist so that a team can test on an iPhone without
owning one, or on a model it would use once. They also run automated tests on the same devices,
which the automation courses of this track come back to. None of them was run for this course, and
their plans and prices change, so what one costs is a question for its own site on the day.

## Reaching boxoffice from somewhere else

Every one of these runs into the same fact about your lab. boxoffice listens on `127.0.0.1`, an
address that means *this machine*, so a phone, even one on the same Wi-Fi, cannot open it, and a
phone in a device cloud certainly cannot. An emulator on the laptop can, because it runs on the
same machine; the Android Emulator reaches the laptop at an address of its own, `10.0.2.2`, and its
documentation says so.

Device clouds solve it with a **tunnel**: a small program you run on your machine that opens a
connection out to the service, so that their phone can reach your application through it. That is
convenient and it is a decision, because it gives a machine outside your organisation a path to
something inside it. Where the application holds real customers' data, the rule from lesson 20
applies before any tunnel is opened: test data in test environments, never somebody's real details,
and a device somebody else owns sees whatever you show it.

## Putting it together for boxoffice

For boxoffice 1.0, Ana's choice from section 03 of this lesson becomes concrete:

| cell | how Ana reaches it |
|---|---|
| Chrome on an Android phone | the Android Emulator for the full pass, and one real phone in the device cloud for a short look |
| Safari on an iPhone | a device cloud, through its tunnel, since nobody on the team has an iPhone |
| Chrome, Edge and Firefox on Windows | the same browsers on her Ubuntu laptop, and a Windows machine borrowed for one afternoon of short passes |
| Safari on a Mac | the device cloud again |
| every page at 360 | responsive mode in Chrome and Firefox, on every new build |

Every line in that table has a cost and a gap, and the gaps go in the plan alongside the cells that
were not tested at all. A compatibility claim is only as good as the list of where it was checked,
and **"tested on mobile" means nothing until it names which mobile, with which engine, and how**.
