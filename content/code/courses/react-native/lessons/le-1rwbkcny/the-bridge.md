---
title: The bridge, and what it cost
version: 1
---

**For most of its first decade, React Native's two halves talked by sending each other messages.**
That channel was called the **bridge**, and most articles, answers and courses about React Native
written before 2024 describe an app built around it. You will read them, so it is worth knowing what
they mean and why the bridge is gone.

## Messages, in batches, in JSON

The JavaScript side and the native side never shared a single object. When your code wanted a view
created, it did not call anything native: it added a message to a queue, something like *create view
42 of type `RCTText` with these properties*. The queue was serialised to JSON, handed across, parsed
on the other side, and acted on. Answers came back the same way, later.

Three properties fell out of that design, and each one shaped how React Native apps were written:

- **Everything was asynchronous.** JavaScript could never ask native code a question and wait for the
  answer in the same function. Measuring a view meant sending a request and receiving the size in a
  callback some frames afterwards.
- **Everything was copied.** A large array sent to native code was turned into a string, sent, and
  turned back into an array. A list of a thousand items crossed the bridge as a thousand items'
  worth of text.
- **Every native module started at launch.** The bridge needed a table of every module the app might
  call, so they were all created when the app opened, including the camera module of an app whose
  camera screen nobody would open that day.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l01-bridge\" aria-label=\"The old architecture. The JavaScript side puts messages in a queue, such as create view 42 or set its text. The queue is serialised to JSON and crosses the bridge in a batch. The native side parses it and acts. Answers come back the same way, later, so every call is asynchronous and every value is copied.\"><defs><marker id=\"l01-bridge-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"130\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">JavaScript side</text><text x=\"130\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a queue of messages</text><rect x=\"40\" y=\"76\" width=\"180\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">{\"op\":\"create\",\"tag\":42}</text><rect x=\"40\" y=\"108\" width=\"180\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">{\"op\":\"set\",\"text\":\"Hi\"}</text><rect x=\"40\" y=\"140\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">…</text><rect x=\"270\" y=\"70\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">the bridge</text><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">JSON, in batches</text><path d=\"M220 100 L270 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-bridge-ah-paper-dim)\"></path><path d=\"M450 100 L500 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-bridge-ah-paper-dim)\"></path><text x=\"590\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">native side</text><rect x=\"510\" y=\"76\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"94.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">parse, then</text><text x=\"595.0\" y=\"107.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">create the views</text><path d=\"M590 170 L590 196 L130 196 L130 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-bridge-ah-paper-dim)\"></path><text x=\"360\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">answers come back the same way, frames later</text></svg>", "caption": "Before 2024: nothing was shared, everything was a message, and every answer was a callback."}
```

## Where it hurt

The costs showed up as particular symptoms that every React Native developer of that era learnt to
recognise. A gesture that followed the finger through JavaScript lagged behind it, because every
movement made a round trip through the queue. A screen that measured itself and then laid itself
out flickered between the two states for a frame. Startup time grew with the number of libraries
installed, whether or not they were used. And an animation driven from JavaScript stuttered whenever
the JavaScript thread was busy, because the frames were messages too.

Workarounds grew around each of these. `useNativeDriver: true` sent an animation's whole description
across once, so native code could run it without further messages; lesson 12 still uses it. Libraries
moved their hottest paths into native code. None of that removed the bridge itself, which is what
the next section is about.

## Why it is still worth knowing

Two reasons. **Old code still says it**: a library's README that mentions the bridge, a Stack
Overflow answer about `NativeModules`, a blog post about "bridge traffic" — all describe a design
your app no longer has, and the advice in them may no longer apply. And **the habits outlived it**:
keeping data that crosses between the two sides small, and keeping work that must be smooth off the
JavaScript thread, are still good advice, for reasons the next section changes but does not remove.
