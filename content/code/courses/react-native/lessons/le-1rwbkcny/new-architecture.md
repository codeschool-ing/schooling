---
title: The new architecture: JSI, Fabric and TurboModules
version: 1
---

**The new architecture replaces messages with references.** Instead of describing what it wants in
JSON and waiting, JavaScript holds a handle to a C++ object and calls a method on it, the way it
calls a method on any JavaScript object. React Native 0.76 made it the default in 2024, and 0.82
made it the only architecture there is: a project on the version this course uses, 0.88, cannot
switch it off.

It has four parts, and each one undoes one of the costs of the last section.

## JSI: the JavaScript Interface

**JSI** is a C++ API through which an engine like Hermes exposes JavaScript values to C++, and C++
objects to JavaScript. A native object registered through it appears in JavaScript as an object with
methods; calling one runs the C++ function directly, on the JavaScript thread, and returns its
result. No queue, no JSON, no callback some frames later.

Two consequences matter in practice. A call **may now be synchronous**: a native module can answer
`getString()` with a string, there and then. And data **need not be copied** through text: a large
buffer can be handed across as itself. Neither makes every call free — a synchronous call that
does slow work blocks the JavaScript thread for exactly that long — but the overhead of crossing is
gone.

## Fabric: the renderer

**Fabric** is the part that turns React's elements into native views, rewritten on top of JSI. The
tree of what should be on screen lives in C++, shared by both sides, so the JavaScript side can ask
for a view's size and receive it in the same call. That is what lets a component measure itself and
lay itself out without a frame of flicker in between.

It also lets React Native use React's concurrent features. A render can be interrupted when
something more urgent arrives, a press for instance, and resumed afterwards. Lesson 9 meets
`useTransition`, which depends on this.

## TurboModules: native modules, loaded when used

A native module is code written in Kotlin, Java, Swift, Objective-C or C++ that JavaScript calls:
the camera, the file system, the secure store. **TurboModules** are native modules reached through
JSI, and they are created the first time JavaScript asks for one rather than when the app opens. An
app with forty libraries installed pays at launch for the ones the first screen uses.

## Codegen: the contract, checked

JSI is C++, and a native module is written in Kotlin or Swift, so something has to write the glue in
between. **Codegen** does: you describe the module once, as a typed TypeScript interface, and at build
time it generates the C++ and the native interfaces from that description. A Kotlin function whose
parameter types do not match the TypeScript spec no longer compiles, which turns a class of crashes
that used to appear on a device into errors in the build. Lesson 17 writes a spec and watches Codegen
run.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l01-jsi\" aria-label=\"The new architecture. JavaScript holds references to C++ objects through JSI and calls them directly, in the same call. Fabric keeps the tree of views in C++ and mounts native views on the main thread. TurboModules are native modules created the first time they are called. Codegen writes the C++ glue at build time from a typed TypeScript spec.\"><defs><marker id=\"l01-jsi-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">JavaScript, in Hermes</text><rect x=\"40\" y=\"60\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">module.getString()</text><text x=\"120\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">a direct call, same thread</text><rect x=\"250\" y=\"55\" width=\"50\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"275\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">JSI</text><path d=\"M200 77 L250 77\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-jsi-ah-paper-dim)\" marker-start=\"url(#l01-jsi-ah-paper-dim)\"></path><rect x=\"330\" y=\"30\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"415.0\" y=\"46.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">TurboModule:</text><text x=\"415.0\" y=\"59.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">created on first use</text><rect x=\"330\" y=\"96\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"415.0\" y=\"112.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Fabric: the tree</text><text x=\"415.0\" y=\"125.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">of views, in C++</text><path d=\"M300 70 L330 53\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-jsi-ah-paper-dim)\"></path><path d=\"M300 85 L330 119\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-jsi-ah-paper-dim)\"></path><rect x=\"530\" y=\"30\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Kotlin or Swift</text><rect x=\"530\" y=\"96\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"112.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">native views,</text><text x=\"615.0\" y=\"125.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">on the main thread</text><path d=\"M500 53 L530 53\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-jsi-ah-paper-dim)\"></path><path d=\"M500 119 L530 119\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-jsi-ah-paper-dim)\"></path><rect x=\"250\" y=\"186\" width=\"250\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"375.0\" y=\"202.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Codegen: C++ glue</text><text x=\"375.0\" y=\"215.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">from a TypeScript spec</text><text x=\"375\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">written at build time</text><path d=\"M375 186 L375 145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-jsi-ah-paper-dim)\"></path></svg>", "caption": "Since 0.76 by default, and since 0.82 always: references instead of messages."}
```

## What did not change

**Your components are written the same way.** `View`, `Text`, `useState` and the rest look exactly
as they did; the architecture changed underneath them. What changed for application code is mostly
what *stopped* happening: a list that measures itself does not flicker, a library does not slow the
launch merely by being installed, and the advice "keep traffic over the bridge small" no longer
names anything. **The JavaScript thread is still one thread**, and keeping it free is still the
whole of lessons 12 and 19.
