---
title: Motion the reader can turn off
version: 1
---

Lesson 11 section 08 introduced **`prefers-reduced-motion`**. A site with many animations can answer it in one place, with a rule like this, loaded after the others:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

For readers who asked for less motion, every animation and transition becomes **0.01 ms** long and runs **once**. The page is the same page with the movement taken out: anything that slides in is simply there, because, as section 08 recommended, its normal styles are its final state.

```
ana@laptop:~/site$ probe --reduced-motion reduced.html style .spinner animation-duration,animation-iteration-count style .notice opacity
div.spinner  animation-duration: 1e-05s
div.spinner  animation-iteration-count: 1
p.notice  opacity: 1
```

The spinner's duration is **1e-05s**, which is 0.01 ms, and its iteration count **1**: it no longer spins. The notice is fully opaque, **1**, from the first measurement. The rule uses a tiny duration rather than `none` so that anything listening for the end of an animation in JavaScript still gets the event.

## The other way round

The global rule is a safety net. The opposite pattern is better when you write the animations yourself: put **the movement inside** a `no-preference` query, so that a reader who said nothing gets it and the default is still:

```css
@media (prefers-reduced-motion: no-preference) {
  .notice { animation: drop-in 400ms ease-out; }
}
```

**Reduced does not mean none.** A fade or a colour change is not the movement the setting is about; sliding, zooming, spinning and parallax are. A site can replace a slide with a short fade for these readers instead of removing feedback altogether.

## What WCAG asks

Success criterion **2.2.2, Pause, Stop, Hide**, at level A, asks that anything moving that starts by itself and lasts more than five seconds, a carousel or a scrolling ticker, can be paused, stopped or hidden by the reader. A loading indicator is the usual exception, because it stops when loading does. Criterion **2.3.1** forbids content that flashes more than three times a second, which can cause seizures. And 2.3.3, at AAA, is the motion from interactions that lesson 11 described.
