---
title: What runs where, inside one app
version: 1
---

**A React Native app is a native app.** What a phone installs is an Android package or an iOS
bundle, built by Gradle or by Xcode like any other, with a native entry point and native views on
the screen. What makes it React Native is one thing that app carries inside it: a JavaScript engine,
and a file of your JavaScript for that engine to run.

The common picture is the wrong way round. Many people arrive believing their JavaScript is
*compiled into* Kotlin or Swift, or that the app is a web page in a hidden browser. Neither is true.
Your code stays JavaScript to the end and runs in an engine called **Hermes**, which ships inside the
app. Nothing draws HTML: a `<Text>` in your component becomes a `TextView` on Android and a
`UILabel` on iOS, the same objects a Kotlin or Swift developer would have created.

## Three places work happens

A phone gives an app one thread that may touch the screen, the **main thread** (Android calls it
the UI thread). Every view is created, changed and drawn there, and every touch arrives there
first. Block it for a third of a second and the app stops answering, which both systems punish:
Android shows an *Application Not Responding* dialog after five seconds of it.

React Native adds a second thread, the **JavaScript thread**, where Hermes runs your code. React
works out what the screen should look like there: it calls your components, compares the result
with the last one, and decides what changed. A long loop in your code blocks this thread and not
the main one, so the app still scrolls, but nothing you wrote can answer a press until the loop
ends.

Between the two sits the work of turning React's answer into views:

| step | what happens | where |
|---|---|---|
| render | your components run and return elements | JavaScript thread |
| layout | Yoga, a C++ library, turns flexbox rules into sizes and positions | wherever the render ran |
| mount | the native views are created or updated to match | main thread |

**Yoga** is why lesson 5 can talk about flexbox in an app with no CSS: it is a layout engine written
in C++ that understands flexbox and nothing else, and both platforms use the same copy.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 215\" role=\"img\" data-fig=\"l01-threads\" aria-label=\"Three places work happens in a React Native app. On the JavaScript thread, Hermes runs your components and React, which renders elements. Yoga, in C++, computes the layout. On the main thread, the native views are mounted and drawn, and touches arrive; a touch travels to the JavaScript thread as an event, and the answer comes back as views.\"><defs><marker id=\"l01-threads-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">JavaScript thread</text><text x=\"360\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">C++, shared</text><text x=\"600\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">main thread</text><rect x=\"40\" y=\"60\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"78.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Hermes runs your</text><text x=\"120.0\" y=\"91.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">components and React</text><text x=\"120\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">1 · render</text><rect x=\"280\" y=\"60\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"78.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Yoga: flexbox</text><text x=\"360.0\" y=\"91.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">to sizes and positions</text><text x=\"360\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">2 · layout</text><rect x=\"520\" y=\"60\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"78.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">native views:</text><text x=\"600.0\" y=\"91.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">TextView, UILabel</text><text x=\"600\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">3 · mount</text><path d=\"M200 85 L280 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-threads-ah-paper-dim)\"></path><path d=\"M440 85 L520 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-threads-ah-paper-dim)\"></path><text x=\"600\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a touch arrives here</text><path d=\"M560 182 L560 196 L120 196 L120 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-threads-ah-paper-dim)\"></path><text x=\"340\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">event</text></svg>", "caption": "Your code runs on the JavaScript thread. Only the main thread may touch a view, so the result is handed to it."}
```

## Why the split matters to you

Most of the performance advice in this course comes from this picture. A slow component makes the
JavaScript thread late, so a press is answered late; a list that creates thousands of views makes
the main thread late, so scrolling stutters. Lesson 12 moves animations off the JavaScript thread
entirely, so that a busy component cannot make them stutter, and lesson 19 measures which thread a
slowdown lives on before fixing anything.

It also explains a rule you meet in every library's documentation: **anything that touches a view
has to happen on the main thread**, so a native module that draws must hand its work there. Lesson
17 writes one.
