---
title: How React Native draws a screen
version: 1
---

**React Native runs your JavaScript, and asks the platform to draw real native controls for what it
describes.** There is no browser engine, no HTML and no CSS in the app. A `<Text>` in your code becomes
a `TextView` on Android and a `UILabel` on iOS; a `<Pressable>` becomes a native view that takes touches.
The screen the person sees is the one any Kotlin or Swift app would show.

The common picture is that React Native "compiles JavaScript to native code". It does not. **Your
JavaScript still runs, inside the app, in a JavaScript engine**, and what crosses to the native side is
a description of the screen, not your program.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l07-layers\" aria-label=\"The layers of a React Native app on a phone. Your components and planner.ts are JavaScript, run by the Hermes engine. React works out what the screen should be. The renderer, Fabric, with the Yoga layout engine, creates and lays out native views. Those are the platform's own controls: a TextView or a UILabel for Text, a native view for Pressable. JSI joins the JavaScript to the native side. There is no WebView anywhere.\"><defs><marker id=\"l07-layers-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"170\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"34\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">JavaScript, in Hermes</text><rect x=\"40\" y=\"52\" width=\"260\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"68.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">your components,</text><text x=\"170.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">and src/planner.ts</text><rect x=\"40\" y=\"120\" width=\"260\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"136.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">React: what the</text><text x=\"170.0\" y=\"149.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">screen should be</text><path d=\"M170 98 L170 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-layers-ah-paper-dim)\"></path><rect x=\"360\" y=\"82\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"430.0\" y=\"100.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Fabric and Yoga:</text><text x=\"430.0\" y=\"113.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">views and layout</text><path d=\"M300 143 L360 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-layers-ah-paper-dim)\"></path><text x=\"330\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">JSI</text><text x=\"610\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the platform's own views</text><rect x=\"530\" y=\"52\" width=\"160\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"68.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;Text&gt; → TextView,</text><text x=\"610.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UILabel</text><rect x=\"530\" y=\"120\" width=\"160\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"136.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;Pressable&gt; → a</text><text x=\"610.0\" y=\"149.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">native touch view</text><path d=\"M500 100 L530 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-layers-ah-paper-dim)\"></path><path d=\"M500 115 L530 143\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-layers-ah-paper-dim)\"></path><text x=\"360\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">no WebView, no HTML, no CSS</text></svg>", "caption": "Your code still runs as JavaScript. What reaches the screen is a description, turned into the views a Kotlin or Swift app would have."}
```

## The parts

- **Hermes** is the JavaScript engine React Native ships with, made for phones: it compiles your
  JavaScript to bytecode when the app is built, so the phone does not parse it at every start.
- **React** decides what the screen should be, from your components and their state, and works out what
  changed since the last time. That half is the same React that runs in a browser.
- **The renderer**, called Fabric in the current architecture, takes React's answer and creates,
  updates and lays out the native views. **Yoga**, a layout engine written in C++, works out where each
  view goes, from flexbox rules, the same on both platforms.
- **JSI**, the JavaScript Interface, is how JavaScript calls native code directly, without turning every
  call into a message. It replaced the asynchronous "bridge" of the early versions of React Native,
  which is the word you will still find in older articles.

## What that means for the planner

**The rules in `src/planner.ts` run as they are**: they are JavaScript with no DOM, and Hermes runs
JavaScript. **The views in `src/view.ts` cannot come along**: there is no `document`, no
`createElement`, no `<button>`. The screens are written again with React Native's components, which is
the price the native path asks, and lesson 6 said it is the part worth paying for only when the app
needs what native views give.
