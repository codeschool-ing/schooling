---
title: Two ways to a store
version: 1
---

**There are two ways to put a web developer's work on a phone or a desktop, and they differ in who
draws the screen.** In the first, your web app runs as it is, inside a browser engine that a native
app carries. In the second, you write the app again, and the operating system's own controls draw
every button and list. The rest of this course is those two ways, side by side, and how to tell which
one a given app needs.

The common picture is a third one: that a web app can be "converted" into a native app, and comes
out the other end as Swift or Kotlin. **Nothing converts it.** Every tool in this course either runs
your HTML, CSS and JavaScript in a browser engine, or asks you to describe the screen again in its own
terms. Knowing which of the two a tool does tells you most of what it can and cannot do.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l01-two-ways\" aria-label=\"Two ways from a web app to a store. Top row, the wrapper: the built site, dist, is copied into a native app whose whole screen is a WebView, and the browser engine draws the screen; Capacitor does this for Android and iOS, Electron and Tauri for the desktop. Bottom row, the native path: the screens are written again as components, React Native turns them into the platform's own views, and the platform draws the screen. The planner's rules, src/planner.ts, have no DOM in them and go into both.\"><defs><marker id=\"l01-two-ways-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">the wrapper</text><text x=\"20\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">the native path</text><rect x=\"20\" y=\"36\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"54.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the built site</text><text x=\"120.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dist/</text><rect x=\"260\" y=\"36\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"54.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a native app whose</text><text x=\"360.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">screen is a WebView</text><rect x=\"500\" y=\"36\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"54.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a browser engine</text><text x=\"600.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">draws the screen</text><rect x=\"20\" y=\"166\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the screens, written</text><text x=\"120.0\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">again as components</text><rect x=\"260\" y=\"166\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">React Native turns</text><text x=\"360.0\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">them into native views</text><rect x=\"500\" y=\"166\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the platform's own</text><text x=\"600.0\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">controls draw it</text><path d=\"M220 61 L260 61\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-two-ways-ah-paper-dim)\"></path><path d=\"M460 61 L500 61\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-two-ways-ah-paper-dim)\"></path><path d=\"M220 191 L260 191\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-two-ways-ah-paper-dim)\"></path><path d=\"M460 191 L500 191\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-two-ways-ah-paper-dim)\"></path><text x=\"360\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">Capacitor · Electron · Tauri</text><text x=\"360\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">React Native · Flutter · Swift and Kotlin</text><rect x=\"20\" y=\"112\" width=\"200\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"120.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the rules, src/planner.ts:</text><text x=\"120.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no DOM, so they go into both</text><path d=\"M120 112 L120 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-two-ways-ah-paper-dim)\"></path><path d=\"M120 146 L120 164\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-two-ways-ah-paper-dim)\"></path></svg>", "caption": "Nothing converts a web app into a native one. Either a browser engine still draws it, or the screens are written again for the platform to draw."}
```

## The wrapper: your app, inside a native shell

A **WebView** is a browser engine without the browser around it: no address bar, no tabs, just the
part that turns HTML into pixels, embedded in an ordinary app. Android has one, built on Chromium.
iOS has one, built on WebKit, the engine of Safari. A wrapped app is a small native program whose
whole screen is a WebView, loading your built site from files inside the app.

- **Capacitor** (lessons 2 to 6) wraps a web app for Android and iOS. Your `dist/` folder is copied
  into a real Android project and a real Xcode project, and a **bridge** lets your JavaScript call
  native code: the camera, the files, notifications.
- **Electron** (lesson 11) wraps a web app for Windows, macOS and Linux, and carries its own copy of
  Chromium and of Node.js inside every app.
- **Tauri** (lesson 12) does the same with the WebView the operating system already has, and a core
  written in Rust instead of Node.

**What you keep is everything you already wrote.** The planner of the next section becomes an Android
app in lesson 2 without one line of it changing. What you give up is anything the WebView cannot
do, and lesson 6 is about finding that out before an app store finds it out for you.

## The native path: the screen drawn by the platform

A native app's screen is made of the platform's own controls. Written in Swift for iOS and Kotlin
for Android, that means two apps, two languages and two teams. **React Native** (lessons 7 to 9) is
the middle road this course takes: you write components in JavaScript and TypeScript, with React,
and React Native turns them into real native views on each platform. There is no DOM and no HTML.
A `<View>` becomes an Android `View` and an iOS `UIView`.

What it buys is the platform's own scrolling, gestures, text input and accessibility, with no browser
engine in between. What it costs is a rewrite of the screens. The logic can move across:
`src/planner.ts` has no DOM in it, and lesson 7 imports it as it is. **The views cannot**, because
there is no `document` to draw on. Lesson 10 looks at the other tools on this path, Flutter and
NativeScript, and at Ionic, which sits on the wrapper side.

## What the course does with them

| lessons | what | where it runs |
|---|---|---|
| 1 | the planner, and your computer set up | the browser |
| 2 to 6 | Capacitor: the planner as an Android and iOS app | a phone or an emulator |
| 7 to 10 | React Native and Expo, and a look at the others | a phone, an emulator or the browser |
| 11 and 12 | Electron and Tauri: the planner as a desktop app | a window on your computer |
| 13 to 15 | packages, signatures, stores and updates | everywhere |
| 16 | your own app, released | wherever you choose |
