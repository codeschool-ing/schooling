---
title: What Capacitor is, and the bridge in the middle
version: 1
---

**Capacitor takes a built web app and puts it inside a real Android project and a real Xcode
project**, whose only job is to open a WebView full screen and load your files into it. The projects
are ordinary ones: Android Studio and Xcode open them, build them and sign them as they would any
app. Capacitor adds two things to each, a way to serve your files and a way for your JavaScript to
call native code.

It is easy to picture Capacitor as a server, or as a converter. It is neither. **Nothing runs on a
computer of yours once the app is built**: the files travel inside the app, and the WebView reads
them from the phone's own storage.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l02-bridge\" aria-label=\"Inside a Capacitor app on a phone. The WebView shows your built site, served by Capacitor from the app's own files at https://localhost on Android and capacitor://localhost on iOS. When your code calls a plugin, the call crosses the bridge as a message to a native class, in Java or Kotlin on Android and Swift on iOS, which talks to the camera, the files or the notifications, and the answer comes back as the result of a Promise.\"><defs><marker id=\"l02-bridge-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-bridge-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"214\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"36\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the app, on the phone</text><rect x=\"40\" y=\"52\" width=\"250\" height=\"162\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">the WebView</text><rect x=\"60\" y=\"86\" width=\"210\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"165.0\" y=\"102.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">your built site, dist/,</text><text x=\"165.0\" y=\"115.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">served at https://localhost</text><rect x=\"60\" y=\"150\" width=\"210\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"165.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Preferences.set(…)</text><text x=\"345\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">the bridge</text><path d=\"M270 160 L420 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-bridge-ah-amber)\"></path><path d=\"M420 186 L270 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l02-bridge-ah-paper-dim)\"></path><text x=\"345\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the answer: a Promise resolves</text><rect x=\"420\" y=\"146\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">a native class:</text><text x=\"480.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Java or Kotlin, or Swift</text><path d=\"M540 171 L565 171\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-bridge-ah-paper-dim)\"></path><rect x=\"565\" y=\"146\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the phone's files,</text><text x=\"625.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">camera, notifications</text></svg>", "caption": "Your files travel inside the app and are served from it. The bridge is the one way out of the WebView, and each plugin is a class on the other side of it."}
```

## Your files, served from inside the app

The WebView does not open your files as `file://` paths. Capacitor answers its requests itself,
under an address that looks like a web server: `https://localhost` on Android and
`capacitor://localhost` on iOS. To your code, the app is a site served from its own origin, so
`fetch("courses.json")` works, cookies and `localStorage` work, and the planner runs without one
line changed. The cost is that **this origin belongs to the phone**: nothing on the internet is
`localhost` from there, and a call to your own API needs its real address.

## The bridge

A web page cannot reach the camera's native interface, the device's files or its notification
system. Capacitor's **bridge** is the path from your JavaScript to native code that can. Calling a
plugin from TypeScript looks like calling any asynchronous function:

```typescript
import { Preferences } from "@capacitor/preferences";
await Preferences.set({ key: "plan", value: JSON.stringify(plan) });
```

Underneath, the call is turned into a message, handed to the native side, answered by a class
written in Java or Kotlin on Android and in Swift on iOS, and the answer comes back as the result of
the `Promise`. Lesson 4 uses five of these plugins on the planner, and lesson 5 writes one.

**The same call has a third implementation, for the web.** Most official plugins ship one, so the
planner keeps working in an ordinary browser: `Preferences` writes to `localStorage` there. That is
what lets this course run most of a plugin's behaviour in Chromium, and also what hides a difference
until the app runs on a phone, which lesson 6 is about.

## What Capacitor is not

- **It is not Cordova**, though it can load most Cordova plugins. Cordova regenerated its native
  projects on every build, so a change made in Xcode was lost; Capacitor generates them once and
  then treats them as your source code, in git, which is lesson 3's subject.
- **It is not a framework.** It does not care whether `dist/` came from React, Angular, Vue, Svelte
  or five files of TypeScript. It needs a folder with an `index.html` in it.
- **It is not Ionic**, though the same company makes both. Ionic is a set of mobile-looking
  components for the web; lesson 10 looks at it.
