---
title: Less motion, when it is asked for
version: 1
---

**Both platforms have a setting that asks apps for less motion**: *Reduce Motion* on iOS, *Remove
animations* on Android. People turn it on because movement on screen makes them dizzy or nauseous, or
because it distracts them. An app that ignores it is one some people cannot use for long.

`AccessibilityInfo.isReduceMotionEnabled()` answers the question. The planner's bar asks it before every
animation and, when the answer is yes, uses a duration of 0: the bar changes at once, without moving.
**The information is kept; only the movement goes.** The bar still shows 76 percent, a screen reader still
says 95 of 125.

`frames.mjs` takes `--reduced`, which asks the browser for reduced motion the way the phone's setting
would. The second run marks spanish's session of the 22nd done, so the bar goes from 95 to all 125:

```
ana@dev:~/planner$ node frames.mjs 'http://localhost:8082/?today=2026-10-21' 'Mark 30 min on 2026-10-22 done' --reduced
width every 50 ms: 936 1232 1232 1232 1232 1232 1232 1232 1232 1232 1232
```

**One sample at the old width, then the new one.** No climb in between: the first sample was taken before
the change arrived, and the next one found it complete.

## What to reduce, and what to keep

Reducing motion does not mean removing every change. A fade is usually fine, a large slide or a bounce
is not, and anything that moves on its own, an animated background, a carousel turning by itself,
should stop. Navigation transitions belong to React Navigation, which follows the setting on each
platform. For your own animations, the question to ask is whether the movement carries information; if
it does, give the information another way.
